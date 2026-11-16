import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/p2_widgets.dart';
import '../../category/data/category_models.dart';
import 'ai_opinion_screen.dart';

const p2DiscountIcon = 'assets/icons/p2_discount.svg';
const p2AddressIcon = 'assets/icons/p2_address.svg';
const p2ShopIcon = 'assets/icons/p2_shop.svg';
const p2SearchIcon = 'assets/icons/p2_search.svg';

/// 분석_007-01 할인 찾기 결과.
class SavingHintScreen extends StatelessWidget {
  const SavingHintScreen({
    required this.result,
    super.key,
    this.quota,
    this.linkLauncher,
  });

  final Map<String, dynamic> result;
  final Map<String, dynamic>? quota;
  final Future<bool> Function(Uri uri)? linkLauncher;

  @override
  Widget build(BuildContext context) {
    final content = result['content'] as Map<String, dynamic>? ?? const {};
    final categories =
        (content['categories'] as List? ?? const [])
            .whereType<Map<String, dynamic>>()
            .toList()
          ..sort(
            (a, b) =>
                (a['rank'] as int? ?? 99).compareTo(b['rank'] as int? ?? 99),
          );
    final suggestions = (content['search_suggestions'] as List? ?? const [])
        .whereType<Map<String, dynamic>>()
        .toList();
    return P2Page(
      title: '할인 찾기',
      children: [
        AiResultMeta(result: result),
        const SizedBox(height: 26),
        for (var i = 0; i < categories.length; i++) ...[
          if (i > 0) const SizedBox(height: 26),
          _CategoryTipCard(
            data: categories[i],
            fallbackRank: i + 1,
            linkLauncher: linkLauncher,
          ),
        ],
        if (suggestions.isNotEmpty) ...[
          const SizedBox(height: 26),
          _SearchSuggestionsCard(suggestions: suggestions),
        ],
        const SizedBox(height: 26),
        Text(
          content['disclaimer'] as String? ??
              '할인 정보는 실제와 다를 수 있어요. 매장에서 확인해 주세요.',
          style: p2Caption50,
        ),
        const SizedBox(height: 30),
        AiQuotaFooter(quota: quota),
      ],
    );
  }
}

class _CategoryTipCard extends StatelessWidget {
  const _CategoryTipCard({
    required this.data,
    required this.fallbackRank,
    this.linkLauncher,
  });

  final Map<String, dynamic> data;
  final int fallbackRank;
  final Future<bool> Function(Uri uri)? linkLauncher;

  @override
  Widget build(BuildContext context) {
    final category = data['category'] as String? ?? '';
    final rank = data['rank'] as int? ?? fallbackRank;
    final method = (data['discount_method'] as String?)?.trim();
    final tip = (data['tip'] as String?)?.trim();
    final address = data['store_address'] as String?;
    final link = data['store_link'] as String?;
    return P2Card(
      padding: const EdgeInsets.all(19),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.selected,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: P2CategoryIcon(
                  name: category,
                  kind: CategoryKind.expense,
                  color: P2Colors.lavender,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  category,
                  style: const TextStyle(
                    color: AppColors.text,
                    fontSize: 20,
                    fontWeight: FontWeight.w500,
                    height: 24 / 20,
                  ),
                ),
              ),
              P2Badge('많이 쓴 $rank위', tone: P2BadgeTone.solid),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              SvgPicture.asset(p2DiscountIcon, width: 15, height: 15),
              const SizedBox(width: 6),
              Text('할인 방법', style: p2Body.copyWith(color: AppColors.text80)),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            method == null || method.isEmpty ? (tip ?? '') : method,
            style: p2Body,
          ),
          if (address != null && address.isNotEmpty) ...[
            const SizedBox(height: 14),
            _ActionRow(
              key: Key('saving-address-$rank'),
              icon: p2AddressIcon,
              label: address,
              trailing: Text(
                '복사',
                style: p2Body.copyWith(color: AppColors.text80),
              ),
              onTap: () async {
                await Clipboard.setData(ClipboardData(text: address));
                if (context.mounted) showTopToast(context, '주소를 복사했어요');
              },
            ),
          ] else if (link != null && link.isNotEmpty) ...[
            const SizedBox(height: 14),
            _ActionRow(
              key: Key('saving-link-$rank'),
              icon: p2ShopIcon,
              label: '쇼핑몰에서 보기',
              trailing: SvgPicture.asset(
                'assets/icons/analysis_arrow_right.svg',
                width: 24,
                height: 24,
              ),
              onTap: () {
                final uri = Uri.tryParse(link);
                if (uri == null) return;
                (linkLauncher ??
                    (uri) => launchUrl(
                      uri,
                      mode: LaunchMode.externalApplication,
                    ))(uri);
              },
            ),
          ],
        ],
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.icon,
    required this.label,
    required this.trailing,
    required this.onTap,
    super.key,
  });

  final String icon;
  final String label;
  final Widget trailing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    behavior: HitTestBehavior.opaque,
    onTap: onTap,
    child: Container(
      height: 50,
      padding: const EdgeInsets.only(left: 14, right: 14),
      decoration: BoxDecoration(
        color: AppColors.selected,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          SvgPicture.asset(icon, width: 26, height: 26),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: p2Body,
            ),
          ),
          trailing,
        ],
      ),
    ),
  );
}

/// Google 검색 추천 — Google 이 준 HTML 을 수정 없이 웹뷰로 표시한다.
class _SearchSuggestionsCard extends StatelessWidget {
  const _SearchSuggestionsCard({required this.suggestions});

  final List<Map<String, dynamic>> suggestions;

  @override
  Widget build(BuildContext context) => P2Card(
    padding: const EdgeInsets.fromLTRB(15, 15, 15, 15),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            SvgPicture.asset(p2SearchIcon, width: 15, height: 15),
            const SizedBox(width: 6),
            Text(
              'Google 검색 추천',
              style: p2Body.copyWith(color: AppColors.text80),
            ),
          ],
        ),
        const SizedBox(height: 10),
        for (final suggestion in suggestions)
          _RenderedSuggestion(
            html: suggestion['rendered_content'] as String? ?? '',
            queries: (suggestion['queries'] as List? ?? const [])
                .whereType<String>()
                .toList(),
          ),
      ],
    ),
  );
}

class _RenderedSuggestion extends StatefulWidget {
  const _RenderedSuggestion({required this.html, required this.queries});

  final String html;
  final List<String> queries;

  @override
  State<_RenderedSuggestion> createState() => _RenderedSuggestionState();
}

class _RenderedSuggestionState extends State<_RenderedSuggestion> {
  WebViewController? _controller;

  @override
  void initState() {
    super.initState();
    if (WebViewPlatform.instance != null && widget.html.isNotEmpty) {
      _controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setBackgroundColor(Colors.transparent)
        ..setNavigationDelegate(
          NavigationDelegate(
            onNavigationRequest: (request) {
              final uri = Uri.tryParse(request.url);
              if (uri != null && uri.scheme.startsWith('http')) {
                launchUrl(uri, mode: LaunchMode.externalApplication);
                return NavigationDecision.prevent;
              }
              return NavigationDecision.navigate;
            },
          ),
        )
        ..loadHtmlString(
          '<html><head><meta name="viewport" content="width=device-width, '
          'initial-scale=1"></head><body style="margin:0;background:transparent">'
          '${widget.html}</body></html>',
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    if (controller != null) {
      return SizedBox(height: 56, child: WebViewWidget(controller: controller));
    }
    // 웹뷰를 쓸 수 없는 환경(테스트)에서는 검색어만 칩으로 보여준다.
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final query in widget.queries)
          Container(
            height: 33,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.selected,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              query,
              style: p2Caption80.copyWith(color: AppColors.text),
            ),
          ),
      ],
    );
  }
}

/// 분석_007-02: 할인 찾기 제3자 제공 동의 팝업. [동의]면 true.
Future<bool> showSavingHintConsent(BuildContext context) async {
  final result = await showBlurOverlay<bool>(
    context,
    label: '제3자 제공 동의',
    builder: (dialogContext) => P2DesignFrame(
      child: Center(
        child: SizedBox(
          width: 354,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 354,
                padding: const EdgeInsets.only(top: 33, bottom: 33),
                decoration: BoxDecoration(
                  color: AppColors.secondary,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    const Text(
                      '할인 찾기를 위해\nGoogle에 정보를 보낼까요?',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.text,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        height: 18 / 15,
                      ),
                    ),
                    const SizedBox(height: 18),
                    const Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: 'Google LLC',
                            style: TextStyle(color: AppColors.text),
                          ),
                          TextSpan(text: '가 '),
                          TextSpan(
                            text: '할인 정보 검색',
                            style: TextStyle(color: AppColors.text),
                          ),
                          TextSpan(text: '에 쓰고\n'),
                          TextSpan(
                            text: '최대 55일 보관 후 삭제',
                            style: TextStyle(color: AppColors.text),
                          ),
                          TextSpan(text: '해요.'),
                        ],
                      ),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.text80,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        height: 18 / 15,
                      ),
                    ),
                    const SizedBox(height: 18),
                    const ColoredBox(
                      color: Color(0x14E2E2F9),
                      child: SizedBox(width: 354, height: 1),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      '동의하지 않아도 다른 기능은 그대로 쓸 수 있어요',
                      style: p2Caption80.copyWith(color: P2Colors.lavender),
                    ),
                    const SizedBox(height: 18),
                    GestureDetector(
                      key: const Key('consent-detail-open'),
                      onTap: () => Navigator.of(dialogContext).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const SavingHintConsentDetailScreen(),
                        ),
                      ),
                      child: Container(
                        height: 29,
                        padding: const EdgeInsets.only(left: 12, right: 6),
                        decoration: BoxDecoration(
                          color: const Color(0x14E2E2F9),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '내용 보기',
                              style: p2Caption80.copyWith(
                                color: AppColors.text,
                              ),
                            ),
                            SvgPicture.asset(
                              'assets/icons/analysis_arrow_right.svg',
                              width: 20,
                              height: 20,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  P2Button(
                    key: const Key('consent-decline'),
                    label: '동의 안 함',
                    tone: P2ButtonTone.grey,
                    width: 167,
                    onPressed: () => Navigator.of(dialogContext).pop(false),
                  ),
                  const SizedBox(width: 20),
                  P2Button(
                    key: const Key('consent-agree'),
                    label: '동의',
                    width: 167,
                    onPressed: () => Navigator.of(dialogContext).pop(true),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  );
  return result ?? false;
}

/// 분석_007-03: 제3자 제공 동의 내용 보기.
class SavingHintConsentDetailScreen extends StatelessWidget {
  const SavingHintConsentDetailScreen({super.key});

  static const _rows = [
    ('제공받는 자', 'Google LLC'),
    ('제공 목적', 'Google 검색 연동으로 자주 쓰는 곳의 할인·적립 정보 찾기'),
    ('제공 항목', '지난달 많이 쓴 카테고리, 주요 품목·가맹점 이름'),
    (
      '보유·이용 기간',
      '최대 55일 보관 후 삭제\n(검색 연동 기록은 30일 보관되며, 이 기간에 검색 기능의 오류 확인·테스트에 쓰일 수 있어요)',
    ),
    (
      '동의 거부권과 불이익',
      '동의하지 않을 수 있어요. 동의하지 않으면 할인 찾기만 이용할 수 없고, 다른 기능은 그대로 이용할 수 있어요.',
    ),
    (
      '국외 이전',
      '이전 국가: 미국 등\n이전 시기·방법:\n할인 찾기를 누를 때 암호화(TLS)해 전송.\n연락처: googlekrsupport@google.com',
    ),
  ];

  @override
  Widget build(BuildContext context) => P2Page(
    title: '제3자 제공 동의 내용',
    bottomHeight: 121,
    bottom: Container(
      padding: const EdgeInsets.fromLTRB(24, 25, 24, 35),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          stops: [0, .795],
          colors: [Color(0x00121215), Color(0xE6121215)],
        ),
      ),
      child: P2Button(
        key: const Key('consent-detail-confirm'),
        label: '확인',
        onPressed: () => Navigator.of(context).pop(),
      ),
    ),
    children: [
      const Text('할인 찾기 · 선택 동의', style: p2Body),
      const SizedBox(height: 20),
      const Text(
        '할인 찾기는 Google 검색으로 자주 쓰는 곳의 할인·적립 정보를 찾아요. '
        '이를 위해 아래와 같이 개인정보를 Google LLC에 제공해요.',
        style: p2Caption80,
      ),
      const SizedBox(height: 20),
      Container(
        width: 354,
        padding: const EdgeInsets.fromLTRB(24, 25, 24, 25),
        decoration: BoxDecoration(
          color: AppColors.selected,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < _rows.length; i++) ...[
              if (i > 0) const SizedBox(height: 18),
              Text(_rows[i].$1, style: p2Caption50),
              const SizedBox(height: 4),
              Text(_rows[i].$2, style: p2Body),
            ],
          ],
        ),
      ),
    ],
  );
}
