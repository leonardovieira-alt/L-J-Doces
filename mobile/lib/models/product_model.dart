class Product {
  final String id;
  final String name;
  final String description;
  final String ingredients;
  final double price;
  final double costPrice;
  final List<String> images; // max 5
  final String categoryId;
  final String? subcategoryId;
  final Map<int, bool> availableDays; // 0=Sunday, 1=Monday... 6=Saturday
  final int stockQuantity;

  bool get isAvailableToday {
    final now = DateTime.now();
    final todayIndex =
        now.weekday % 7; // dart: 1=Mon...7=Sun -> map: 0=Sun, 1=Mon
    return availableDays[todayIndex] == true;
  }

  String get availableDaysString {
    const diaNomes = ['Dom', 'Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb'];
    List<String> ativos = [];
    for (int i = 0; i < 7; i++) {
      if (availableDays[i] == true) ativos.add(diaNomes[i]);
    }
    return ativos.isNotEmpty ? ativos.join(', ') : 'Indisponível';
  }

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.ingredients,
    required this.price,
    required this.costPrice,
    required this.images,
    required this.categoryId,
    this.subcategoryId,
    required this.availableDays,
    required this.stockQuantity,
  });
}
