// coverage:ignore-file
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

part 'uuid_provider.g.dart';

/// UUID生成器を提供するプロバイダ
@Riverpod(keepAlive: true)
Uuid uuid(Ref ref) {
  return const Uuid();
}
