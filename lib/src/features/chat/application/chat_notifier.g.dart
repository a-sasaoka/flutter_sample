// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// チャットのやり取りを管理するプロバーダー

@ProviderFor(ChatNotifier)
final chatProvider = ChatNotifierProvider._();

/// チャットのやり取りを管理するプロバーダー
final class ChatNotifierProvider
    extends $NotifierProvider<ChatNotifier, ChatState> {
  /// チャットのやり取りを管理するプロバーダー
  ChatNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'chatProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$chatNotifierHash();

  @$internal
  @override
  ChatNotifier create() => ChatNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ChatState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ChatState>(value),
    );
  }
}

String _$chatNotifierHash() => r'795f0d385d62f25a562eba89aad46bd6d82a3b50';

/// チャットのやり取りを管理するプロバーダー

abstract class _$ChatNotifier extends $Notifier<ChatState> {
  ChatState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<ChatState, ChatState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<ChatState, ChatState>,
              ChatState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
