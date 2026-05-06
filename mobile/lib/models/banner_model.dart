class BannerModel {
  final String id;
  final String imageUrl;
  final bool active;
  final DateTime createdAt;

  BannerModel({
    required this.id,
    required this.imageUrl,
    this.active = true,
    required this.createdAt,
  });

  factory BannerModel.fromJson(Map<String, dynamic> json) {
    return BannerModel(
      id: json['id'] as String,
      imageUrl: json['image_url'] as String,
      active: json['active'] ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'image_url': imageUrl,
      'active': active,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
