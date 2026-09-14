import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/auth_widgets.dart';
import '../../../shared/widgets/design_canvas.dart';

class TermsDocument {
  const TermsDocument({required this.title, required this.sections});

  final String title;
  final List<(String, String)> sections;
}

const serviceTermsDocument = TermsDocument(
  title: '서비스 이용 약관',
  sections: [('제 1조', '안녕하세요\n감사합니다'), ('제 2조', '안녕하세요')],
);
const privacyTermsDocument = TermsDocument(
  title: '개인정보 수집·이용 동의',
  sections: [('제 1조', '안녕하세요\n감사합니다'), ('제 2조', '안녕하세요')],
);
const marketingTermsDocument = TermsDocument(
  title: '마케팅 수신 동의',
  sections: [('제 1조', '안녕하세요\n감사합니다'), ('제 2조', '안녕하세요')],
);

const termsDocuments = [
  serviceTermsDocument,
  privacyTermsDocument,
  marketingTermsDocument,
];

class TermsDetailScreen extends StatelessWidget {
  const TermsDetailScreen({required this.document, super.key});

  final TermsDocument document;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DesignCanvas(
        width: 402,
        height: 874,
        child: ColoredBox(
          color: AppColors.background,
          child: Stack(
            children: [
              Positioned(
                left: 24,
                top: 50,
                width: 34,
                height: 34,
                child: IconButton(
                  padding: EdgeInsets.zero,
                  tooltip: '뒤로가기',
                  onPressed: () => Navigator.of(context).maybePop(),
                  icon: SvgPicture.asset(AppAssets.arrowBackLight),
                ),
              ),
              Positioned(
                left: 24,
                top: 129,
                child: Text(
                  document.title,
                  key: const ValueKey('terms-detail-title'),
                  style: const TextStyle(
                    color: AppColors.text,
                    fontSize: 27,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Positioned(
                left: 24,
                top: 192,
                width: 354,
                height: 555,
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      for (
                        var index = 0;
                        index < document.sections.length;
                        index++
                      ) ...[
                        _TermsSection(section: document.sections[index]),
                        if (index < document.sections.length - 1)
                          const SizedBox(height: 20),
                      ],
                    ],
                  ),
                ),
              ),
              AuthBottomAction(
                label: '확인',
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TermsSection extends StatelessWidget {
  const _TermsSection({required this.section});

  final (String, String) section;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 354,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 25),
      decoration: BoxDecoration(
        color: AppColors.secondary,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            section.$1,
            style: const TextStyle(
              color: AppColors.text,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 9),
          Text(
            section.$2,
            style: TextStyle(
              color: AppColors.text80,
              fontSize: 12,
              height: 1.25,
            ),
          ),
        ],
      ),
    );
  }
}
