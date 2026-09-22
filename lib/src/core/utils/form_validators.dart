import 'package:flutter/widgets.dart';

/// フォーム入力用の共通バリデータ集
abstract final class FormValidators {
  /// スペース（空白文字）のみの入力を弾くバリデータ
  ///
  /// null または空文字列は許容し（必須チェックは `FormBuilderValidators.required()` で行う）、
  /// 半角・全角スペースやタブ等のみが入力された実質的な空文字を検知します。
  static FormFieldValidator<String> notOnlyWhitespace({
    String errorText = '空白のみの入力はできません',
  }) {
    return (value) {
      if (value != null && value.isNotEmpty && value.trim().isEmpty) {
        return errorText;
      }
      return null;
    };
  }

  /// パスワードの最小文字数バリデータ
  static FormFieldValidator<String> password({
    int minLength = 8,
    String? errorText,
  }) {
    return (value) {
      if (value == null || value.isEmpty) {
        return null;
      }
      if (value.length < minLength) {
        return errorText ?? '$minLength文字以上で入力してください';
      }
      return null;
    };
  }
}
