/// 共通で利用する Analytics イベント名をまとめる
enum AnalyticsEvent {
  /// アプリ起動
  appStarted('app_started'),

  /// ホーム画面のボタンタップ
  homeButtonTapped('home_analytics_button_tapped'),

  /// ログイン成功
  loginSuccess('login_success'),

  /// ログアウト
  logout('logout'),

  /// エラー発生
  errorOccurred('error_occurred');

  const AnalyticsEvent(this.name);

  /// イベント名
  final String name;
}
