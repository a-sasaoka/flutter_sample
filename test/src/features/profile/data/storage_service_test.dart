import 'dart:async';
import 'dart:io';

import 'package:checks/checks.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_sample/src/core/exceptions/app_exception.dart';
import 'package:flutter_sample/src/core/utils/logger_provider.dart';
import 'package:flutter_sample/src/features/profile/data/storage_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:talker_flutter/talker_flutter.dart';

class MockFirebaseStorage extends Mock implements FirebaseStorage {}

class MockReference extends Mock implements Reference {}

class FakeUploadTask extends Fake implements UploadTask {
  FakeUploadTask(this._snapshot);
  final TaskSnapshot _snapshot;

  @override
  Future<S> then<S>(
    FutureOr<S> Function(TaskSnapshot) onValue, {
    Function? onError,
  }) {
    return Future.value(_snapshot).then(onValue, onError: onError);
  }
}

class MockTaskSnapshot extends Mock implements TaskSnapshot {}

class MockTalker extends Mock implements Talker {}

class MockFile extends Mock implements File {}

void main() {
  late MockFirebaseStorage mockStorage;
  late MockReference mockRootRef;
  late MockReference mockAvatarsRef;
  late MockReference mockFileRef;
  late MockTaskSnapshot mockTaskSnapshot;
  late MockTalker mockTalker;
  late MockFile mockFile;
  late StorageService service;

  setUpAll(() {
    registerFallbackValue(SettableMetadata());
    registerFallbackValue(StackTrace.current);
  });

  setUp(() {
    mockStorage = MockFirebaseStorage();
    mockRootRef = MockReference();
    mockAvatarsRef = MockReference();
    mockFileRef = MockReference();
    mockTaskSnapshot = MockTaskSnapshot();
    mockTalker = MockTalker();
    mockFile = MockFile();

    when(() => mockTalker.debug(any<dynamic>())).thenReturn(null);
    when(
      () => mockTalker.handle(
        any<Object>(),
        any<StackTrace?>(),
        any<dynamic>(),
      ),
    ).thenReturn(null);

    when(() => mockStorage.ref()).thenReturn(mockRootRef);
    when(() => mockStorage.refFromURL(any())).thenReturn(mockFileRef);
    when(() => mockRootRef.child('avatars')).thenReturn(mockAvatarsRef);
    when(() => mockAvatarsRef.child(any())).thenReturn(mockFileRef);

    service = StorageService(
      storage: mockStorage,
      talker: mockTalker,
    );
  });

  group('StorageService uploadAvatar Tests', () {
    const userId = 'user_123';
    const downloadUrl = 'https://firebasestorage.googleapis.com/avatar.jpg';

    test('uploadAvatar: 正常系 - アップロードが成功してダウンロードURLが返ること', () async {
      when(
        () => mockFileRef.putFile(mockFile, any()),
      ).thenAnswer((_) => FakeUploadTask(mockTaskSnapshot));
      when(() => mockTaskSnapshot.ref).thenReturn(mockFileRef);
      when(
        () => mockFileRef.getDownloadURL(),
      ).thenAnswer((_) async => downloadUrl);

      final result = await service.uploadAvatar(
        userId: userId,
        file: mockFile,
      );

      check(result).equals(downloadUrl);
      verify(
        () => mockAvatarsRef.child(any(that: startsWith('${userId}_'))),
      ).called(1);
      verify(() => mockFileRef.putFile(mockFile, any())).called(1);
    });

    test(
      'uploadAvatar: 異常系 - FirebaseException 発生時は AppException.server を投げること',
      () async {
        final firebaseException = FirebaseException(
          plugin: 'firebase_storage',
          code: 'unauthorized',
          message: 'Permission denied',
        );

        when(
          () => mockFileRef.putFile(mockFile, any()),
        ).thenThrow(firebaseException);

        await check(
          service.uploadAvatar(userId: userId, file: mockFile),
        ).throws<AppException>();

        verify(
          () => mockTalker.handle(
            firebaseException,
            any<StackTrace?>(),
            'Firebase Storage upload error',
          ),
        ).called(1);
      },
    );

    test(
      'uploadAvatar: 異常系 - 予期せぬ例外発生時は AppException.unknown を投げること',
      () async {
        final genericException = Exception('Unexpected error');

        when(
          () => mockFileRef.putFile(mockFile, any()),
        ).thenThrow(genericException);

        await check(
          service.uploadAvatar(userId: userId, file: mockFile),
        ).throws<AppException>();

        verify(
          () => mockTalker.handle(
            genericException,
            any<StackTrace?>(),
            'Unexpected error during avatar upload',
          ),
        ).called(1);
      },
    );
  });

  group('StorageService deleteAvatar Tests', () {
    const userId = 'user_123';

    test('deleteAvatar: 正常系 - ファイル削除が成功すること', () async {
      when(() => mockFileRef.delete()).thenAnswer((_) async {});

      await check(service.deleteAvatar(userId: userId)).completes();

      verify(() => mockAvatarsRef.child('$userId.jpg')).called(1);
      verify(() => mockFileRef.delete()).called(1);
    });

    test(
      'deleteAvatar: 正常系 - ファイルが存在しない(object-not-found)場合は例外を投げず正常終了すること',
      () async {
        final notFoundException = FirebaseException(
          plugin: 'firebase_storage',
          code: 'object-not-found',
        );

        when(() => mockFileRef.delete()).thenThrow(notFoundException);

        await check(service.deleteAvatar(userId: userId)).completes();

        verify(
          () => mockTalker.debug(
            'Avatar file did not exist on Storage. Nothing to delete.',
          ),
        ).called(1);
      },
    );

    test(
      'deleteAvatar: 異常系 - '
      'object-not-found以外のFirebaseExceptionはAppException.serverを投げること',
      () async {
        final firebaseException = FirebaseException(
          plugin: 'firebase_storage',
          code: 'unauthorized',
        );

        when(() => mockFileRef.delete()).thenThrow(firebaseException);

        await check(
          service.deleteAvatar(userId: userId),
        ).throws<AppException>();

        verify(
          () => mockTalker.handle(
            firebaseException,
            any<StackTrace?>(),
            'Firebase Storage delete error',
          ),
        ).called(1);
      },
    );

    test(
      'deleteAvatar: 異常系 - 予期せぬ例外発生時は AppException.unknown を投げること',
      () async {
        final genericException = Exception('Network down');

        when(() => mockFileRef.delete()).thenThrow(genericException);

        await check(
          service.deleteAvatar(userId: userId),
        ).throws<AppException>();

        verify(
          () => mockTalker.handle(
            genericException,
            any<StackTrace?>(),
            'Unexpected error during avatar deletion',
          ),
        ).called(1);
      },
    );
  });

  group('StorageService deleteAvatarByUrl Tests', () {
    const avatarUrl = 'https://firebasestorage.googleapis.com/avatar_123.jpg';

    test('deleteAvatarByUrl: 正常系 - URL指定でファイル削除が成功すること', () async {
      when(() => mockFileRef.delete()).thenAnswer((_) async {});

      await check(
        service.deleteAvatarByUrl(avatarUrl: avatarUrl),
      ).completes();

      verify(() => mockStorage.refFromURL(avatarUrl)).called(1);
      verify(() => mockFileRef.delete()).called(1);
    });

    test(
      'deleteAvatarByUrl: 正常系 - ファイルが存在しない(object-not-found)場合は例外を投げず正常終了すること',
      () async {
        final notFoundException = FirebaseException(
          plugin: 'firebase_storage',
          code: 'object-not-found',
        );

        when(() => mockFileRef.delete()).thenThrow(notFoundException);

        await check(
          service.deleteAvatarByUrl(avatarUrl: avatarUrl),
        ).completes();

        verify(
          () => mockTalker.debug(
            'Avatar file did not exist on Storage. Nothing to delete.',
          ),
        ).called(1);
      },
    );

    test(
      'deleteAvatarByUrl: 異常系 - '
      'object-not-found以外のFirebaseExceptionはAppException.serverを投げること',
      () async {
        final firebaseException = FirebaseException(
          plugin: 'firebase_storage',
          code: 'unauthorized',
        );

        when(() => mockFileRef.delete()).thenThrow(firebaseException);

        await check(
          service.deleteAvatarByUrl(avatarUrl: avatarUrl),
        ).throws<AppException>();

        verify(
          () => mockTalker.handle(
            firebaseException,
            any<StackTrace?>(),
            'Firebase Storage delete error',
          ),
        ).called(1);
      },
    );

    test(
      'deleteAvatarByUrl: 異常系 - 予期せぬ例外発生時は AppException.unknown を投げること',
      () async {
        final genericException = Exception('Network down');

        when(() => mockFileRef.delete()).thenThrow(genericException);

        await check(
          service.deleteAvatarByUrl(avatarUrl: avatarUrl),
        ).throws<AppException>();

        verify(
          () => mockTalker.handle(
            genericException,
            any<StackTrace?>(),
            'Unexpected error during avatar deletion',
          ),
        ).called(1);
      },
    );
  });

  group('storageServiceProvider Tests', () {
    test('storageServiceProvider: 正しく StorageService インスタンスを提供すること', () {
      final container = ProviderContainer(
        overrides: [
          firebaseStorageProvider.overrideWithValue(mockStorage),
          loggerProvider.overrideWithValue(mockTalker),
        ],
      );
      addTearDown(container.dispose);

      final storageService = container.read(storageServiceProvider);
      check(storageService).isA<StorageService>();
    });
  });
}
