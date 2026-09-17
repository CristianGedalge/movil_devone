class IssueModel {
  final int id;
  final int number;
  final String title;
  final String? description;
  final String state;
  final int? projectId;
  final String? submitterName;
  final DateTime? submitDate;
  final int commentCount;

  IssueModel({
    required this.id,
    required this.number,
    required this.title,
    this.description,
    required this.state,
    this.projectId,
    this.submitterName,
    this.submitDate,
    this.commentCount = 0,
  });

  factory IssueModel.fromJson(Map<String, dynamic> json) {
    DateTime? parsedDate;
    if (json['submitDate'] != null) {
      if (json['submitDate'] is int) {
        parsedDate = DateTime.fromMillisecondsSinceEpoch(json['submitDate'] as int);
      } else if (json['submitDate'] is String) {
        parsedDate = DateTime.tryParse(json['submitDate'] as String);
      }
    }

    return IssueModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      number: (json['number'] as num?)?.toInt() ?? (json['id'] as num?)?.toInt() ?? 0,
      title: json['title']?.toString() ?? 'Sin título',
      description: json['description']?.toString(),
      state: json['state']?.toString() ?? 'Open',
      projectId: (json['projectId'] as num?)?.toInt(),
      submitterName: json['submitterName']?.toString() ?? json['submitter']?['name']?.toString(),
      submitDate: parsedDate,
      commentCount: (json['commentCount'] as num?)?.toInt() ?? 0,
    );
  }

  bool get isOpen => state.toLowerCase() == 'open';
}
