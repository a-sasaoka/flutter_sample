// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'push_notification_service_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// [FlutterLocalNotificationsPlugin] を提供するプロバイダー

@ProviderFor(flutterLocalNotificationsPlugin)
final flutterLocalNotificationsPluginProvider =
    FlutterLocalNotificationsPluginProvider._();

/// [FlutterLocalNotificationsPlugin] を提供するプロバイダー

final class FlutterLocalNotificationsPluginProvider
    extends
        $FunctionalProvider<
          FlutterLocalNotificationsPlugin,
          FlutterLocalNotificationsPlugin,
          FlutterLocalNotificationsPlugin
        >
    with $Provider<FlutterLocalNotificationsPlugin> {
  /// [FlutterLocalNotificationsPlugin] を提供するプロバイダー
  FlutterLocalNotificationsPluginProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'flutterLocalNotificationsPluginProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$flutterLocalNotificationsPluginHash();

  @$internal
  @override
  $ProviderElement<FlutterLocalNotificationsPlugin> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  FlutterLocalNotificationsPlugin create(Ref ref) {
    return flutterLocalNotificationsPlugin(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(FlutterLocalNotificationsPlugin value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<FlutterLocalNotificationsPlugin>(
        value,
      ),
    );
  }
}

String _$flutterLocalNotificationsPluginHash() =>
    r'5012bb087ba16f70c0b479f4f83169aed9e1b683';

/// 🔔 [PushNotificationService] を提供するプロバイダー

@ProviderFor(pushNotificationService)
final pushNotificationServiceProvider = PushNotificationServiceProvider._();

/// 🔔 [PushNotificationService] を提供するプロバイダー

final class PushNotificationServiceProvider
    extends
        $FunctionalProvider<
          PushNotificationService,
          PushNotificationService,
          PushNotificationService
        >
    with $Provider<PushNotificationService> {
  /// 🔔 [PushNotificationService] を提供するプロバイダー
  PushNotificationServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'pushNotificationServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$pushNotificationServiceHash();

  @$internal
  @override
  $ProviderElement<PushNotificationService> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  PushNotificationService create(Ref ref) {
    return pushNotificationService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PushNotificationService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PushNotificationService>(value),
    );
  }
}

String _$pushNotificationServiceHash() =>
    r'bf93fbac9d9ee7de2743f7d6e940970cb424ac2f';
