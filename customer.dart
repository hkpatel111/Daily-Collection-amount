class Customer {
  final int? id;
  String name;
  String mobile;
  final String createdAt;
  bool isActive;

  Customer({
    this.id,
    required this.name,
    required this.mobile,
    required this.createdAt,
    this.isActive = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'mobile': mobile,
      'created_at': createdAt,
      'is_active': isActive ? 1 : 0,
    };
  }

  factory Customer.fromMap(Map<String, dynamic> map) {
    return Customer(
      id: map['id'] as int?,
      name: map['name'] as String,
      mobile: map['mobile'] as String,
      createdAt: map['created_at'] as String,
      isActive: (map['is_active'] as int) == 1,
    );
  }

  Customer copyWith({
    int? id,
    String? name,
    String? mobile,
    String? createdAt,
    bool? isActive,
  }) {
    return Customer(
      id: id ?? this.id,
      name: name ?? this.name,
      mobile: mobile ?? this.mobile,
      createdAt: createdAt ?? this.createdAt,
      isActive: isActive ?? this.isActive,
    );
  }
}
