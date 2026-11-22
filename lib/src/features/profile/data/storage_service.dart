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

/// Firebase Storage へのファイルアップロード・削除を管理するサービスクラス
class StorageService {
  /// コンストラクタ
  const StorageService({
    required this.storage,
    required this.talker,
    required this.uuid,
    required this.getCurrentDateTime,
  });

  /// FirebaseStorage インスタンス
  final FirebaseStorage storage;

  /// ロガー
  final Talker talker;

  /// UUID生成器
  final Uuid uuid;

  /// 現在日時を取得する関数
  final DateTime Function() getCurrentDateTime;

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
    r'^/[A-Za-z0-9.\-_]+/',
    caseSensitive: false,
  );

  /// 指定されたURLが `firebase_storage` SDK の `refFromURL` で処理可能な削除対象URLか判定する
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
    if (host == 'storage.googleapis.com' ||
        host == 'storage.cloud.google.com') {
      return _cloudStoragePathRegExp.hasMatch(uri.path);
    }

    return false;
  }

  /// アバター画像を URL を指定して Firebase Storage から削除する
  ///
  /// Firebase Storage 以外のURL（外部プロバイダ画像やローカルパス等）や空文字が渡された場合は
  /// 例外を発生させず安全にスキップします。
  Future<void> deleteAvatarByUrl({required String avatarUrl}) async {
    if (!isFirebaseStorageUrl(avatarUrl)) {
      talker.debug(
        'Skipped avatar deletion because URL is not Firebase Storage: '
        '$avatarUrl',
      );
      return;
    }

    try {
      talker.debug('Deleting avatar image by URL: $avatarUrl');
      final ref = storage.refFromURL(avatarUrl);
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
