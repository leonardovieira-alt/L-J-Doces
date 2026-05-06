class Category {
  final String id;
  final String name;
  final String description;
  final String? imageUrl;
  final int orderIndex;
  final List<SubCategory> subcategories;

  Category({
    required this.id,
    required this.name,
    required this.description,
    this.imageUrl,
    this.orderIndex = 0,
    this.subcategories = const [],
  });
}

class SubCategory {
  final String id;
  final String categoryId;
  final String name;
  final String description;
  final String? imageUrl;
  final int orderIndex;

  SubCategory({
    required this.id,
    required this.categoryId,
    required this.name,
    required this.description,
    this.imageUrl,
    this.orderIndex = 0,
  });
}
