import 'package:flutter/material.dart';

import '../../../core/constants/app_assets.dart';

/// 등록_013: 카테고리 종류 (지출/수입).
enum CategoryKind {
  expense('expense', '지출'),
  income('income', '수입');

  const CategoryKind(this.apiValue, this.label);
  final String apiValue;
  final String label;

  /// 가계_002: 지출 카테고리 15개, 수입 카테고리 10개(기본 포함)까지 만들 수 있음.
  int get maxCount => this == CategoryKind.expense ? 15 : 10;
}

/// GET /categories 의 한 항목.
@immutable
class CategoryItem {
  const CategoryItem({
    required this.name,
    required this.kind,
    this.id,
    this.icon,
    this.isDefault = false,
    this.recordCount = 0,
  });

  factory CategoryItem.fromJson(Map<String, dynamic> json) => CategoryItem(
    id: json['id'] as String?,
    name: json['name'] as String? ?? '',
    icon: json['icon'] as String?,
    isDefault: json['is_default'] as bool? ?? json['id'] == null,
    kind: json['type'] == 'income' ? CategoryKind.income : CategoryKind.expense,
    recordCount:
        json['record_count'] as int? ?? json['expense_count'] as int? ?? 0,
  );

  final String? id;
  final String name;
  final String? icon;
  final bool isDefault;
  final CategoryKind kind;
  final int recordCount;

  CategoryItem copyWith({String? name, String? icon, int? recordCount}) =>
      CategoryItem(
        id: id,
        name: name ?? this.name,
        icon: icon ?? this.icon,
        isDefault: isDefault,
        kind: kind,
        recordCount: recordCount ?? this.recordCount,
      );

  @override
  bool operator ==(Object other) =>
      other is CategoryItem &&
      other.id == id &&
      other.name == name &&
      other.kind == kind;

  @override
  int get hashCode => Object.hash(id, name, kind);
}

/// 기본 카테고리 목록 (서버 응답이 없을 때의 표시용 기본값).
const defaultExpenseCategoryNames = [
  '식비',
  '카페',
  '쇼핑',
  '의료',
  '문화',
  '교통',
  '교육',
  '기타',
];
const defaultIncomeCategoryNames = ['급여', '용돈', '부수입', '환급·환불', '기타'];

List<CategoryItem> defaultCategories(CategoryKind kind) => [
  for (final name
      in kind == CategoryKind.expense
          ? defaultExpenseCategoryNames
          : defaultIncomeCategoryNames)
    CategoryItem(name: name, kind: kind, isDefault: true),
];

/// 등록_013-01: 직접 만드는 카테고리용 아이콘 세트 (지출 16개 · 수입 15개).
@immutable
class CategoryIconSpec {
  const CategoryIconSpec(this.id, this.asset, this.color, {this.width = 26});
  final String id;
  final String asset;
  final Color color;
  final double width;
}

abstract final class CategoryIconSet {
  static const _root = 'assets/icons/category_set';
  static const _incomeColor = Color(0xFFA9A4FF);

  static const expense = <CategoryIconSpec>[
    CategoryIconSpec('food', '$_root/expense_food.svg', Color(0xFFFA9441)),
    CategoryIconSpec(
      'medical',
      '$_root/expense_medical.svg',
      Color(0xFFE74646),
    ),
    CategoryIconSpec('cafe', '$_root/expense_cafe.svg', Color(0xFFC1B4B4)),
    CategoryIconSpec(
      'shopping',
      '$_root/expense_shopping.svg',
      Color(0xFFD841B8),
    ),
    CategoryIconSpec(
      'transport',
      '$_root/expense_transport.svg',
      Color(0xFF4C64FF),
    ),
    CategoryIconSpec(
      'culture',
      '$_root/expense_culture.svg',
      Color(0xFFA8D886),
    ),
    CategoryIconSpec('send', '$_root/expense_send.svg', Color(0xFF5E56FF)),
    CategoryIconSpec(
      'education',
      '$_root/expense_education.svg',
      Color(0xFFA8A3FF),
    ),
    CategoryIconSpec('pencil', '$_root/expense_pencil.svg', Color(0xFF6B9EF5)),
    CategoryIconSpec('camera', '$_root/expense_camera.svg', Color(0xFF3FB597)),
    CategoryIconSpec('photo', '$_root/expense_photo.svg', Color(0xFFA756EE)),
    CategoryIconSpec('bell', '$_root/expense_bell.svg', Color(0xFFE7D05A)),
    CategoryIconSpec(
      'bookmark',
      '$_root/expense_bookmark.svg',
      Color(0xFFC67848),
    ),
    CategoryIconSpec('fire', '$_root/expense_fire.svg', Color(0xFFE63567)),
    CategoryIconSpec('person', '$_root/expense_person.svg', Color(0xFF46ACFF)),
    CategoryIconSpec('piggy', '$_root/expense_piggy.svg', Color(0xFFFAD162)),
  ];

  static const income = <CategoryIconSpec>[
    CategoryIconSpec(
      'store',
      '$_root/income_store.svg',
      _incomeColor,
      width: 27,
    ),
    CategoryIconSpec('cash', '$_root/income_cash.svg', _incomeColor, width: 27),
    CategoryIconSpec(
      'graduation',
      '$_root/income_graduation.svg',
      _incomeColor,
    ),
    CategoryIconSpec('award', '$_root/income_award.svg', _incomeColor),
    CategoryIconSpec('piggy', '$_root/income_piggy.svg', _incomeColor),
    CategoryIconSpec('receipt', '$_root/income_receipt.svg', _incomeColor),
    CategoryIconSpec('dots', '$_root/income_dots.svg', _incomeColor),
    CategoryIconSpec('briefcase', '$_root/income_briefcase.svg', _incomeColor),
    CategoryIconSpec('gift', '$_root/income_gift.svg', _incomeColor),
    CategoryIconSpec('heart', '$_root/income_heart.svg', _incomeColor),
    CategoryIconSpec('wallet', '$_root/income_wallet.svg', _incomeColor),
    CategoryIconSpec('trend', '$_root/income_trend.svg', _incomeColor),
    CategoryIconSpec('dollar', '$_root/income_dollar.svg', _incomeColor),
    CategoryIconSpec('bank', '$_root/income_bank.svg', _incomeColor),
    CategoryIconSpec('laptop', '$_root/income_laptop.svg', _incomeColor),
  ];

  static List<CategoryIconSpec> of(CategoryKind kind) =>
      kind == CategoryKind.expense ? expense : income;

  static CategoryIconSpec? find(String? id, CategoryKind kind) {
    if (id == null) return null;
    for (final spec in of(kind)) {
      if (spec.id == id) return spec;
    }
    return null;
  }

  /// 기본 지출 카테고리의 대표 색(선택 테두리 색).
  static Color defaultExpenseColor(String name) => switch (name) {
    '식비' => const Color(0xFFFA9441),
    '카페' || '카페/간식' => const Color(0xFFC1B4B4),
    '쇼핑' => const Color(0xFFD841B8),
    '의료' || '의료/건강' => const Color(0xFFE74646),
    '문화' || '문화/여가' => const Color(0xFFA8D886),
    '교통' || '교통/차량' => const Color(0xFF4C64FF),
    '교육' => const Color(0xFFA8A3FF),
    _ => const Color(0xFF5E56FF),
  };

  /// 카테고리 이름·아이콘 식별자로 표시할 SVG 경로를 고른다.
  /// 기본 카테고리는 icon=null 이라 이름으로 매칭한다.
  static String assetFor({
    required String? name,
    required String? icon,
    required CategoryKind kind,
  }) {
    final spec = find(icon, kind);
    if (spec != null) return spec.asset;
    return kind == CategoryKind.income
        ? AppAssets.incomeIconFor(name)
        : AppAssets.categoryIconFor(name);
  }

  static Color colorFor({
    required String? name,
    required String? icon,
    required CategoryKind kind,
  }) {
    final spec = find(icon, kind);
    if (spec != null) return spec.color;
    return kind == CategoryKind.income
        ? _incomeColor
        : defaultExpenseColor(name ?? '');
  }

  /// 직접 만든 아이콘은 26×26 프레임 전체를 그대로 쓴다.
  static bool isCustomIcon(String? icon, CategoryKind kind) =>
      find(icon, kind) != null;
}
