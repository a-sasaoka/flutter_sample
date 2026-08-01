import 'package:local_auth/local_auth.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'local_authentication_provider.g.dart';

/// 🔐 LocalAuthentication のインスタンスを提供する Provider
@Riverpod(keepAlive: true)
LocalAuthentication localAuthentication(Ref ref) {
  return LocalAuthentication();
}
