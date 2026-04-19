// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// チャットのリポジトリクラスのプロバイダー
/// ※ Riverpodの初期化処理であり、内部でFirebase初期化を伴うためカバレッジから除外

@ProviderFor(chatRepository)
const chatRepositoryProvider = ChatRepositoryProvider._();

/// チャットのリポジトリクラスのプロバイダー
/// ※ Riverpodの初期化処理であり、内部でFirebase初期化を伴うためカバレッジから除外

final class ChatRepositoryProvider
    extends $FunctionalProvider<ChatRepository, ChatRepository, ChatRepository>
    with $Provider<ChatRepository> {
  /// チャットのリポジトリクラスのプロバイダー
  /// ※ Riverpodの初期化処理であり、内部でFirebase初期化を伴うためカバレッジから除外
  const ChatRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'chatRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$chatRepositoryHash();

  @$internal
  @override
  $ProviderElement<ChatRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  ChatRepository create(Ref ref) {
    return chatRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ChatRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ChatRepository>(value),
    );
  }
}

String _$chatRepositoryHash() => r'2c662ce1c9186f91d7ca96cdd2b4844b63e6fa8f';
