class Item {
  final int? id;
  final String name;
  final double price;
  final String? imagePath;

  Item({this.id, required this.name, required this.price, this.imagePath});

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'price': price,
      'image_path': imagePath,
    };
  }

  factory Item.fromMap(Map<String, dynamic> map) {
    return Item(
      id: map['id'] as int?,
      name: map['name'] as String,
      price: (map['price'] as num).toDouble(),
      imagePath: map['image_path'] as String?,
    );
  }

  Item copyWith({int? id, String? name, double? price, String? imagePath}) {
    return Item(
      id: id ?? this.id,
      name: name ?? this.name,
      price: price ?? this.price,
      imagePath: imagePath ?? this.imagePath,
    );
  }
}
