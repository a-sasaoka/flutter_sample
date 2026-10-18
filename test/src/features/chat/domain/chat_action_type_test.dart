import 'package:checks/checks.dart';
import 'package:flutter_sample/src/features/chat/domain/chat_action_type.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ChatActionType', () {
    test('fromFunctionName: 正しい関数名からEnumへ変換できること', () {
      check(
        ChatActionType.fromFunctionName('createMemo'),
      ).equals(ChatActionType.createMemo);
      check(
        ChatActionType.fromFunctionName('listMemos'),
      ).equals(ChatActionType.listMemos);
      check(
        ChatActionType.fromFunctionName('changeThemeMode'),
      ).equals(ChatActionType.changeThemeMode);
      check(
        ChatActionType.fromFunctionName('searchWeb'),
      ).equals(ChatActionType.searchWeb);
    });

    test('fromFunctionName: 未定義の関数名の場合はnullを返すこと', () {
      check(ChatActionType.fromFunctionName('unknown')).isNull();
      check(ChatActionType.fromFunctionName('')).isNull();
    });
  });
}
