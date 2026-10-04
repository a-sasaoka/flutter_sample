import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'app_lock_state_provider.g.dart';

/// アプリがロック解除済み（操作可能状態）かどうかを提供するプロバイダー
///
/// デフォルト実装は、Core層が特定機能に依存せず動作できるよう `true`（ロックなし）を返します。
/// アプリ起動時に `appLockOverrides` 等を通じて、実際のアプリロック状態と同期するようにオーバーライドされます。
@Riverpod(keepAlive: true)
bool isAppUnlocked(Ref ref) => true;
