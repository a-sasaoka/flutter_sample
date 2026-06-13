import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_sample/src/core/ui/l10n_extension.dart';
import 'package:flutter_sample/src/features/onboarding/application/onboarding_notifier.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// アプリの初回起動時に表示されるオンボーディング画面
class OnboardingScreen extends HookConsumerWidget {
  /// コンストラクタ
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final pageController = usePageController();
    final currentPage = useState(0);

    // 3ページ分のデータを定義します
    final pages = [
      _OnboardingPageData(
        title: l10n.onboardingPage1Title,
        description: l10n.onboardingPage1Desc,
        icon: Icons.edit_document,
        colors: [Colors.blue.shade300, Colors.blue.shade700],
      ),
      _OnboardingPageData(
        title: l10n.onboardingPage2Title,
        description: l10n.onboardingPage2Desc,
        icon: Icons.sync,
        colors: [Colors.teal.shade300, Colors.teal.shade700],
      ),
      _OnboardingPageData(
        title: l10n.onboardingPage3Title,
        description: l10n.onboardingPage3Desc,
        icon: Icons.chat_bubble,
        colors: [Colors.purple.shade300, Colors.purple.shade700],
      ),
    ];

    void completeOnboarding() {
      unawaited(ref.read(onboardingProvider.notifier).complete());
    }

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // 右上のスキップボタン
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.only(top: 8, right: 16),
                child: TextButton(
                  onPressed: completeOnboarding,
                  child: Text(
                    l10n.onboardingSkip,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
            // スライド表示領域
            Expanded(
              child: PageView.builder(
                controller: pageController,
                itemCount: pages.length,
                onPageChanged: (index) => currentPage.value = index,
                itemBuilder: (context, index) {
                  return _OnboardingPage(data: pages[index]);
                },
              ),
            ),
            // 下部のナビゲーション（インジケータと進むボタン）
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // カスタムドットインジケータ
                  Row(
                    children: List.generate(pages.length, (index) {
                      final isSelected = currentPage.value == index;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        height: 8,
                        width: isSelected ? 24 : 8,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Theme.of(context).colorScheme.primary
                              : Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      );
                    }),
                  ),
                  // 次へ / はじめるボタン
                  ElevatedButton(
                    onPressed: () {
                      if (currentPage.value == pages.length - 1) {
                        completeOnboarding();
                      } else {
                        unawaited(
                          pageController.nextPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                    child: Text(
                      currentPage.value == pages.length - 1
                          ? l10n.onboardingStart
                          : l10n.onboardingNext,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 各スライドのデータクラス
class _OnboardingPageData {
  const _OnboardingPageData({
    required this.title,
    required this.description,
    required this.icon,
    required this.colors,
  });

  final String title;
  final String description;
  final IconData icon;
  final List<Color> colors;
}

/// 各スライドのUIを表示するウィジェット
class _OnboardingPage extends StatelessWidget {
  const _OnboardingPage({required this.data});

  final _OnboardingPageData data;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // ビジュアルイラストカード
          Container(
            height: 220,
            width: 220,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: data.colors,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(32),
              boxShadow: [
                BoxShadow(
                  color: data.colors.last.withValues(alpha: 0.4),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Icon(
              data.icon,
              size: 100,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 48),
          // タイトル
          Text(
            data.title,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          // 説明文
          Text(
            data.description,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
