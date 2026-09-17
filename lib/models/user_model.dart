class UserModel {
  final int id;
  final String name;
  final String? fullName;
  final bool disabled;
  final String? type;

  UserModel({
    required this.id,
    required this.name,
    this.fullName,
    this.disabled = false,
    this.type,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: json['name']?.toString() ?? 'Usuario',
      fullName: json['fullName']?.toString(),
      disabled: json['disabled'] as bool? ?? false,
      type: json['type']?.toString(),
    );
  }

  String get displayName => fullName?.isNotEmpty == true ? fullName! : name;
}
