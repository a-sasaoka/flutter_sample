import 'dart:typed_data';

import 'package:checks/checks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_checks/flutter_checks.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_sample/l10n/app_localizations.dart';
import 'package:flutter_sample/src/core/utils/logger_provider.dart';
import 'package:flutter_sample/src/features/app_lock/application/app_lock_service.dart';
import 'package:flutter_sample/src/features/app_lock/domain/app_lock_state.dart';
import 'package:flutter_sample/src/features/share/application/share_service.dart';
import 'package:flutter_sample/src/features/share/presentation/share_demo_screen.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';
import 'package:mocktail/mocktail.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:share_plus/share_plus.dart';
import 'package:talker_flutter/talker_flutter.dart';

class MockShareService extends Mock implements ShareService {}

class MockImagePickerPlatform extends Mock
    with MockPlatformInterfaceMixin
    implements ImagePickerPlatform {}

class FakeImagePickerOptions extends Fake implements ImagePickerOptions {}

class FakeAppLockService extends AppLockService {
  int suppressionCallCount = 0;

  @override
  Future<AppLockState> build() async => const AppLockState.disabled();

  @override
  Future<T> runWithLockSuppression<T>(Future<T> Function() action) async {
    suppressionCallCount++;
    return await action();
  }
}

void main() {
  late MockShareService mockShareService;
  late ImagePickerPlatform originalImagePickerPlatform;
  late MockImagePickerPlatform mockImagePickerPlatform;
  late FakeAppLockService fakeAppLockService;
  late Talker talker;

  setUpAll(() {
    registerFallbackValue(const Rect.fromLTWH(0, 0, 10, 10));
    registerFallbackValue(FakeImagePickerOptions());
    originalImagePickerPlatform = ImagePickerPlatform.instance;
  });

  tearDownAll(() {
    ImagePickerPlatform.instance = originalImagePickerPlatform;
  });

  setUp(() {
    mockShareService = MockShareService();
    mockImagePickerPlatform = MockImagePickerPlatform();
    fakeAppLockService = FakeAppLockService();
    talker = Talker(settings: TalkerSettings(useConsoleLogs: false));
    ImagePickerPlatform.instance = mockImagePickerPlatform;
  });

  Widget buildTestWidget() {
    return ProviderScope(
      overrides: [
        shareServiceProvider.overrideWithValue(mockShareService),
        appLockServiceProvider.overrideWith(() => fakeAppLockService),
        loggerProvider.overrideWithValue(talker),
      ],
      child: const MaterialApp(
        localizationsDelegates: [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        locale: Locale('ja'),
        home: ShareDemoScreen(),
      ),
    );
  }

  group('ShareDemoScreen - UI Rendering', () {
    testWidgets('主要なUI要素がすべて正しく表示されること', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      check(find.text('SNSシェア機能')).findsOne();
      check(find.text('テキスト・URL共有（OS標準）')).findsOne();

      check(find.byKey(const Key('share_text_field'))).findsOne();
      check(find.byKey(const Key('share_url_field'))).findsOne();
      check(find.byKey(const Key('share_subject_field'))).findsOne();
      check(find.byKey(const Key('share_text_button'))).findsOne();

      // 画面下部の画像共有セクションまでスクロール
      final imageSectionFinder = find.text('画像共有（OS標準）');
      await tester.dragUntilVisible(
        imageSectionFinder,
        find.byType(ListView),
        const Offset(0, -200),
      );
      check(imageSectionFinder).findsOne();
      check(find.byKey(const Key('pick_image_button'))).findsOne();
      check(find.byKey(const Key('share_sample_image_button'))).findsOne();

      // さらに画面最下部の特定SNSセクションまでスクロール
      final directSnsFinder = find.text('特定のSNSへ直接共有');
      await tester.dragUntilVisible(
        directSnsFinder,
        find.byType(ListView),
        const Offset(0, -200),
      );
      check(directSnsFinder).findsOne();
      check(find.byKey(const Key('share_x_button'))).findsOne();
      check(find.byKey(const Key('share_line_button'))).findsOne();
    });
  });

  group('ShareDemoScreen - Actions', () {
    testWidgets('テキスト共有ボタンをタップした時、shareText が呼ばれ成功SnackBarが表示されること', (
      tester,
    ) async {
      when(
        () => mockShareService.shareText(
          text: any(named: 'text'),
          subject: any(named: 'subject'),
          sharePositionOrigin: any(named: 'sharePositionOrigin'),
        ),
      ).thenAnswer(
        (_) async => const ShareResult('success', ShareResultStatus.success),
      );

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('share_text_button')));
      await tester.pumpAndSettle();

      verify(
        () => mockShareService.shareText(
          text: any(named: 'text'),
          subject: any(named: 'subject'),
          sharePositionOrigin: any(named: 'sharePositionOrigin'),
        ),
      ).called(1);

      check(find.text('共有が完了しました')).findsOne();
    });

    testWidgets('共有がキャンセルされた場合、キャンセルSnackBarが表示されること', (tester) async {
      when(
        () => mockShareService.shareText(
          text: any(named: 'text'),
          subject: any(named: 'subject'),
          sharePositionOrigin: any(named: 'sharePositionOrigin'),
        ),
      ).thenAnswer(
        (_) async => const ShareResult('', ShareResultStatus.dismissed),
      );

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('share_text_button')));
      await tester.pumpAndSettle();

      check(find.text('共有がキャンセルされました')).findsOne();
    });

    testWidgets('サンプル画像即時シェアボタンをタップした時、shareXFiles が呼ばれること', (tester) async {
      when(() => mockShareService.createSampleImage()).thenAnswer(
        (_) async => XFile.fromData(
          Uint8List(0),
          mimeType: 'image/png',
          name: 'sample.png',
        ),
      );
      when(
        () => mockShareService.shareXFiles(
          files: any(named: 'files'),
          text: any(named: 'text'),
          sharePositionOrigin: any(named: 'sharePositionOrigin'),
        ),
      ).thenAnswer(
        (_) async => const ShareResult('success', ShareResultStatus.success),
      );

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      final sampleBtn = find.byKey(const Key('share_sample_image_button'));
      await tester.dragUntilVisible(
        sampleBtn,
        find.byType(ListView),
        const Offset(0, -200),
      );
      await tester.drag(find.byType(ListView), const Offset(0, -150));
      await tester.pumpAndSettle();

      await tester.tap(sampleBtn);
      await tester.pumpAndSettle();

      verify(
        () => mockShareService.shareXFiles(
          files: any(named: 'files'),
          text: any(named: 'text'),
          sharePositionOrigin: any(named: 'sharePositionOrigin'),
        ),
      ).called(1);

      check(find.text('共有が完了しました')).findsOne();
    });

    testWidgets('Xでポストボタンをタップした時、shareToX が呼ばれ成功SnackBarが表示されること', (
      tester,
    ) async {
      when(
        () => mockShareService.shareToX(
          text: any(named: 'text'),
          url: any(named: 'url'),
          hashtags: any(named: 'hashtags'),
        ),
      ).thenAnswer((_) async => true);

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      final xBtn = find.byKey(const Key('share_x_button'));
      await tester.dragUntilVisible(
        xBtn,
        find.byType(ListView),
        const Offset(0, -200),
      );
      await tester.drag(find.byType(ListView), const Offset(0, -150));
      await tester.pumpAndSettle();

      await tester.tap(xBtn);
      await tester.pumpAndSettle();

      verify(
        () => mockShareService.shareToX(
          text: any(named: 'text'),
          url: any(named: 'url'),
          hashtags: any(named: 'hashtags'),
        ),
      ).called(1);

      check(find.text('Xを開きました')).findsOne();
    });

    testWidgets('LINEで送るボタンをタップした時、shareToLine が呼ばれ成功SnackBarが表示されること', (
      tester,
    ) async {
      when(
        () => mockShareService.shareToLine(text: any(named: 'text')),
      ).thenAnswer((_) async => true);

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      final lineBtn = find.byKey(const Key('share_line_button'));
      await tester.dragUntilVisible(
        lineBtn,
        find.byType(ListView),
        const Offset(0, -200),
      );
      await tester.drag(find.byType(ListView), const Offset(0, -150));
      await tester.pumpAndSettle();

      await tester.tap(lineBtn);
      await tester.pumpAndSettle();

      verify(
        () => mockShareService.shareToLine(text: any(named: 'text')),
      ).called(1);

      check(find.text('LINEを開きました')).findsOne();
    });

    testWidgets('共有が利用不可の場合、利用不可SnackBarが表示されること', (tester) async {
      when(
        () => mockShareService.shareText(
          text: any(named: 'text'),
          subject: any(named: 'subject'),
          sharePositionOrigin: any(named: 'sharePositionOrigin'),
        ),
      ).thenAnswer(
        (_) async => const ShareResult('', ShareResultStatus.unavailable),
      );

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('share_text_button')));
      await tester.pumpAndSettle();

      check(find.text('共有機能を利用できません')).findsOne();
    });

    testWidgets('テキストとURLが共に空欄の場合、テキスト共有が実行されないこと', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('share_text_field')), '');
      await tester.enterText(find.byKey(const Key('share_url_field')), '');
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('share_text_button')));
      await tester.pumpAndSettle();

      verifyNever(
        () => mockShareService.shareText(
          text: any(named: 'text'),
          subject: any(named: 'subject'),
          sharePositionOrigin: any(named: 'sharePositionOrigin'),
        ),
      );
    });

    testWidgets('アルバムから画像を選択した時、プレビューが表示され共有実行できること', (tester) async {
      when(
        () => mockImagePickerPlatform.getImageFromSource(
          source: ImageSource.gallery,
          options: any(named: 'options'),
        ),
      ).thenAnswer(
        (_) async => XFile('test/dummy_image.png', name: 'dummy_image.png'),
      );
      when(
        () => mockShareService.shareXFiles(
          files: any(named: 'files'),
          text: any(named: 'text'),
          sharePositionOrigin: any(named: 'sharePositionOrigin'),
        ),
      ).thenAnswer(
        (_) async => const ShareResult('success', ShareResultStatus.success),
      );

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      final pickBtn = find.byKey(const Key('pick_image_button'));
      await tester.dragUntilVisible(
        pickBtn,
        find.byType(ListView),
        const Offset(0, -200),
      );
      await tester.drag(find.byType(ListView), const Offset(0, -150));
      await tester.pumpAndSettle();

      await tester.tap(pickBtn);
      await tester.pumpAndSettle();

      // 選択した画像のファイル名が表示されていること
      check(find.text('選択中の画像: dummy_image.png')).findsOne();

      // 選択画像共有ボタンが表示されていること
      final shareSelectedBtn = find.byKey(
        const Key('share_selected_image_button'),
      );
      check(shareSelectedBtn).findsOne();

      // 選択画像共有ボタンをタップ
      await tester.tap(shareSelectedBtn);
      await tester.pumpAndSettle();

      verify(
        () => mockShareService.shareXFiles(
          files: any(named: 'files'),
          text: any(named: 'text'),
          sharePositionOrigin: any(named: 'sharePositionOrigin'),
        ),
      ).called(1);
      check(find.text('共有が完了しました')).findsOne();
      check(fakeAppLockService.suppressionCallCount).isGreaterThan(0);
    });

    testWidgets('画像読み込みエラー時に broken_image アイコンが表示されること', (tester) async {
      when(
        () => mockImagePickerPlatform.getImageFromSource(
          source: ImageSource.gallery,
          options: any(named: 'options'),
        ),
      ).thenAnswer(
        (_) async => XFile('test/dummy_image.png', name: 'dummy_image.png'),
      );

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      final pickBtn = find.byKey(const Key('pick_image_button'));
      await tester.dragUntilVisible(
        pickBtn,
        find.byType(ListView),
        const Offset(0, -200),
      );
      await tester.drag(find.byType(ListView), const Offset(0, -150));
      await tester.pumpAndSettle();

      await tester.tap(pickBtn);
      await tester.pumpAndSettle();

      final imageWidget = tester.widget<Image>(find.byType(Image));
      final errorWidget = imageWidget.errorBuilder!(
        tester.element(find.byType(Image)),
        Exception('Image load error'),
        StackTrace.empty,
      );

      await tester.pumpWidget(MaterialApp(home: Scaffold(body: errorWidget)));
      await tester.pumpAndSettle();

      check(find.byIcon(Icons.broken_image)).findsOne();
    });

    testWidgets('選択中画像の削除ボタン（✕）をタップした時、画像がクリアされること', (tester) async {
      when(
        () => mockImagePickerPlatform.getImageFromSource(
          source: ImageSource.gallery,
          options: any(named: 'options'),
        ),
      ).thenAnswer(
        (_) async => XFile('test/dummy_image.png', name: 'dummy_image.png'),
      );

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      final pickBtn = find.byKey(const Key('pick_image_button'));
      await tester.dragUntilVisible(
        pickBtn,
        find.byType(ListView),
        const Offset(0, -200),
      );
      await tester.drag(find.byType(ListView), const Offset(0, -150));
      await tester.pumpAndSettle();

      await tester.tap(pickBtn);
      await tester.pumpAndSettle();

      check(find.text('選択中の画像: dummy_image.png')).findsOne();

      // ✕ボタンをタップ
      final clearBtn = find.byIcon(Icons.close);
      await tester.tap(clearBtn);
      await tester.pumpAndSettle();

      // 選択中テキストが消え、再度画像選択ボタンが表示されていること
      check(find.text('選択中の画像: dummy_image.png')).findsNothing();
      check(find.byKey(const Key('pick_image_button'))).findsOne();
    });

    testWidgets('アルバムからの画像選択がキャンセルされた場合、選択画像がnullのままであること', (tester) async {
      when(
        () => mockImagePickerPlatform.getImageFromSource(
          source: ImageSource.gallery,
          options: any(named: 'options'),
        ),
      ).thenAnswer((_) async => null);

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      final pickBtn = find.byKey(const Key('pick_image_button'));
      await tester.dragUntilVisible(
        pickBtn,
        find.byType(ListView),
        const Offset(0, -200),
      );
      await tester.drag(find.byType(ListView), const Offset(0, -150));
      await tester.pumpAndSettle();

      await tester.tap(pickBtn);
      await tester.pumpAndSettle();

      check(
        find.byKey(const Key('share_selected_image_button')),
      ).findsNothing();
      check(find.byKey(const Key('pick_image_button'))).findsOne();
      check(fakeAppLockService.suppressionCallCount).isGreaterThan(0);
    });

    testWidgets('アルバムからの画像選択時に例外が発生した場合、エラーログが出力され画像が選択されないこと', (tester) async {
      when(
        () => mockImagePickerPlatform.getImageFromSource(
          source: ImageSource.gallery,
          options: any(named: 'options'),
        ),
      ).thenThrow(Exception('Picker failure'));

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      final pickBtn = find.byKey(const Key('pick_image_button'));
      await tester.dragUntilVisible(
        pickBtn,
        find.byType(ListView),
        const Offset(0, -200),
      );
      await tester.drag(find.byType(ListView), const Offset(0, -150));
      await tester.pumpAndSettle();

      await tester.tap(pickBtn);
      await tester.pumpAndSettle();

      check(
        find.byKey(const Key('share_selected_image_button')),
      ).findsNothing();
      check(find.byKey(const Key('pick_image_button'))).findsOne();
      check(fakeAppLockService.suppressionCallCount).isGreaterThan(0);
    });

    testWidgets('Xでポストが失敗した時、失敗SnackBarが表示されること', (tester) async {
      when(
        () => mockShareService.shareToX(
          text: any(named: 'text'),
          url: any(named: 'url'),
          hashtags: any(named: 'hashtags'),
        ),
      ).thenAnswer((_) async => false);

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      final xBtn = find.byKey(const Key('share_x_button'));
      await tester.dragUntilVisible(
        xBtn,
        find.byType(ListView),
        const Offset(0, -200),
      );
      await tester.drag(find.byType(ListView), const Offset(0, -150));
      await tester.pumpAndSettle();

      await tester.tap(xBtn);
      await tester.pumpAndSettle();

      check(find.text('Xを開けませんでした')).findsOne();
    });

    testWidgets('テキストが空の状態でXでポストボタンをタップした時、デフォルト文言が渡されること', (tester) async {
      when(
        () => mockShareService.shareToX(
          text: any(named: 'text'),
          url: any(named: 'url'),
          hashtags: any(named: 'hashtags'),
        ),
      ).thenAnswer((_) async => true);

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('share_text_field')), '');
      await tester.enterText(find.byKey(const Key('share_url_field')), '');
      await tester.pumpAndSettle();

      final xBtn = find.byKey(const Key('share_x_button'));
      await tester.dragUntilVisible(
        xBtn,
        find.byType(ListView),
        const Offset(0, -200),
      );
      await tester.drag(find.byType(ListView), const Offset(0, -150));
      await tester.pumpAndSettle();

      await tester.tap(xBtn);
      await tester.pumpAndSettle();

      verify(
        () => mockShareService.shareToX(
          text: 'Flutter Sample App からシェアしています！ #Flutter',
          hashtags: any(named: 'hashtags'),
        ),
      ).called(1);
    });

    testWidgets('LINEで送るが失敗した時、失敗SnackBarが表示されること', (tester) async {
      when(
        () => mockShareService.shareToLine(text: any(named: 'text')),
      ).thenAnswer((_) async => false);

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      final lineBtn = find.byKey(const Key('share_line_button'));
      await tester.dragUntilVisible(
        lineBtn,
        find.byType(ListView),
        const Offset(0, -200),
      );
      await tester.drag(find.byType(ListView), const Offset(0, -150));
      await tester.pumpAndSettle();

      await tester.tap(lineBtn);
      await tester.pumpAndSettle();

      check(find.text('LINEを開けませんでした')).findsOne();
    });

    testWidgets('テキストとURLが空の状態でLINEで送るボタンをタップした時、デフォルト文言が渡されること', (
      tester,
    ) async {
      when(
        () => mockShareService.shareToLine(text: any(named: 'text')),
      ).thenAnswer((_) async => true);

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('share_text_field')), '');
      await tester.enterText(find.byKey(const Key('share_url_field')), '');
      await tester.pumpAndSettle();

      final lineBtn = find.byKey(const Key('share_line_button'));
      await tester.dragUntilVisible(
        lineBtn,
        find.byType(ListView),
        const Offset(0, -200),
      );
      await tester.drag(find.byType(ListView), const Offset(0, -150));
      await tester.pumpAndSettle();

      await tester.tap(lineBtn);
      await tester.pumpAndSettle();

      verify(
        () => mockShareService.shareToLine(
          text: 'Flutter Sample App からシェアしています！ #Flutter',
        ),
      ).called(1);
    });
  });
}
