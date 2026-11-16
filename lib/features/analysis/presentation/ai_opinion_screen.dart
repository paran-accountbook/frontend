import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/p2_widgets.dart';

const p2GlanceIcon = 'assets/icons/p2_glance.svg';
const p2WarnIcon = 'assets/icons/p2_warn.svg';
const p2CheckCircleIcon = 'assets/icons/p2_check_circle.svg';
const p2CheckIcon = 'assets/icons/p2_check.svg';

/// 분석_005-01·007-01 위쪽: '지난달(○월) 기준' + 생성일.
class AiResultMeta extends StatelessWidget {
  const AiResultMeta({required this.result, super.key});

  final Map<String, dynamic> result;

  @override
  Widget build(BuildContext context) {
    final month = monthOf(result['target_month'] as String?);
    final created = DateTime.tryParse(result['created_at'] as String? ?? '');
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        P2Badge('지난달(${month ?? ''}월) 기준'),
        if (created != null)
          Text('${created.month}월 ${created.day}일 생성', style: p2Caption50),
      ],
    );
  }
}

/// 분석_005-01·007-01 아래쪽: 남은 횟수 + 다음 충전일 버튼.
class AiQuotaFooter extends StatelessWidget {
  const AiQuotaFooter({required this.quota, super.key, this.onGenerate});

  final Map<String, dynamic>? quota;
  final VoidCallback? onGenerate;

  @override
  Widget build(BuildContext context) {
    final remaining = quota?['remaining'] as int? ?? 0;
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '이번 달 $remaining회 남음',
              style: p2Caption80.copyWith(color: AppColors.text),
            ),
            const Text('매달 1일 1회씩 새로 받아요', style: p2Caption50),
          ],
        ),
        const SizedBox(height: 20),
        if (remaining >= 1 && onGenerate != null)
          P2Button(label: '새로 받기', onPressed: onGenerate)
        else
          Container(
            key: const Key('ai-next-reset'),
            width: 354,
            height: 56,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.selected,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.text20),
            ),
            child: Text(
              '${monthDayLabel(quota?['next_reset_date'] as String?)}에 새로 받을 수 있어요',
              style: const TextStyle(
                color: AppColors.text50,
                fontSize: 15,
                fontWeight: FontWeight.w600,
                height: 18 / 15,
              ),
            ),
          ),
      ],
    );
  }
}

/// 보라 반투명 '한눈에 보기' 카드.
class AiGlanceCard extends StatelessWidget {
  const AiGlanceCard({required this.title, required this.child, super.key});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) => P2Card(
    color: const Color(0x805E56FF),
    border: false,
    radius: 18,
    padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            SvgPicture.asset(p2GlanceIcon, width: 26, height: 26),
            const SizedBox(width: 6),
            Text(title, style: p2Body.copyWith(color: P2Colors.lavender)),
          ],
        ),
        const SizedBox(height: 10),
        child,
      ],
    ),
  );
}

/// 분석_005-01 소비 습관 진단 결과.
class AiOpinionScreen extends StatelessWidget {
  const AiOpinionScreen({required this.result, super.key, this.quota});

  final Map<String, dynamic> result;
  final Map<String, dynamic>? quota;

  @override
  Widget build(BuildContext context) {
    final content = result['content'] as Map<String, dynamic>? ?? const {};
    final points = (content['improvement_points'] as List? ?? const [])
        .whereType<String>()
        .toList();
    final actions = (content['action_suggestions'] as List? ?? const [])
        .whereType<String>()
        .toList();
    return P2Page(
      title: '소비 습관 진단',
      children: [
        AiResultMeta(result: result),
        const SizedBox(height: 26),
        AiGlanceCard(
          title: '한눈에 보기',
          child: Text(content['summary'] as String? ?? '', style: p2Body),
        ),
        if (points.isNotEmpty) ...[
          const SizedBox(height: 26),
          P2Card(
            padding: const EdgeInsets.fromLTRB(21, 19, 21, 19),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _CardTitle(icon: p2WarnIcon, title: '아쉬운 점'),
                const SizedBox(height: 15),
                for (var i = 0; i < points.length; i++) ...[
                  if (i > 0) const SizedBox(height: 10),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 22,
                        height: 22,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: AppColors.selected,
                          borderRadius: BorderRadius.circular(11),
                        ),
                        child: Text('${i + 1}', style: p2Caption50),
                      ),
                      const SizedBox(width: 10),
                      Expanded(child: Text(points[i], style: p2Body)),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
        if (actions.isNotEmpty) ...[
          const SizedBox(height: 26),
          P2Card(
            padding: const EdgeInsets.fromLTRB(19, 19, 19, 19),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _CardTitle(icon: p2CheckCircleIcon, title: '이렇게 해보세요'),
                const SizedBox(height: 15),
                for (var i = 0; i < actions.length; i++) ...[
                  if (i > 0) const SizedBox(height: 10),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 3),
                        child: SvgPicture.asset(
                          p2CheckIcon,
                          width: 16,
                          height: 16,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(child: Text(actions[i], style: p2Body)),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
        const SizedBox(height: 26),
        const Text('AI가 만든 의견이라 실제와 다를 수 있어요', style: p2Caption50),
        const SizedBox(height: 25),
        AiQuotaFooter(quota: quota),
      ],
    );
  }
}

class _CardTitle extends StatelessWidget {
  const _CardTitle({required this.icon, required this.title});

  final String icon;
  final String title;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      SvgPicture.asset(icon, width: 16, height: 16),
      const SizedBox(width: 6),
      Text(title, style: p2Body.copyWith(color: AppColors.text80)),
    ],
  );
}
