import 'package:flutter/foundation.dart';

import 'category_models.dart';

/// 등록_013: 카테고리 추가·수정·삭제 API.
abstract interface class CategoryService {
  Future<List<CategoryItem>> categories(CategoryKind kind);

  Future<CategoryItem> createCategory({
    required String name,
    required String icon,
    required CategoryKind kind,
  });

  Future<CategoryItem> updateCategory(
    CategoryItem category, {
    required String name,
    required String icon,
  });

  /// [moveTo] 를 주면 그 카테고리(이름)로 내역을 옮긴 뒤 삭제, 없으면 내역까지 전체 삭제.
  Future<Map<String, dynamic>> deleteCategory(
    CategoryItem category, {
    String? moveTo,
  });
}

/// 앱 전체에서 같은 카테고리 목록(순서·아이콘)을 쓰도록 보관하는 저장소.
/// 필터 시트, 등록·수정 화면의 카테고리 선택, 가계부 목록 아이콘이 함께 사용한다.
class CategoryStore extends ChangeNotifier {
  CategoryStore._();

  static final CategoryStore instance = CategoryStore._();

  final Map<CategoryKind, List<CategoryItem>> _items = {
    CategoryKind.expense: defaultCategories(CategoryKind.expense),
    CategoryKind.income: defaultCategories(CategoryKind.income),
  };
  final Set<CategoryKind> _loaded = {};

  List<CategoryItem> of(CategoryKind kind) => List.unmodifiable(_items[kind]!);

  bool isLoaded(CategoryKind kind) => _loaded.contains(kind);

  /// 직접 만든 카테고리의 아이콘 식별자를 이름으로 찾는다.
  String? iconFor(String? name, CategoryKind kind) {
    if (name == null) return null;
    for (final item in _items[kind]!) {
      if (item.name == name) return item.icon;
    }
    return null;
  }

  Future<List<CategoryItem>> load(
    CategoryService service,
    CategoryKind kind,
  ) async {
    final items = await service.categories(kind);
    replace(kind, items);
    return of(kind);
  }

  Future<void> loadAll(CategoryService service) async {
    await Future.wait([
      load(service, CategoryKind.expense),
      load(service, CategoryKind.income),
    ]);
  }

  void replace(CategoryKind kind, List<CategoryItem> items) {
    _items[kind] = items.isEmpty ? defaultCategories(kind) : [...items];
    _loaded.add(kind);
    notifyListeners();
  }

  @visibleForTesting
  void reset() {
    _items[CategoryKind.expense] = defaultCategories(CategoryKind.expense);
    _items[CategoryKind.income] = defaultCategories(CategoryKind.income);
    _loaded.clear();
    notifyListeners();
  }
}

/// 화면이 열릴 때 카테고리 목록을 미리 불러둔다(실패해도 기본 카테고리로 동작).
Future<void> preloadCategories(Object? service) async {
  if (service is! CategoryService) return;
  try {
    await CategoryStore.instance.loadAll(service);
  } catch (_) {}
}

/// 등록·수정의 카테고리 선택 목록(기본 먼저, 그다음 직접 만든 순서).
List<String> categoryNames(CategoryKind kind, {String? including}) {
  final names = [for (final item in CategoryStore.instance.of(kind)) item.name];
  if (including != null &&
      including.isNotEmpty &&
      including != '선택' &&
      !names.contains(including)) {
    names.add(including);
  }
  return names;
}
