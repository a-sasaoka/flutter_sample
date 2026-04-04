import 'package:flutter/material.dart';
import 'package:flutter_sample/l10n/app_localizations.dart';
import 'package:flutter_sample/src/features/user/application/user_notifier.dart'; // 💡 パス調整
import 'package:flutter_sample/src/features/user/data/user_model.dart';
import 'package:flutter_sample/src/features/user/presentation/user_list_screen.dart'; // 💡 パス調整
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mocktail/mocktail.dart';

// --- モック & フェイク定義 ---

class MockAppLocalizations extends Mock implements AppLocalizations {}

// 非同期のタイミングを無視し、直接 state(状態) を操れる Fake を作る
class FakeUserNotifier extends UserNotifier {
  int refreshCallCount = 0;

  @override
  Future<List<UserModel>> build() async {
    // 初期化時のエラーやLoadingでUIが不安定になるのを防ぐため、最初は空データで落ち着かせる
    return [];
  }

  // テストコードから好きなタイミングで状態を「強制変更」するためのメソッド
  // ignore: use_setters_to_change_properties
  void changeState(AsyncValue<List<UserModel>> newState) {
    state = newState;
  }

  @override
  Future<void> refresh() async {
    refreshCallCount++;
  }
}

class _MockLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _MockLocalizationsDelegate(this.mock);
  final MockAppLocalizations mock;
  @override
  bool isSupported(Locale locale) => true;
  @override
  Future<AppLocalizations> load(Locale locale) async => mock;
  @override
  bool shouldReload(covariant _) => false;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late MockAppLocalizations mockL10n;

  setUp(() {
    mockL10n = MockAppLocalizations();
    when(() => mockL10n.userListTitle).thenReturn('User List');
    when(() => mockL10n.errorUnknown).thenReturn('Error Occurred');
    when(() => mockL10n.close).thenReturn('Close');
  });

  UserModel createDummyUser(int id) {
    return UserModel.fromJson({
      'id': id,
      'name': 'Test User $id',
      'email': 'test$id@example.com',
      'phone': '123-456-7890',
      'website': 'https://example.com',
      'address': {
        'street': 'Test Street',
        'suite': 'Suite $id',
        'city': 'Tokyo',
        'zipcode': '100-0000',
        'geo': {'lat': '35.6895', 'lng': '139.6917'},
      },
    });
  }

  // FakeNotifier のインスタンスを保存し、テスト中いつでも操作できるようにする
  FakeUserNotifier? fakeNotifier;

  Future<void> setupWidget(WidgetTester tester) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          userProvider.overrideWith(() {
            fakeNotifier = FakeUserNotifier();
            return fakeNotifier!; // 生成したインスタンスを保持！
          }),
        ],
        child: MaterialApp(
          localizationsDelegates: [_MockLocalizationsDelegate(mockL10n)],
          home: const UserListScreen(),
        ),
      ),
    );
    // 初回の空データ描画が完全に終わるまで待つ
    await tester.pumpAndSettle();
  }

  group('UserListScreen Coverage 100% Test', () {
    testWidgets('【状態系】Loading状態の時にインジケータが表示されること', (tester) async {
      await setupWidget(tester);

      // 状態を Loading に「強制変更」
      fakeNotifier!.changeState(const AsyncValue.loading());
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('【正常系】Data状態でユーザー一覧が正しく表示されること', (tester) async {
      await setupWidget(tester);

      final dummyUsers = [createDummyUser(1), createDummyUser(2)];

      // 状態を Data に「強制変更」
      fakeNotifier!.changeState(AsyncValue.data(dummyUsers));
      await tester.pumpAndSettle();

      expect(find.text('User List'), findsOneWidget);
      expect(find.byType(ListTile), findsNWidgets(2));
      expect(find.text('Test User 1'), findsOneWidget);
    });

    testWidgets('【正常系】引っ張って更新（Pull-to-Refresh）で refresh が呼ばれること', (
      tester,
    ) async {
      await setupWidget(tester);

      fakeNotifier!.changeState(AsyncValue.data([createDummyUser(1)]));
      await tester.pumpAndSettle();

      final refreshIndicator = tester.widget<RefreshIndicator>(
        find.byType(RefreshIndicator),
      );
      await refreshIndicator.onRefresh();

      // FakeNotifier側でカウントアップされたか確認
      expect(fakeNotifier!.refreshCallCount, 1);
    });

    testWidgets('【異常系】Error状態でエラー文とSnackBarが表示されること', (tester) async {
      await setupWidget(tester);

      final exception = Exception('API Error');

      // 状態を Error に「強制変更」
      fakeNotifier!.changeState(AsyncValue.error(exception, StackTrace.empty));

      // UIに新しい状態(Error)を反映させるため、1フレームだけ画面を更新する
      await tester.pump();

      expect(find.text('Error Occurred'), findsOneWidget);

      // addPostFrameCallback で予約された SnackBar のアニメーションを少しだけ進める
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(SnackBar), findsOneWidget);
    });
  });
}
