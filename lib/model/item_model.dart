class Item {
  final String id;
  final String name;
  final String category; // 'Food', 'Stationery', 'Electronics'
  final String imageUrl;

  Item({
    required this.id,
    required this.name,
    required this.category,
    this.imageUrl = '',
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'category': category,
      'imageUrl': imageUrl,
    };
  }

  factory Item.fromMap(Map<String, dynamic> map, String docId) {
    return Item(
      id: docId,
      name: map['name'] ?? '',
      category: map['category'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
    );
  }
}