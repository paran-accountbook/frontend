import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../core/constants/app_assets.dart';
import '../../core/theme/app_colors.dart';
import '../../features/category/data/category_models.dart';
import '../../features/category/data/category_service.dart';

/// P2 디자인 공통 색.
abstract final class P2Colors {
  static const lavender = Color(0xFFA8A3FF);
  static const black = Color(0xFF1B1B1B);
  static const danger = Color(0xFFCF376A);
  static const dangerText = Color(0xFFFF7373);
  static const dim = Color(0x80121215);
}

const p2ToastErrorIcon = 'assets/icons/p2_toast_error.svg';
const p2MenuEditIcon = 'assets/icons/p2_menu_edit.svg';
const p2MenuDeleteIcon = 'assets/icons/p2_menu_delete.svg';
const p2CompleteCheckIcon = 'assets/icons/p2_complete_check.svg';
const p2CategoryAddIcon = 'assets/icons/p2_category_add.svg';

OverlayEntry? _currentToast;
Timer? _toastTimer;

/// 화면 위쪽 안내(토스트). 성공은 체크, 실패·제한은 ✕ 아이콘.
void showTopToast(
  BuildContext context,
  String message, {
  bool error = false,
  bool bottom = false,
  Duration duration = const Duration(milliseconds: 2200),
}) {
  final overlay = Overlay.maybeOf(context, rootOverlay: true);
  if (overlay == null) return;
  _toastTimer?.cancel();
  _currentToast?.remove();
  final entry = OverlayEntry(
    builder: (context) => bottom
        ? Positioned(
            left: 0,
            right: 0,
            // 하단 탭 바로 위 (디자인 기준 아래에서 125).
            bottom: 125 * MediaQuery.sizeOf(context).width / 402,
            child: IgnorePointer(
              child: Center(
                child: _TopToast(
                  key: const Key('p2-bottom-toast'),
                  message: message,
                  error: error,
                  margin: EdgeInsets.zero,
                  alignment: Alignment.bottomCenter,
                ),
              ),
            ),
          )
        : Positioned(
            left: 0,
            right: 0,
            top: 0,
            child: IgnorePointer(
              child: SafeArea(
                bottom: false,
                child: Center(
                  child: _TopToast(
                    key: const Key('p2-top-toast'),
                    message: message,
                    error: error,
                  ),
                ),
              ),
            ),
          ),
  );
  _currentToast = entry;
  overlay.insert(entry);
  _toastTimer = Timer(duration, () {
    if (_currentToast == entry) {
      entry.remove();
      _currentToast = null;
    }
  });
}

/// 테스트에서 남은 토스트를 정리할 때 사용.
void dismissTopToast() {
  _toastTimer?.cancel();
  _currentToast?.remove();
  _currentToast = null;
}

class _TopToast extends StatelessWidget {
  const _TopToast({
    required this.message,
    required this.error,
    super.key,
    this.margin = const EdgeInsets.only(top: 24),
    this.alignment = Alignment.topCenter,
  });

  final String message;
  final bool error;
  final EdgeInsets margin;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final scale = MediaQuery.sizeOf(context).width / 402;
      return Transform.scale(
        scale: scale,
        alignment: alignment,
        child: Material(
          type: MaterialType.transparency,
          child: Container(
            width: 354,
            height: 50,
            margin: margin,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: const Color(0xF2272932),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.text10, width: .5),
            ),
            child: Row(
              children: [
                SvgPicture.asset(
                  error ? p2ToastErrorIcon : AppAssets.toastSuccess,
                  width: error ? 22 : 22,
                  height: 22,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    message,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.text,
                      fontFamily: 'Pretendard',
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      height: 22 / 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

/// 화면 전체를 흐리게 덮는 팝업(디자인의 'Frame 222' 배경).
Future<T?> showBlurOverlay<T>(
  BuildContext context, {
  required WidgetBuilder builder,
  String label = '팝업',
  bool dismissible = false,
}) => showGeneralDialog<T>(
  context: context,
  barrierDismissible: dismissible,
  barrierLabel: label,
  barrierColor: Colors.transparent,
  transitionDuration: const Duration(milliseconds: 150),
  transitionBuilder: (context, animation, secondaryAnimation, child) =>
      FadeTransition(opacity: animation, child: child),
  pageBuilder: (dialogContext, animation, secondaryAnimation) => Material(
    color: Colors.transparent,
    child: Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            onTap: dismissible ? () => Navigator.of(dialogContext).pop() : null,
            child: ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                child: const ColoredBox(color: P2Colors.dim),
              ),
            ),
          ),
        ),
        Positioned.fill(child: builder(dialogContext)),
      ],
    ),
  ),
);

/// 402×874 디자인 좌표계를 화면 너비에 맞춰 그린다(팝업 내용용).
class P2DesignFrame extends StatelessWidget {
  const P2DesignFrame({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final scale = constraints.maxWidth / 402;
      final height = constraints.maxHeight / scale;
      return FittedBox(
        fit: BoxFit.fitWidth,
        alignment: Alignment.topCenter,
        child: SizedBox(width: 402, height: height, child: child),
      );
    },
  );
}

/// 하단 버튼(354×56, radius 20). 회색·보라·분홍.
enum P2ButtonTone { grey, main, danger }

class P2Button extends StatelessWidget {
  const P2Button({
    required this.label,
    required this.onPressed,
    super.key,
    this.tone = P2ButtonTone.main,
    this.width = 354,
    this.height = 56,
  });

  final String label;
  final VoidCallback? onPressed;
  final P2ButtonTone tone;
  final double? width;
  final double height;

  @override
  Widget build(BuildContext context) {
    final color = switch (tone) {
      P2ButtonTone.grey => AppColors.selected,
      P2ButtonTone.main => AppColors.main,
      P2ButtonTone.danger => P2Colors.danger,
    };
    final enabled = onPressed != null;
    return SizedBox(
      width: width,
      height: height,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onPressed,
        child: Opacity(
          opacity: enabled ? 1 : .4,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.text20),
            ),
            child: Center(
              child: Text(
                label,
                style: TextStyle(
                  color: tone == P2ButtonTone.grey
                      ? AppColors.text
                      : Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  height: 18 / 15,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 디자인의 34×34 닫기(✕) 아이콘.
class P2CloseIcon extends StatelessWidget {
  const P2CloseIcon({required this.onTap, super.key, this.label});

  final VoidCallback onTap;
  final String? label;

  @override
  Widget build(BuildContext context) => GestureDetector(
    behavior: HitTestBehavior.opaque,
    onTap: onTap,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SvgPicture.asset(AppAssets.ledgerFilterClose, width: 34, height: 34),
        if (label case final text?) ...[
          const SizedBox(height: 20),
          SizedBox(
            height: 17,
            child: Text(
              text,
              style: const TextStyle(
                color: AppColors.text,
                fontSize: 14,
                fontWeight: FontWeight.w500,
                height: 17 / 14,
              ),
            ),
          ),
        ],
      ],
    ),
  );
}

/// 카테고리 아이콘(26 슬롯). 기본 카테고리는 이름으로, 직접 만든 카테고리는 아이콘 식별자로.
class P2CategoryIcon extends StatelessWidget {
  const P2CategoryIcon({
    required this.name,
    required this.kind,
    super.key,
    this.icon,
    this.color,
    this.size = 26,
  });

  final String name;
  final String? icon;
  final CategoryKind kind;

  /// 지정하면 아이콘을 한 색으로 칠함(선택된 수입 칩·팝업의 회색 아이콘).
  final Color? color;
  final double size;

  @override
  Widget build(BuildContext context) {
    final iconId = icon ?? CategoryStore.instance.iconFor(name, kind);
    final custom = CategoryIconSet.find(iconId, kind);
    final filter = color == null
        ? null
        : ColorFilter.mode(color!, BlendMode.srcIn);
    if (custom != null) {
      return SizedBox.square(
        dimension: size,
        child: SvgPicture.asset(
          custom.asset,
          width: size * custom.width / 26,
          height: size,
          fit: BoxFit.contain,
          colorFilter: filter,
        ),
      );
    }
    final (w, h) = kind == CategoryKind.income
        ? (26.0, 26.0)
        : switch (name) {
            '식비' => (14.0, 20.0),
            '카페' || '카페/간식' || '기타' => (26.0, 26.0),
            '쇼핑' || '문화' || '의료' => (18.0, 18.0),
            '교통' => (20.0, 20.0),
            '교육' => (24.0, 16.0),
            _ => (26.0, 26.0),
          };
    final scale = size / 26;
    return SizedBox.square(
      dimension: size,
      child: Center(
        child: SvgPicture.asset(
          kind == CategoryKind.income
              ? AppAssets.incomeIconFor(name)
              : defaultExpenseCategoryNames.contains(name)
              ? AppAssets.categoryIconFor(name)
              : AppAssets.categoryOther,
          width: w * scale,
          height: h * scale,
          colorFilter: filter,
        ),
      ),
    );
  }
}

/// 디자인의 카테고리 '작은 버튼' (109×55).
/// - 지출 선택: 아이콘 색 테두리
/// - 수입 선택: 보라 배경 + 검은 글자/아이콘
/// - muted: 팝업 위쪽에 보여주는 회색 아이콘 칩
class P2CategoryChip extends StatelessWidget {
  const P2CategoryChip({
    required this.category,
    super.key,
    this.selected = false,
    this.muted = false,
    this.highlighted = false,
    this.onTap,
    this.onLongPress,
    this.width,
  });

  final CategoryItem category;
  final bool selected;
  final bool muted;
  final bool highlighted;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final double? width;

  @override
  Widget build(BuildContext context) {
    final income = category.kind == CategoryKind.income;
    final filled = income && selected;
    final borderColor = selected && !income
        ? CategoryIconSet.colorFor(
            name: category.name,
            icon: category.icon,
            kind: category.kind,
          )
        : AppColors.text20;
    return GestureDetector(
      key: Key('category-chip-${category.kind.apiValue}-${category.name}'),
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        // Figma: 지출 칩 109, 수입 칩 112. 내용은 가운데 정렬(긴 이름은 좌우 여백을 줄여 맞춤).
        width: width ?? (income ? 112 : 109),
        height: 55,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: filled ? P2Colors.lavender : AppColors.selected,
          borderRadius: BorderRadius.circular(30.154),
          border: Border.all(
            color: borderColor,
            width: selected && !income ? 1 : .503,
          ),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                P2CategoryIcon(
                  name: category.name,
                  icon: category.icon,
                  kind: category.kind,
                  size: income ? 27 : 26,
                  color: filled
                      ? P2Colors.black
                      : muted || highlighted || income
                      ? AppColors.text50
                      : null,
                ),
                const SizedBox(width: 6),
                Text(
                  category.name,
                  maxLines: 1,
                  softWrap: false,
                  style: TextStyle(
                    color: filled
                        ? P2Colors.black
                        : income && !highlighted
                        ? AppColors.text50
                        : AppColors.text,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    height: 18 / 15,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 점선 테두리의 [+ 추가] 칩.
class P2AddCategoryChip extends StatelessWidget {
  const P2AddCategoryChip({required this.onTap, super.key});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    key: const Key('category-add-chip'),
    behavior: HitTestBehavior.opaque,
    onTap: onTap,
    child: CustomPaint(
      painter: const _DashedRRectPainter(
        color: P2Colors.lavender,
        radius: 30.154,
      ),
      child: Container(
        width: 109,
        height: 55,
        padding: const EdgeInsets.only(left: 24, right: 26),
        child: Row(
          children: [
            SvgPicture.asset(p2CategoryAddIcon, width: 26, height: 26),
            const SizedBox(width: 6),
            const Text(
              '추가',
              style: TextStyle(
                color: P2Colors.lavender,
                fontSize: 15,
                fontWeight: FontWeight.w600,
                height: 18 / 15,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _DashedRRectPainter extends CustomPainter {
  const _DashedRRectPainter({required this.color, required this.radius});

  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = .7;
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(radius)),
      );
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        canvas.drawPath(metric.extractPath(distance, distance + 4), paint);
        distance += 7;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedRRectPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.radius != radius;
}

/// 결제수단·기간 등 텍스트만 있는 작은 버튼(높이 47).
class P2TextChip extends StatelessWidget {
  const P2TextChip({
    required this.label,
    required this.selected,
    required this.onTap,
    super.key,
    this.width,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final double? width;

  @override
  Widget build(BuildContext context) => GestureDetector(
    behavior: HitTestBehavior.opaque,
    onTap: onTap,
    child: Container(
      width: width,
      height: 47,
      padding: width == null
          ? const EdgeInsets.symmetric(horizontal: 26)
          : EdgeInsets.zero,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: selected ? P2Colors.lavender : AppColors.selected,
        borderRadius: BorderRadius.circular(30.154),
        border: Border.all(color: AppColors.text20, width: .503),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: selected ? P2Colors.black : AppColors.text50,
          fontSize: 15,
          fontWeight: FontWeight.w600,
          height: 18 / 15,
        ),
      ),
    ),
  );
}

/// 가운데 카드형 확인 팝업 (회원 탈퇴 재확인 팝업 마이_005-04와 같은 모양).
/// 카드(354) 아래에 [취소] [확인] 버튼이 20 간격으로 놓인다.
class P2CenterConfirmCard extends StatelessWidget {
  const P2CenterConfirmCard({
    required this.title,
    required this.description,
    required this.note,
    required this.confirmLabel,
    required this.onCancel,
    required this.onConfirm,
    super.key,
    this.noteColor = P2Colors.danger,
    this.noteSize = 14,
    this.confirmColor = P2Colors.danger,
    this.compact = false,
  });

  /// 마이_002-02 무지출 기록 팝업처럼 간격이 좁고 구분선이 안쪽으로 들어간 모양.
  final bool compact;
  final String title;
  final String description;
  final String note;
  final Color noteColor;
  final double noteSize;
  final String confirmLabel;
  final Color confirmColor;
  final VoidCallback onCancel;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 354,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 354,
          padding: compact
              ? const EdgeInsets.only(top: 32, bottom: 28)
              : const EdgeInsets.symmetric(vertical: 33),
          decoration: BoxDecoration(
            color: AppColors.secondary,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.text,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    height: 18 / 15,
                  ),
                ),
              ),
              SizedBox(height: compact ? 8 : 18),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  description,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: compact ? AppColors.text80 : AppColors.text50,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    height: 21 / 12,
                  ),
                ),
              ),
              SizedBox(height: compact ? 16 : 18),
              ColoredBox(
                color: const Color(0x14E2E2F9),
                child: SizedBox(width: compact ? 306 : 354, height: 1),
              ),
              SizedBox(height: compact ? 16 : 18),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  note,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: noteColor,
                    fontSize: noteSize,
                    fontWeight: FontWeight.w500,
                    height: (noteSize >= 14 ? 22 : 21) / noteSize,
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
              key: const Key('center-confirm-cancel'),
              label: '취소',
              tone: P2ButtonTone.grey,
              width: 167,
              onPressed: onCancel,
            ),
            const SizedBox(width: 20),
            P2Button(
              key: const Key('center-confirm-ok'),
              label: confirmLabel,
              tone: confirmColor == AppColors.main
                  ? P2ButtonTone.main
                  : P2ButtonTone.danger,
              width: 167,
              onPressed: onConfirm,
            ),
          ],
        ),
      ],
    ),
  );
}

/// 가운데 카드형 확인 팝업을 띄운다. 확인을 누르면 true.
Future<bool> showCenterConfirm(
  BuildContext context, {
  required String title,
  required String description,
  required String note,
  required String confirmLabel,
  Color noteColor = P2Colors.danger,
  double noteSize = 14,
  Color confirmColor = P2Colors.danger,
  String label = '확인 팝업',
  bool compact = false,
}) async {
  final result = await showBlurOverlay<bool>(
    context,
    label: label,
    builder: (dialogContext) => P2DesignFrame(
      child: Center(
        child: P2CenterConfirmCard(
          title: title,
          description: description,
          note: note,
          noteColor: noteColor,
          noteSize: noteSize,
          confirmLabel: confirmLabel,
          confirmColor: confirmColor,
          compact: compact,
          onCancel: () => Navigator.of(dialogContext).pop(false),
          onConfirm: () => Navigator.of(dialogContext).pop(true),
        ),
      ),
    ),
  );
  return result ?? false;
}

/// 등록_010-01·등록_009-01: '소비사진 첨부 (선택)' 회색 버튼(354×56).
class P2PhotoAttachButton extends StatelessWidget {
  const P2PhotoAttachButton({
    required this.count,
    required this.onTap,
    super.key,
  });

  final int count;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    key: const Key('expense-photo-attach'),
    behavior: HitTestBehavior.opaque,
    onTap: onTap,
    child: Container(
      width: double.infinity,
      height: 56,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.selected,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.text20),
      ),
      child: Text.rich(
        TextSpan(
          text: count == 0 ? '소비사진 첨부 ' : '소비사진 $count장 첨부됨 ',
          children: const [
            TextSpan(
              text: '(선택)',
              style: TextStyle(color: P2Colors.lavender),
            ),
          ],
        ),
        style: const TextStyle(
          color: AppColors.text,
          fontSize: 15,
          fontWeight: FontWeight.w600,
          height: 18 / 15,
        ),
      ),
    ),
  );
}

/// '* * * *' 꾸밈 구분선 (354×7).
class P2AsteriskDivider extends StatelessWidget {
  const P2AsteriskDivider({super.key, this.width = 354});

  final double width;

  @override
  Widget build(BuildContext context) => SvgPicture.asset(
    AppAssets.asteriskDividerDark,
    width: width,
    height: 7,
    fit: BoxFit.fill,
  );
}

/// 상단 뒤로가기 + 27px 제목이 있는 P2 페이지 틀 (내용은 세로 스크롤).
/// 내용은 y=191(제목 아래 25)부터 시작한다.
class P2Page extends StatelessWidget {
  const P2Page({
    required this.title,
    required this.children,
    super.key,
    this.onBack,
    this.bottom,
    this.bottomHeight = 0,
    this.scrollKey,
    this.background = AppColors.background,
    this.overlay,
  });

  final String title;
  final List<Widget> children;
  final VoidCallback? onBack;
  final Widget? bottom;
  final double bottomHeight;
  final Key? scrollKey;
  final Color background;
  final Widget? overlay;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: background,
    body: P2DesignFrame(
      child: Stack(
        children: [
          Positioned.fill(child: ColoredBox(color: background)),
          Positioned.fill(
            child: SingleChildScrollView(
              key: scrollKey,
              padding: EdgeInsets.fromLTRB(24, 50, 24, 40 + bottomHeight),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  P2BackButton(onTap: onBack),
                  const SizedBox(height: 41),
                  Text(
                    title,
                    style: const TextStyle(
                      color: AppColors.text,
                      fontSize: 27,
                      fontWeight: FontWeight.w700,
                      height: 32 / 27,
                    ),
                  ),
                  const SizedBox(height: 34),
                  ...children,
                ],
              ),
            ),
          ),
          if (bottom case final widget?)
            Positioned(left: 0, right: 0, bottom: 0, child: widget),
          ?overlay,
        ],
      ),
    ),
  );
}

class P2BackButton extends StatelessWidget {
  const P2BackButton({super.key, this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    key: const Key('p2-back'),
    behavior: HitTestBehavior.opaque,
    onTap: onTap ?? () => Navigator.of(context).maybePop(),
    child: Semantics(
      button: true,
      label: '뒤로가기',
      child: SvgPicture.asset(AppAssets.arrowBackLight, width: 34, height: 34),
    ),
  );
}

/// 작은 알약 배지 (예: '이번 달 1회', '지난달(10월) 기준').
class P2Badge extends StatelessWidget {
  const P2Badge(this.label, {super.key, this.tone = P2BadgeTone.accent});

  final String label;
  final P2BadgeTone tone;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (tone) {
      P2BadgeTone.accent => (const Color(0x805E56FF), P2Colors.lavender),
      P2BadgeTone.muted => (AppColors.selected, AppColors.text50),
      P2BadgeTone.solid => (P2Colors.lavender, P2Colors.black),
      P2BadgeTone.grey => (AppColors.selected, P2Colors.lavender),
    };
    return Container(
      height: 23,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(21),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: fg,
          fontSize: 12,
          fontWeight: FontWeight.w500,
          height: 21 / 12,
        ),
      ),
    );
  }
}

enum P2BadgeTone { accent, muted, solid, grey }

/// 회색 카드(#191A1F, 테두리 10%, radius 20).
class P2Card extends StatelessWidget {
  const P2Card({
    required this.child,
    super.key,
    this.padding = const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
    this.color = AppColors.secondary,
    this.border = true,
    this.radius = 20,
    this.gradient,
  });

  final Widget child;
  final EdgeInsets padding;
  final Color color;
  final bool border;
  final double radius;
  final Gradient? gradient;

  @override
  Widget build(BuildContext context) => Container(
    width: 354,
    // Figma 는 테두리를 안쪽에 그리므로 테두리 두께만큼 여백을 줄여 위치를 맞춘다.
    padding: border
        ? EdgeInsets.fromLTRB(
            (padding.left - 1).clamp(0, double.infinity),
            (padding.top - 1).clamp(0, double.infinity),
            (padding.right - 1).clamp(0, double.infinity),
            (padding.bottom - 1).clamp(0, double.infinity),
          )
        : padding,
    decoration: BoxDecoration(
      color: gradient == null ? color : null,
      gradient: gradient,
      borderRadius: BorderRadius.circular(radius),
      border: border ? Border.all(color: AppColors.text10) : null,
    ),
    child: child,
  );
}

/// 섹션 제목(20) + 설명(12).
class P2SectionHeader extends StatelessWidget {
  const P2SectionHeader({required this.title, super.key, this.subtitle});

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w500,
          height: 24 / 20,
        ),
      ),
      if (subtitle case final text?) ...[
        const SizedBox(height: 10),
        Text(text, style: p2Caption80),
      ],
    ],
  );
}

const p2Caption80 = TextStyle(
  color: AppColors.text80,
  fontSize: 12,
  fontWeight: FontWeight.w500,
  height: 21 / 12,
);
const p2Caption50 = TextStyle(
  color: AppColors.text50,
  fontSize: 12,
  fontWeight: FontWeight.w500,
  height: 21 / 12,
);
const p2Body = TextStyle(
  color: AppColors.text,
  fontSize: 14,
  fontWeight: FontWeight.w500,
  height: 22 / 14,
);

/// 금액 표기(Amarante) + ₩ 아이콘.
class P2Amount extends StatelessWidget {
  const P2Amount(
    this.amount, {
    super.key,
    this.size = 20,
    this.color = AppColors.text,
  });

  final int amount;
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(
        formatWon(amount),
        style: TextStyle(
          color: color,
          fontFamily: 'Amarante',
          fontSize: size,
          height: 1.2,
        ),
      ),
      SizedBox(width: size >= 30 ? 6 : 4),
      SvgPicture.asset(
        AppAssets.wonLight,
        width: size >= 30 ? 22 : 14,
        height: size >= 30 ? 23 : 15,
        colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
      ),
    ],
  );
}

String formatWon(int amount) {
  final negative = amount < 0;
  final digits = amount.abs().toString();
  final buffer = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buffer.write(',');
    buffer.write(digits[i]);
  }
  return '${negative ? '-' : ''}$buffer';
}

/// 'YYYY-MM-DD' → '12월 1일'
String monthDayLabel(String? date) {
  final value = DateTime.tryParse(date ?? '');
  return value == null ? '' : '${value.month}월 ${value.day}일';
}

/// 'YYYY-MM' → 10
int? monthOf(String? yearMonth) {
  final parts = (yearMonth ?? '').split('-');
  return parts.length >= 2 ? int.tryParse(parts[1]) : null;
}
