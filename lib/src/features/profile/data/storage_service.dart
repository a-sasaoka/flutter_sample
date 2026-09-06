import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_sample/src/core/exceptions/app_exception.dart';
import 'package:flutter_sample/src/core/utils/logger_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:talker_flutter/talker_flutter.dart';

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
  );
}

/// Firebase Storage へのファイルアップロード・削除を管理するサービスクラス
class StorageService {
  /// コンストラクタ
  const StorageService({
    required this.storage,
    required this.talker,
  });

  /// FirebaseStorage インスタンス
  final FirebaseStorage storage;

  /// ロガー
  final Talker talker;

  /// アバター画像を Firebase Storage にアップロードし、ダウンロードURLを返す
  Future<String> uploadAvatar({
    required String userId,
    required File file,
  }) async {
    try {
      talker.debug('Uploading avatar image for user: $userId');
      final timestamp = DateTime.now().toUtc().millisecondsSinceEpoch;
      final fileName = '${userId}_$timestamp.jpg';
      final ref = storage.ref().child('avatars').child(fileName);
      final metadata = SettableMetadata(
        contentType: 'image/jpeg',
      );
      final uploadTask = ref.putFile(file, metadata);
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();
      talker.debug('Avatar uploaded successfully. URL: $downloadUrl');
      return downloadUrl;
    } on FirebaseException catch (e, st) {
      talker.handle(e, st, 'Firebase Storage upload error');
      throw const AppException.server(
        message: 'Failed to upload avatar image',
      );
    } on Object catch (e, st) {
      talker.handle(e, st, 'Unexpected error during avatar upload');
      throw AppException.unknown(
        message: 'Unexpected error during avatar upload',
        error: e,
      );
    }
  }

  /// アバター画像を URL を指定して Firebase Storage から削除する
  Future<void> deleteAvatarByUrl({
    required String avatarUrl,
  }) async {
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
      throw const AppException.server(
        message: 'Failed to delete avatar image',
      );
    } on Object catch (e, st) {
      talker.handle(e, st, 'Unexpected error during avatar deletion');
      throw AppException.unknown(
        message: 'Unexpected error during avatar deletion',
        error: e,
      );
    }
  }
}
