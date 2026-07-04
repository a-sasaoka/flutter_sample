import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_sample/src/core/ui/error_handler.dart';
import 'package:flutter_sample/src/core/ui/l10n_extension.dart';
import 'package:flutter_sample/src/features/profile/application/profile_notifier.dart';
import 'package:flutter_sample/src/features/profile/domain/user_profile.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// 厳格に半角数字のみを許可し、非半角数字が1文字でも含まれるペーストや入力を完全に拒否するFormatter
class StrictDigitsTextInputFormatter extends TextInputFormatter {
  /// コンストラクタ
  const StrictDigitsTextInputFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // 空文字の場合はクリア操作などのためにそのまま許可する
    if (newValue.text.isEmpty) {
      return newValue;
    }

    // 入力後のテキスト全体が半角数字のみで構成されているかチェック
    final regExp = RegExp(r'^[0-9]+$');
    if (!regExp.hasMatch(newValue.text)) {
      // 1文字でも非半角数字が含まれている場合は入力を完全に拒否し、古いテキスト値を維持する
      return oldValue;
    }

    return newValue;
  }
}

/// 会員情報登録・変更画面
class ProfileEditScreen extends ConsumerWidget {
  /// コンストラクタ
  const ProfileEditScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileProvider);
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.profileTitle),
      ),
      body: switch (profileAsync) {
        AsyncData(value: final profile) => _ProfileEditForm(profile: profile),
        AsyncError(:final error) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${l10n.errorOccurred}: $error',
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.invalidate(profileProvider),
                child: Text(l10n.retry),
              ),
            ],
          ),
        ),
        _ => const Center(
          child: ExcludeSemantics(
            child: CircularProgressIndicator.adaptive(),
          ),
        ),
      },
    );
  }
}

/// 会員情報入力フォーム部分のウィジェット
class _ProfileEditForm extends HookConsumerWidget {
  const _ProfileEditForm({required this.profile});

  final UserProfile profile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formKey = useMemoized(GlobalKey<FormState>.new);
    final l10n = context.l10n;

    // Hookを使用して各テキストエディティングコントローラを管理（初期値をセット）
    final nameController = useTextEditingController(text: profile.name);
    final emailController = useTextEditingController(text: profile.email);
    final displayNameController = useTextEditingController(
      text: profile.displayName,
    );
    final phoneController = useTextEditingController(text: profile.phone);

    final profileState = ref.watch(profileProvider);
    final isLoading = profileState.isLoading;

    // 保存ボタン押下時の処理
    Future<void> onSubmit() async {
      if (formKey.currentState?.validate() ?? false) {
        final updatedProfile = UserProfile(
          name: nameController.text.trim(),
          email: emailController.text.trim(),
          displayName: displayNameController.text.trim(),
          phone: phoneController.text.trim(),
        );

        try {
          await ref
              .read(profileProvider.notifier)
              .updateProfile(updatedProfile);
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(l10n.profileSaveSuccess)),
            );
          }
        } on Exception catch (e) {
          if (context.mounted) {
            ErrorHandler.showSnackBar(context, e);
          }
        }
      }
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 氏名
            TextFormField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: l10n.profileNameLabel,
                hintText: l10n.profileNameHint,
                border: const OutlineInputBorder(),
              ),
              validator: FormBuilderValidators.compose([
                (value) {
                  if (value != null &&
                      value.isNotEmpty &&
                      value.trim().isEmpty) {
                    return l10n.profileNameEmpty;
                  }
                  return null;
                },
                FormBuilderValidators.required(
                  errorText: l10n.profileNameRequired,
                ),
                FormBuilderValidators.maxLength(
                  128,
                  errorText: l10n.profileNameMaxLength,
                ),
              ]),
              enabled: !isLoading,
            ),
            const SizedBox(height: 16),

            // メールアドレス
            TextFormField(
              controller: emailController,
              decoration: InputDecoration(
                labelText: l10n.profileEmailLabel,
                hintText: 'example@example.com',
                border: const OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
              validator: FormBuilderValidators.compose([
                FormBuilderValidators.required(
                  errorText: l10n.profileEmailRequired,
                ),
                FormBuilderValidators.email(
                  errorText: l10n.profileEmailInvalid,
                ),
                FormBuilderValidators.maxLength(
                  256,
                  errorText: l10n.profileEmailMaxLength,
                ),
              ]),
              enabled: !isLoading,
            ),
            const SizedBox(height: 16),

            // 表示名
            TextFormField(
              controller: displayNameController,
              decoration: InputDecoration(
                labelText: l10n.profileDisplayNameLabel,
                hintText: l10n.profileDisplayNameHint,
                border: const OutlineInputBorder(),
              ),
              validator: FormBuilderValidators.compose([
                FormBuilderValidators.maxLength(
                  128,
                  errorText: l10n.profileDisplayNameMaxLength,
                ),
              ]),
              enabled: !isLoading,
            ),
            const SizedBox(height: 16),

            // 電話番号
            TextFormField(
              controller: phoneController,
              decoration: InputDecoration(
                labelText: l10n.profilePhoneLabel,
                hintText: '09012345678',
                border: const OutlineInputBorder(),
              ),
              keyboardType: TextInputType.phone,
              inputFormatters: const [
                StrictDigitsTextInputFormatter(),
              ],
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return null; // 任意入力のため空は許可
                }

                if (!RegExp(r'^[0-9]+$').hasMatch(value)) {
                  return l10n.profilePhoneInvalid;
                }

                // 携帯・IP（090, 080, 070, 050）の判定
                final isMobileOrIp =
                    value.startsWith('090') ||
                    value.startsWith('080') ||
                    value.startsWith('070') ||
                    value.startsWith('050');

                if (isMobileOrIp) {
                  if (value.length != 11) {
                    return l10n.profilePhoneMobileLength;
                  }
                } else {
                  if (value.length != 10) {
                    return l10n.profilePhoneLandlineLength;
                  }
                }
                return null;
              },
              enabled: !isLoading,
            ),
            const SizedBox(height: 32),

            // 保存ボタン
            ElevatedButton(
              onPressed: isLoading ? null : onSubmit,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(l10n.profileSaveButton),
            ),
          ],
        ),
      ),
    );
  }
}
