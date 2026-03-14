// 環境ごとにログ出力を制御するLoggerプロバイダ

import 'package:flutter_sample/src/core/config/flavor_provider.dart';
import 'package:logger/logger.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'logger_provider.g.dart';

/// Loggerプロバイダ
@Riverpod(keepAlive: true)
Logger logger(Ref ref) {
  return Logger(
    level: ref.read(flavorProvider) == Flavor.prod
        ? Level.warning
        : Level.debug,
    printer: PrettyPrinter(
      methodCount: 0,
      errorMethodCount: 3,
      lineLength: 80,
      dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
    ),
  );
}
