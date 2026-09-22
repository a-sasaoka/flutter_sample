import 'package:checks/checks.dart';
import 'package:flutter_sample/src/core/utils/form_validators.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FormValidators', () {
    group('notOnlyWhitespace', () {
      test('null の場合は null を返すこと', () {
        final validator = FormValidators.notOnlyWhitespace();
        check(validator(null)).isNull();
      });

      test('空文字列 の場合は null を返すこと（必須チェックは required に委譲）', () {
        final validator = FormValidators.notOnlyWhitespace();
        check(validator('')).isNull();
      });

      test('半角スペースのみ の場合はエラーメッセージを返すこと', () {
        final validator = FormValidators.notOnlyWhitespace(errorText: '空白のみ不可');
        check(validator('   ')).equals('空白のみ不可');
      });

      test('全角スペースのみ の場合はエラーメッセージを返すこと', () {
        final validator = FormValidators.notOnlyWhitespace(errorText: '空白のみ不可');
        check(validator('　　')).equals('空白のみ不可');
      });

      test('タブや改行のみ の場合はエラーメッセージを返すこと', () {
        final validator = FormValidators.notOnlyWhitespace(errorText: '空白のみ不可');
        check(validator('\t\n ')).equals('空白のみ不可');
      });

      test('デフォルトのエラーテキストが正しく返されること', () {
        final validator = FormValidators.notOnlyWhitespace();
        check(validator(' ')).equals('空白のみの入力はできません');
      });

      test('通常のテキスト の場合は null を返すこと', () {
        final validator = FormValidators.notOnlyWhitespace();
        check(validator('hello')).isNull();
      });

      test('前後に空白を含む通常のテキスト の場合は null を返すこと', () {
        final validator = FormValidators.notOnlyWhitespace();
        check(validator('  hello  ')).isNull();
      });
    });

    group('password', () {
      test('null の場合は null を返すこと', () {
        final validator = FormValidators.password();
        check(validator(null)).isNull();
      });

      test('空文字列 の場合は null を返すこと（必須チェックは required に委譲）', () {
        final validator = FormValidators.password();
        check(validator('')).isNull();
      });

      test('指定した minLength 未満の場合はエラーメッセージを返すこと', () {
        final validator = FormValidators.password(minLength: 6);
        check(validator('12345')).equals('6文字以上で入力してください');
      });

      test('カスタムエラーテキストが正しく返されること', () {
        final validator = FormValidators.password(errorText: '短すぎます');
        check(validator('1234567')).equals('短すぎます');
      });

      test('指定した minLength ちょうど の場合は null を返すこと', () {
        final validator = FormValidators.password(minLength: 6);
        check(validator('123456')).isNull();
      });

      test('指定した minLength 超 の場合は null を返すこと', () {
        final validator = FormValidators.password(minLength: 6);
        check(validator('1234567')).isNull();
      });
    });
  });
}
