/// 共通で利用する Analytics イベント名をまとめる
/// 記録したいイベントが増えた場合はここで追加していく
enum AnalyticsEvent {
  /// アプリ起動
  appStarted('app_started'),

  /// ホーム画面のボタンタップ
  homeButtonTapped('home_analytics_button_tapped'),

  /// ログイン成功
  loginSuccess('login_success'),

  /// ログアウト
  logout('logout'),

  /// アカウント退会（完全削除）完了
  accountDeleted('account_deleted'),

  /// エラー発生
  errorOccurred('error_occurred');

  const AnalyticsEvent(this.name);

  /// イベント名
  final String name;
}
