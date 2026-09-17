class ProjectModel {
  final int id;
  final String name;
  final String? key;
  final String? path;
  final String? description;
  final DateTime? createDate;
  final bool codeManagement;
  final bool issueManagement;
  final int? parentId;
  final int? forkedFromId;

  ProjectModel({
    required this.id,
    required this.name,
    this.key,
    this.path,
    this.description,
    this.createDate,
    this.codeManagement = true,
    this.issueManagement = true,
    this.parentId,
    this.forkedFromId,
  });

  factory ProjectModel.fromJson(Map<String, dynamic> json) {
    DateTime? parsedDate;
    if (json['createDate'] != null) {
      if (json['createDate'] is int) {
        parsedDate = DateTime.fromMillisecondsSinceEpoch(json['createDate'] as int);
      } else if (json['createDate'] is String) {
        parsedDate = DateTime.tryParse(json['createDate'] as String);
      }
    }

    return ProjectModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: json['name']?.toString() ?? 'Sin nombre',
      key: json['key']?.toString(),
      path: json['path']?.toString(),
      description: json['description']?.toString(),
      createDate: parsedDate,
      codeManagement: json['codeManagement'] as bool? ?? true,
      issueManagement: json['issueManagement'] as bool? ?? true,
      parentId: (json['parentId'] as num?)?.toInt(),
      forkedFromId: (json['forkedFromId'] as num?)?.toInt(),
    );
  }

  String get displayName => name;
  String get displayPath => path ?? name;
}
