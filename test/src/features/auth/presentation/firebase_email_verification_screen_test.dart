// ignore_for_file: use_setters_to_change_properties, document_ignores

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sample/l10n/app_localizations.dart';
import 'package:flutter_sample/src/features/auth/application/firebase_auth_state_notifier.dart';
import 'package:flutter_sample/src/features/auth/data/firebase_auth_repository.dart';
import 'package:flutter_sample/src/features/auth/presentation/firebase_email_verification_screen.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mocktail/mocktail.dart';

class MockFirebaseAuthRepository extends Mock
    implements FirebaseAuthRepository {}

class MockUser extends Mock implements User {}

class MockAppLocalizations extends Mock implements AppLocalizations {}

class _MockLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _MockLocalizationsDelegate(this.mock);
  final MockAppLocalizations mock;
  @override
  bool isSupported(Locale locale) => true;
  @override
  Future<AppLocalizations> load(Locale locale) async => mock;
  @override
  bool shouldReload(covariant LocalizationsDelegate<AppLocalizations> old) =>
      false;
}

class FakeFirebaseAuthStateNotifier extends FirebaseAuthStateNotifier {
  FakeFirebaseAuthStateNotifier(this.initialState);
  final User? initialState;

  @override
  User? build() => initialState;

  void updateState(User? newUser) {
    state = newUser;
  }
}

void main() {
  late MockFirebaseAuthRepository mockAuthRepo;
  late MockUser mockUser;
  late MockAppLocalizations mockL10n;

  setUp(() {
    mockAuthRepo = MockFirebaseAuthRepository();
    mockUser = MockUser();
    mockL10n = MockAppLocalizations();

    when(() => mockL10n.emailVerificationTitle).thenReturn('メール認証');
    when(
      () => mockL10n.emailVerificationDescription,
    ).thenReturn('確認メールを送信しました。');
    when(() => mockL10n.resendVerificationMail).thenReturn('再送信する');
    when(() => mockL10n.emailVerificationWaiting).thenReturn('認証待ちです...');
    when(() => mockL10n.checkVerificationStatus).thenReturn('認証を完了したか確認する');

    when(() => mockAuthRepo.sendEmailVerification()).thenAnswer((_) async {});
    when(() => mockAuthRepo.reloadCurrentUser()).thenAnswer((_) async {});
  });

  Widget createTestWidget(ProviderContainer container) {
    final router = GoRouter(
      initialLocation: '/verify',
      routes: [
        GoRoute(
          path: '/verify',
          builder: (context, state) => const FirebaseEmailVerificationScreen(),
        ),
      ],
      errorBuilder: (context, state) => Scaffold(
        body: Text('Navigated to ${state.uri}'),
      ),
    );

    return UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(
        routerConfig: router,
        localizationsDelegates: [_MockLocalizationsDelegate(mockL10n)],
      ),
    );
  }

  group('FirebaseEmailVerificationScreen', () {
    testWidgets('UIが正しくレンダリングされ、再送信ボタンが動作すること', (tester) async {
      when(() => mockUser.emailVerified).thenReturn(false);

      final container = ProviderContainer(
        overrides: [
          firebaseAuthRepositoryProvider.overrideWithValue(mockAuthRepo),
          firebaseAuthStateProvider.overrideWith(
            () => FakeFirebaseAuthStateNotifier(mockUser),
          ),
        ],
      );

      await tester.pumpWidget(createTestWidget(container));
      await tester.pumpAndSettle();

      expect(find.text('メール認証'), findsOneWidget);
      expect(find.text('確認メールを送信しました。'), findsOneWidget);
      expect(find.text('認証を完了したか確認する'), findsOneWidget);
      expect(find.text('認証待ちです...'), findsOneWidget);

      await tester.tap(find.text('再送信する'));
      await tester.pump();

      verify(() => mockAuthRepo.sendEmailVerification()).called(1);
    });

    testWidgets('手動確認ボタンをタップした時、ユーザー情報がリロードされること', (tester) async {
      when(() => mockUser.emailVerified).thenReturn(false);

      final container = ProviderContainer(
        overrides: [
          firebaseAuthRepositoryProvider.overrideWithValue(mockAuthRepo),
          firebaseAuthStateProvider.overrideWith(
            () => FakeFirebaseAuthStateNotifier(mockUser),
          ),
        ],
      );

      await tester.pumpWidget(createTestWidget(container));
      await tester.pumpAndSettle();

      await tester.tap(find.text('認証を完了したか確認する'));
      await tester.pump();

      verify(() => mockAuthRepo.reloadCurrentUser()).called(1);
    });

    testWidgets('アプリがバックグラウンドから復帰(resumed)した時、ユーザー情報がリロードされること', (
      tester,
    ) async {
      when(() => mockUser.emailVerified).thenReturn(false);

      final container = ProviderContainer(
        overrides: [
          firebaseAuthRepositoryProvider.overrideWithValue(mockAuthRepo),
          firebaseAuthStateProvider.overrideWith(
            () => FakeFirebaseAuthStateNotifier(mockUser),
          ),
        ],
      );

      await tester.pumpWidget(createTestWidget(container));
      await tester.pumpAndSettle();

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();

      verify(() => mockAuthRepo.reloadCurrentUser()).called(1);
    });

    testWidgets(
      'ユーザー状態が変更され emailVerified == true になると、自動で HomeRoute に遷移すること',
      (tester) async {
        when(() => mockUser.emailVerified).thenReturn(false);

        final container = ProviderContainer(
          overrides: [
            firebaseAuthRepositoryProvider.overrideWithValue(mockAuthRepo),
            firebaseAuthStateProvider.overrideWith(
              () => FakeFirebaseAuthStateNotifier(mockUser),
            ),
          ],
        );

        await tester.pumpWidget(createTestWidget(container));
        await tester.pumpAndSettle();

        final verifiedUser = MockUser();
        when(() => verifiedUser.emailVerified).thenReturn(true);

        (container.read(firebaseAuthStateProvider.notifier)
                as FakeFirebaseAuthStateNotifier)
            .updateState(verifiedUser);

        await tester.pumpAndSettle();

        expect(find.textContaining('Navigated to'), findsOneWidget);
        expect(find.text('メール認証'), findsNothing);
      },
    );
  });
}
