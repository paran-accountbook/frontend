import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/auth_widgets.dart';
import '../../../shared/widgets/p2_widgets.dart';
import '../data/category_models.dart';
import '../data/category_service.dart';

/// 등록_013-01·02: 카테고리 추가/수정 창. 저장되면 저장된 카테고리를 돌려준다.
Future<CategoryItem?> showCategoryEditor(
  BuildContext context, {
  required CategoryKind kind,
  required CategoryService service,
  CategoryItem? existing,
}) => showBlurOverlay<CategoryItem>(
  context,
  label: existing == null ? '카테고리 추가' : '카테고리 수정',
  builder: (dialogContext) => P2DesignFrame(
    child: _CategoryEditor(kind: kind, service: service, existing: existing),
  ),
);

class _CategoryEditor extends StatefulWidget {
  const _CategoryEditor({
    required this.kind,
    required this.service,
    this.existing,
  });

  final CategoryKind kind;
  final CategoryService service;
  final CategoryItem? existing;

  @override
  State<_CategoryEditor> createState() => _CategoryEditorState();
}

class _CategoryEditorState extends State<_CategoryEditor> {
  late final _name = TextEditingController(text: widget.existing?.name ?? '');
  late String? _icon = widget.existing?.icon;
  bool _saving = false;

  bool get _editing => widget.existing != null;
  bool get _canSave => _name.text.trim().isNotEmpty && _icon != null;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_canSave || _saving) return;
    final name = _name.text.trim();
    setState(() => _saving = true);
    try {
      final saved = _editing
          ? await widget.service.updateCategory(
              widget.existing!,
              name: name,
              icon: _icon!,
            )
          : await widget.service.createCategory(
              name: name,
              icon: _icon!,
              kind: widget.kind,
            );
      if (mounted) Navigator.of(context).pop(saved);
    } on ApiException catch (error) {
      if (!mounted) return;
      showTopToast(
        context,
        error.code == 'E512'
            ? '이미 있는 카테고리 이름이에요'
            : error.code == 'E513'
            ? '${widget.kind.label} 카테고리는 최대 ${widget.kind.maxCount}개까지 만들 수 있어요'
            : error.message,
        error: true,
      );
    } catch (_) {
      if (mounted) {
        showTopToast(context, '저장하지 못했어요. 다시 시도해 주세요', error: true);
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final icons = CategoryIconSet.of(widget.kind);
    final top = _editing ? 265.0 : 279.0;
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () => FocusScope.of(context).unfocus(),
      child: Stack(
        children: [
          Positioned(
            left: 0,
            right: 0,
            top: top + 25,
            child: Center(
              child: P2CloseIcon(
                onTap: () => Navigator.of(context).pop(),
                label: '${widget.kind.label} 카테고리 ${_editing ? '수정' : '추가'}',
              ),
            ),
          ),
          Positioned(
            left: 25,
            top: top + 127,
            child: AuthTextField(
              key: const Key('category-name-field'),
              controller: _name,
              hintText: '최대 4자',
              inputFormatters: [LengthLimitingTextInputFormatter(4)],
              onChanged: (_) => setState(() {}),
            ),
          ),
          Positioned(
            left: 24,
            right: 24,
            top: top + 209,
            child: const Text(
              '아이콘 선택',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.text80,
                fontSize: 12,
                fontWeight: FontWeight.w500,
                height: 21 / 12,
              ),
            ),
          ),
          Positioned(
            left: 24,
            top: top + 256,
            width: 354,
            child: _IconGrid(
              icons: icons,
              selected: _icon,
              onSelected: (id) => setState(() => _icon = id),
            ),
          ),
          Positioned(
            left: 24,
            bottom: 117,
            child: P2Button(
              key: const Key('category-editor-cancel'),
              label: '취소',
              tone: P2ButtonTone.grey,
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          Positioned(
            left: 24,
            bottom: 41,
            child: P2Button(
              key: const Key('category-editor-save'),
              label: _editing ? '저장' : '추가하기',
              onPressed: _canSave && !_saving ? _save : null,
            ),
          ),
        ],
      ),
    );
  }
}

class _IconGrid extends StatelessWidget {
  const _IconGrid({
    required this.icons,
    required this.selected,
    required this.onSelected,
  });

  final List<CategoryIconSpec> icons;
  final String? selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final rows = <List<CategoryIconSpec>>[
      for (var i = 0; i < icons.length; i += 6)
        icons.sublist(i, i + 6 > icons.length ? icons.length : i + 6),
    ];
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var r = 0; r < rows.length; r++) ...[
          if (r > 0) const SizedBox(height: 20),
          SizedBox(
            width: 354,
            height: rows[r].any((spec) => spec.id == selected) ? 40 : 26,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                for (var c = 0; c < rows[r].length; c++)
                  _iconCell(rows[r][c], 22.833 + 61.667 * c),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _iconCell(CategoryIconSpec spec, double center) {
    final isSelected = spec.id == selected;
    final size = isSelected ? 40.0 : 26.0;
    return Positioned(
      left: center - size / 2,
      top: 0,
      bottom: 0,
      child: GestureDetector(
        key: Key('category-icon-${spec.id}'),
        behavior: HitTestBehavior.opaque,
        onTap: () => onSelected(spec.id),
        child: Center(
          child: Container(
            width: size,
            height: size,
            alignment: Alignment.center,
            decoration: isSelected
                ? BoxDecoration(
                    color: spec.color,
                    borderRadius: BorderRadius.circular(11),
                  )
                : null,
            child: SvgPicture.asset(
              spec.asset,
              width: spec.width,
              height: 26,
              colorFilter: isSelected
                  ? const ColorFilter.mode(P2Colors.black, BlendMode.srcIn)
                  : null,
            ),
          ),
        ),
      ),
    );
  }
}

/// 팝업 위쪽에 보여주는 카테고리 칩(가운데 정렬).
class _HeaderChip extends StatelessWidget {
  const _HeaderChip(this.category);

  final CategoryItem category;

  @override
  Widget build(BuildContext context) =>
      Center(child: P2CategoryChip(category: category, muted: true));
}

class _PopupText extends StatelessWidget {
  const _PopupText(this.text, {this.size = 14, this.color = AppColors.text});

  final String text;
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) => Text(
    text,
    textAlign: TextAlign.center,
    style: TextStyle(
      color: color,
      fontSize: size,
      fontWeight: size >= 14 ? FontWeight.w500 : FontWeight.w400,
      height: (size >= 14 ? 22 : 21) / size,
    ),
  );
}

/// 하단 버튼형 팝업 공통 틀 (등록_013-04~09).
class _BottomButtonPopup extends StatelessWidget {
  const _BottomButtonPopup({
    required this.content,
    required this.contentTop,
    required this.primaryLabel,
    required this.onPrimary,
    this.primaryTone = P2ButtonTone.danger,
    this.secondaryLabel,
    this.onSecondary,
    this.primaryKey,
    this.secondaryKey,
  });

  final Widget content;
  final double contentTop;
  final String primaryLabel;
  final VoidCallback? onPrimary;
  final P2ButtonTone primaryTone;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;
  final Key? primaryKey;
  final Key? secondaryKey;

  @override
  Widget build(BuildContext context) => P2DesignFrame(
    child: Stack(
      children: [
        Positioned(left: 0, right: 0, top: contentTop, child: content),
        if (secondaryLabel case final label?)
          Positioned(
            left: 24,
            bottom: 117,
            child: P2Button(
              key: secondaryKey,
              label: label,
              tone: P2ButtonTone.grey,
              onPressed: onSecondary,
            ),
          ),
        Positioned(
          left: 24,
          bottom: 41,
          child: P2Button(
            key: primaryKey,
            label: primaryLabel,
            tone: primaryTone,
            onPressed: onPrimary,
          ),
        ),
      ],
    ),
  );
}

/// 등록_013-03 [카테고리 삭제] 이후 흐름.
/// 삭제했으면 true 를 돌려준다(필터 시트가 목록을 다시 불러옴).
Future<bool> runCategoryDeleteFlow(
  BuildContext context, {
  required CategoryItem category,
  required CategoryService service,
  required List<CategoryItem> sameKindCategories,
}) async {
  if (category.recordCount <= 0) {
    final confirmed = await _showDeleteConfirm(context, category);
    if (confirmed != true || !context.mounted) return false;
    final ok = await _delete(context, service, category);
    if (!ok || !context.mounted) return ok;
    await _showDeleteDone(context, category);
    return true;
  }
  final choice = await _showDeleteWithRecords(context, category);
  if (!context.mounted || choice == null) return false;
  if (choice == _RecordsChoice.deleteAll) {
    final confirmed = await _showDeleteAllConfirm(context, category);
    if (confirmed != true || !context.mounted) return false;
    final ok = await _delete(context, service, category);
    if (!ok || !context.mounted) return ok;
    await _showDeleteDone(context, category);
    return true;
  }
  final target = await _showMoveSelect(
    context,
    category,
    sameKindCategories.where((item) => item.name != category.name).toList(),
  );
  if (target == null || !context.mounted) return false;
  final ok = await _delete(context, service, category, moveTo: target);
  if (!ok || !context.mounted) return ok;
  await _showMoveDone(context, category, target);
  return true;
}

Future<bool> _delete(
  BuildContext context,
  CategoryService service,
  CategoryItem category, {
  CategoryItem? moveTo,
}) async {
  try {
    await service.deleteCategory(category, moveTo: moveTo?.name);
    return true;
  } on ApiException catch (error) {
    if (context.mounted) showTopToast(context, error.message, error: true);
  } catch (_) {
    if (context.mounted) {
      showTopToast(context, '삭제하지 못했어요. 다시 시도해 주세요', error: true);
    }
  }
  return false;
}

Future<bool?> _showDeleteConfirm(BuildContext context, CategoryItem category) =>
    showBlurOverlay<bool>(
      context,
      label: '카테고리 삭제 확인',
      builder: (dialogContext) => _BottomButtonPopup(
        contentTop: 389,
        content: Column(
          children: [
            _HeaderChip(category),
            const SizedBox(height: 20),
            _PopupText('카테고리 ‘${category.name}’를 삭제 하시겠습니까?'),
          ],
        ),
        secondaryLabel: '취소',
        secondaryKey: const Key('category-delete-cancel'),
        onSecondary: () => Navigator.of(dialogContext).pop(false),
        primaryLabel: '삭제하기',
        primaryKey: const Key('category-delete-confirm'),
        onPrimary: () => Navigator.of(dialogContext).pop(true),
      ),
    );

enum _RecordsChoice { deleteAll, move }

Future<_RecordsChoice?> _showDeleteWithRecords(
  BuildContext context,
  CategoryItem category,
) => showBlurOverlay<_RecordsChoice>(
  context,
  label: '함께 삭제 안내',
  builder: (dialogContext) => _BottomButtonPopup(
    contentTop: 323,
    content: Column(
      children: [
        P2CloseIcon(
          key: const Key('category-records-close'),
          label: '닫기',
          onTap: () => Navigator.of(dialogContext).pop(),
        ),
        const SizedBox(height: 20),
        _HeaderChip(category),
        const SizedBox(height: 20),
        _PopupText('이 카테고리로 등록된 내역 ${category.recordCount}건이 존재합니다.'),
        const SizedBox(height: 20),
        const _PopupText('내역도 함께 삭제하시겠습니까?', size: 12, color: AppColors.text80),
      ],
    ),
    secondaryLabel: '다른 카테고리로 이동',
    secondaryKey: const Key('category-records-move'),
    onSecondary: () => Navigator.of(dialogContext).pop(_RecordsChoice.move),
    primaryLabel: '전체삭제',
    primaryKey: const Key('category-records-delete-all'),
    onPrimary: () => Navigator.of(dialogContext).pop(_RecordsChoice.deleteAll),
  ),
);

Future<bool?> _showDeleteAllConfirm(
  BuildContext context,
  CategoryItem category,
) => showBlurOverlay<bool>(
  context,
  label: '전체삭제 확인',
  builder: (dialogContext) => _BottomButtonPopup(
    contentTop: 348,
    content: Column(
      children: [
        _HeaderChip(category),
        const SizedBox(height: 20),
        const _PopupText('해당 카테고리로 입력한 내역 전체가 삭제됩니다'),
        const SizedBox(height: 20),
        const _PopupText('삭제하시겠습니까?', size: 12, color: AppColors.text80),
        const SizedBox(height: 20),
        const _PopupText(
          '더치페이 정산 기록도 함께 삭제돼요',
          size: 12,
          color: AppColors.text50,
        ),
      ],
    ),
    secondaryLabel: '취소',
    secondaryKey: const Key('category-delete-all-cancel'),
    onSecondary: () => Navigator.of(dialogContext).pop(false),
    primaryLabel: '삭제하기',
    primaryKey: const Key('category-delete-all-confirm'),
    onPrimary: () => Navigator.of(dialogContext).pop(true),
  ),
);

Future<void> _showDeleteDone(BuildContext context, CategoryItem category) =>
    showBlurOverlay<void>(
      context,
      label: '삭제 완료',
      builder: (dialogContext) => _BottomButtonPopup(
        contentTop: 398,
        content: Column(
          children: [
            const _CompleteIcon(),
            const SizedBox(height: 20),
            _PopupText('‘${category.name}’가 삭제 되었습니다'),
          ],
        ),
        primaryLabel: '확인',
        primaryTone: P2ButtonTone.main,
        primaryKey: const Key('category-delete-done'),
        onPrimary: () => Navigator.of(dialogContext).pop(),
      ),
    );

class _CompleteIcon extends StatelessWidget {
  const _CompleteIcon();

  @override
  Widget build(BuildContext context) =>
      SvgPicture.asset(p2CompleteCheckIcon, width: 36, height: 36);
}

Future<CategoryItem?> _showMoveSelect(
  BuildContext context,
  CategoryItem source,
  List<CategoryItem> targets,
) => showBlurOverlay<CategoryItem>(
  context,
  label: '이동할 카테고리 선택',
  builder: (dialogContext) =>
      _MoveSelectPopup(source: source, targets: targets),
);

class _MoveSelectPopup extends StatefulWidget {
  const _MoveSelectPopup({required this.source, required this.targets});

  final CategoryItem source;
  final List<CategoryItem> targets;

  @override
  State<_MoveSelectPopup> createState() => _MoveSelectPopupState();
}

class _MoveSelectPopupState extends State<_MoveSelectPopup> {
  CategoryItem? _selected;

  @override
  Widget build(BuildContext context) {
    final rows = (widget.targets.length / 3).ceil();
    final gridHeight = rows * 55.0 + (rows - 1).clamp(0, 99) * 8;
    // 목록이 길면 위로 늘어나고, 버튼(677) 위에서 끝나도록 한다.
    final top = (677 - 25 - (25 + 55 + 26 + 17 + 26 + gridHeight)).clamp(
      40.0,
      322.0,
    );
    return _BottomButtonPopup(
      contentTop: top + 25,
      content: Column(
        children: [
          _HeaderChip(widget.source),
          const SizedBox(height: 26),
          const SizedBox(height: 17, child: _PopupText('이동할 카테고리 선택')),
          const SizedBox(height: 26),
          SizedBox(
            width: 343,
            height: (gridHeight).clamp(0, 677 - 25 - top - 149).toDouble(),
            child: SingleChildScrollView(
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final item in widget.targets)
                    P2CategoryChip(
                      category: item,
                      selected: _selected?.name == item.name,
                      onTap: () => setState(() => _selected = item),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
      secondaryLabel: '취소',
      secondaryKey: const Key('category-move-cancel'),
      onSecondary: () => Navigator.of(context).pop(),
      primaryLabel: '이 카테고리로 이동하기',
      primaryTone: P2ButtonTone.main,
      primaryKey: const Key('category-move-confirm'),
      onPrimary: _selected == null
          ? null
          : () => Navigator.of(context).pop(_selected),
    );
  }
}

Future<void> _showMoveDone(
  BuildContext context,
  CategoryItem source,
  CategoryItem target,
) => showBlurOverlay<void>(
  context,
  label: '이동 완료',
  builder: (dialogContext) => _BottomButtonPopup(
    contentTop: 381.5,
    content: Column(
      children: [
        const _CompleteIcon(),
        const SizedBox(height: 20),
        _PopupText('‘${source.name}’가 ’${target.name}’로 이동되었습니다'),
        const SizedBox(height: 20),
        _PopupText(
          '내역 ${source.recordCount}건은 ‘${target.name}’로 옮기고, ‘${source.name}’는 삭제했어요',
          size: 12,
          color: AppColors.text80,
        ),
      ],
    ),
    primaryLabel: '확인',
    primaryTone: P2ButtonTone.main,
    primaryKey: const Key('category-move-done'),
    onPrimary: () => Navigator.of(dialogContext).pop(),
  ),
);
