import 'package:checks/checks.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_sample/src/features/auth/data/firebase_auth_token_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockFirebaseAuth extends Mock implements FirebaseAuth {}

class MockUser extends Mock implements User {}

void main() {
  late MockFirebaseAuth mockFirebaseAuth;
  late MockUser mockUser;
  late FirebaseAuthTokenStorage tokenStorage;

  setUp(() {
    mockFirebaseAuth = MockFirebaseAuth();
    mockUser = MockUser();
    tokenStorage = FirebaseAuthTokenStorage(mockFirebaseAuth);
  });

  group('FirebaseAuthTokenStorage', () {
    test('getAccessToken: ユーザーがログイン状態の時、最新のIDトークンを返すこと', () async {
      when(() => mockFirebaseAuth.currentUser).thenReturn(mockUser);
      when(
        () => mockUser.getIdToken(),
      ).thenAnswer((_) async => 'dummy_id_token');

      final token = await tokenStorage.getAccessToken();

      check(token).equals('dummy_id_token');
      verify(() => mockFirebaseAuth.currentUser).called(1);
      verify(() => mockUser.getIdToken()).called(1);
    });

    test('getAccessToken: ユーザーが未ログイン状態の時、nullを返すこと', () async {
      when(() => mockFirebaseAuth.currentUser).thenReturn(null);

      final token = await tokenStorage.getAccessToken();

      check(token).isNull();
      verify(() => mockFirebaseAuth.currentUser).called(1);
    });

    test('getRefreshToken: 常にnullを返すこと', () async {
      final token = await tokenStorage.getRefreshToken();
      check(token).isNull();
    });

    test('saveTokens: 何も処理を行わないこと', () async {
      await check(
        tokenStorage.saveTokens(
          accessToken: 'dummy_access',
          refreshToken: 'dummy_refresh',
        ),
      ).completes();
    });

    test('clear: 何も処理を行わないこと', () async {
      await check(tokenStorage.clear()).completes();
    });
  });
}
