import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/widgets/widgets_test_helper.dart';

class MockSharedPreferencesAsync extends Mock
    implements SharedPreferencesAsync {}

MockAppLocalizations setupMockL10n() {
  final mockL10n = MockAppLocalizations();
  when(() => mockL10n.onboardingSkip).thenReturn('Skip');
  when(() => mockL10n.onboardingNext).thenReturn('Next');
  when(() => mockL10n.onboardingStart).thenReturn('Get Started');
  when(() => mockL10n.onboardingPage1Title).thenReturn('シンプルなメモ機能');
  when(
    () => mockL10n.onboardingPage1Desc,
  ).thenReturn('思いついたアイデアやタスクを、いつでもどこでもすばやくメモに残すことができます。');
  when(() => mockL10n.onboardingPage2Title).thenReturn('どこでもつながる同期機能');
  when(
    () => mockL10n.onboardingPage2Desc,
  ).thenReturn('インターネットがないオフライン環境でもメモを書くことができ、接続時に自動でクラウドへ同期されます。');
  when(() => mockL10n.onboardingPage3Title).thenReturn('AIチャットアシスタント');
  when(
    () => mockL10n.onboardingPage3Desc,
  ).thenReturn('メモのまとめを作ったり、アイデアのブレインストーミングをAIアシスタントがサポートします。');
  return mockL10n;
}

MockSharedPreferencesAsync setupMockPrefs({bool completed = false}) {
  final mockPrefs = MockSharedPreferencesAsync();
  when(
    () => mockPrefs.getBool('onboarding_completed'),
  ).thenAnswer((_) async => completed);
  when(
    () => mockPrefs.setBool('onboarding_completed', any()),
  ).thenAnswer((_) async {});
  return mockPrefs;
}
