import 'dart:convert';
import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_sample/src/core/exceptions/app_exception.dart';
import 'package:flutter_sample/src/core/utils/date_time_provider.dart';
import 'package:flutter_sample/src/core/utils/logger_provider.dart';
import 'package:flutter_sample/src/core/utils/uuid_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:talker_flutter/talker_flutter.dart';
import 'package:uuid/uuid.dart';

part 'storage_service.g.dart';

// coverage:ignore-start
/// FirebaseStorage を提供するプロバイダー
@riverpod
FirebaseStorage firebaseStorage(Ref ref) => FirebaseStorage.instance;
// coverage:ignore-end

/// StorageService を提供するプロバイダー
@riverpod
StorageService storageService(Ref ref) {
  return StorageService(
    storage: ref.watch(firebaseStorageProvider),
    talker: ref.watch(loggerProvider),
    uuid: ref.watch(uuidProvider),
    getCurrentDateTime: ref.watch(clockProvider),
  );
}

/// 対象バケット用の FirebaseStorage インスタンスを取得する関数型
typedef StorageForBucket =
    FirebaseStorage Function(FirebaseStorage currentStorage, String bucket);

/// Firebase Storage へのファイルアップロード・削除を管理するサービスクラス
class StorageService {
  /// コンストラクタ
  const StorageService({
    required this.storage,
    required this.talker,
    required this.uuid,
    required this.getCurrentDateTime,
    StorageForBucket? storageForBucket,
  }) : _storageForBucket = storageForBucket;

  /// FirebaseStorage インスタンス
  final FirebaseStorage storage;

  /// ロガー
  final Talker talker;

  /// UUID生成器
  final Uuid uuid;

  /// 現在日時を取得する関数
  final DateTime Function() getCurrentDateTime;

  final StorageForBucket? _storageForBucket;

  // coverage:ignore-start
  static FirebaseStorage _defaultStorageForBucket(
    FirebaseStorage currentStorage,
    String bucket,
  ) => FirebaseStorage.instanceFor(app: currentStorage.app, bucket: bucket);
  // coverage:ignore-end

  /// アバター画像を Firebase Storage にアップロードし、ダウンロードURLを返す
  Future<String> uploadAvatar({
    required String userId,
    required File file,
  }) async {
    try {
      talker.debug('Uploading avatar image for user: $userId');
      final timestamp = getCurrentDateTime().toUtc().millisecondsSinceEpoch;
      final randomId = uuid.v4();
      final fileName = '${userId}_${timestamp}_$randomId.jpg';
      final ref = storage.ref().child('avatars').child(fileName);
      final metadata = SettableMetadata(contentType: 'image/jpeg');
      final uploadTask = ref.putFile(file, metadata);
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();
      talker.debug('Avatar uploaded successfully. URL: $downloadUrl');
      return downloadUrl;
    } on FirebaseException catch (e, st) {
      talker.handle(e, st, 'Firebase Storage upload error');
      throw const AppException.server(message: 'Failed to upload avatar image');
    } on Object catch (e, st) {
      talker.handle(e, st, 'Unexpected error during avatar upload');
      throw AppException.unknown(
        message: 'Unexpected error during avatar upload',
        error: e,
      );
    }
  }

  static final RegExp _firebaseStoragePathRegExp = RegExp(
    r'^/v[A-Za-z0-9_]+/b/[A-Za-z0-9.\-_]+/o(?:/|$)',
    caseSensitive: false,
  );
  static final RegExp _cloudStoragePathRegExp = RegExp(
    r'^/([A-Za-z0-9.\-_]+)/(.+)$',
    caseSensitive: false,
  );

  static final RegExp _invalidPercentRegExp = RegExp('%(?![0-9a-fA-F]{2})');
  static final RegExp _percentSequenceRegExp = RegExp('(?:%[0-9a-fA-F]{2})+');

  static String? _tryDecodeFullPath(String path) {
    try {
      return path.replaceAllMapped(_percentSequenceRegExp, (match) {
        final token = match.group(0)!;
        final bytes = <int>[
          for (var i = 0; i < token.length; i += 3)
            int.parse(token.substring(i + 1, i + 3), radix: 16),
        ];
        return utf8.decode(bytes);
      });
    } on FormatException {
      return null;
    }
  }

  static ({String bucket, String objectPath})? _parseCloudStorageLocation(
    String rawUrl,
    Uri uri,
  ) {
    final host = uri.host.toLowerCase();
    if (host != 'storage.googleapis.com' &&
        host != 'storage.cloud.google.com') {
      return null;
    }

    if (_invalidPercentRegExp.hasMatch(rawUrl)) {
      return null;
    }

    final decodedPath = _tryDecodeFullPath(uri.path);
    if (decodedPath == null) {
      return null;
    }

    final match = _cloudStoragePathRegExp.firstMatch(decodedPath);
    if (match == null) {
      return null;
    }

    final bucket = match.group(1)!;
    final objectPath = match.group(2)!;
    if (objectPath.replaceAll('/', '').trim().isEmpty) {
      return null;
    }

    return (bucket: bucket, objectPath: objectPath);
  }

  /// 指定されたURLが `firebase_storage` SDK の `refFromURL` 等で処理可能な削除対象URLか判定する
  ///
  /// Googleログイン由来の外部プロフィール画像URLやローカルファイルパス、SDK非対応形式、空文字が
  /// 渡された場合に `refFromURL` で例外が発生するのを防ぐために使用します。
  static bool isFirebaseStorageUrl(String url) {
    final trimmed = url.trim();
    if (trimmed.isEmpty) {
      return false;
    }

    final uri = Uri.tryParse(trimmed);
    if (uri == null || uri.host.isEmpty) {
      return false;
    }

    // gs://<bucket>/<object> 形式
    if (uri.scheme == 'gs') {
      return true;
    }

    if (uri.scheme != 'http' && uri.scheme != 'https') {
      return false;
    }

    final host = uri.host.toLowerCase();

    // 本番 Firebase Storage REST URL (/v0/b/<bucket>/o/...) または
    // Firebase Storage Emulator (localhost / 10.0.2.2) の同パス形式
    if (host == 'firebasestorage.googleapis.com' ||
        host == 'localhost' ||
        host == '10.0.2.2') {
      return _firebaseStoragePathRegExp.hasMatch(uri.path);
    }

    // Google Cloud Storage URL (storage.googleapis.com / storage.cloud.google.com)
    return _parseCloudStorageLocation(trimmed, uri) != null;
  }

  Reference _resolveReference(String url) {
    final uri = Uri.tryParse(url);
    if (uri != null) {
      if (_parseCloudStorageLocation(url, uri) case (
        :final bucket,
        :final objectPath,
      )) {
        // Cloud Storage URL は URL 全体の localhost 判定で refFromURL が失敗する場合があるため、
        // 解析済みのバケット名とオブジェクトパスから参照を直接構築する
        final currentBucket = storage.bucket.replaceFirst('gs://', '');
        if (currentBucket == bucket) {
          return storage.ref(objectPath);
        }
        final resolveStorage = _storageForBucket ?? _defaultStorageForBucket;
        return resolveStorage(storage, 'gs://$bucket').ref(objectPath);
      }
    }
    return storage.refFromURL(url);
  }

  /// アバター画像を URL を指定して Firebase Storage から削除する
  ///
  /// Firebase Storage 以外のURL（外部プロバイダ画像やローカルパス等）や空文字が渡された場合は
  /// 例外を発生させず安全にスキップします。
  Future<void> deleteAvatarByUrl({required String avatarUrl}) async {
    final trimmedUrl = avatarUrl.trim();
    if (!isFirebaseStorageUrl(trimmedUrl)) {
      talker.debug(
        'Skipped avatar deletion because URL is not Firebase Storage.',
      );
      return;
    }

    try {
      talker.debug('Deleting avatar image by URL: $trimmedUrl');
      final ref = _resolveReference(trimmedUrl);
      await ref.delete();
      talker.debug('Avatar deleted successfully by URL.');
    } on FirebaseException catch (e, st) {
      // ファイルが存在しない場合 (object-not-found) は正常とみなす
      if (e.code == 'object-not-found') {
        talker.debug(
          'Avatar file did not exist on Storage. Nothing to delete.',
        );
        return;
      }
      talker.handle(e, st, 'Firebase Storage delete error');
      throw const AppException.server(message: 'Failed to delete avatar image');
    } on Object catch (e, st) {
      talker.handle(e, st, 'Unexpected error during avatar deletion');
      throw AppException.unknown(
        message: 'Unexpected error during avatar deletion',
        error: e,
      );
    }
  }
}
