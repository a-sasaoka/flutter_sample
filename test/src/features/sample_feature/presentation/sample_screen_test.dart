import 'package:flutter/material.dart';
import 'package:flutter_sample/l10n/app_localizations.dart';
import 'package:flutter_sample/src/features/sample_feature/presentation/sample_screen.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

// --- モック ---
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

void main() {
  late MockAppLocalizations mockL10n;

  setUp(() {
    mockL10n = MockAppLocalizations();
    // 翻訳テキストのスタブ
    when(() => mockL10n.sampleTitle).thenReturn('サンプル画面');
    when(() => mockL10n.sampleDescription).thenReturn('これはサンプルの説明文です');
  });

  testWidgets('SampleScreen が正しく表示され、翻訳テキストが反映されていること', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: [
          _MockLocalizationsDelegate(mockL10n),
        ],
        home: const SampleScreen(),
      ),
    );

    // 翻訳の反映やレイアウトをしっかり待つ
    await tester.pumpAndSettle();

    // 部分一致 (textContaining) を使うことで、AppBar 内のレンダリング差異を回避
    expect(find.textContaining('サンプル画面'), findsOneWidget);
    expect(find.textContaining('これはサンプルの説明文です'), findsOneWidget);

    expect(find.byType(Center), findsOneWidget);
  });
}
