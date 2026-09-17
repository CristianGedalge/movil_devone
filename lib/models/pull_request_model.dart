class PullRequestModel {
  final int id;
  final int number;
  final String title;
  final String? description;
  final String targetBranch;
  final String sourceBranch;
  final String status;
  final String? submitterName;
  final DateTime? submitDate;

  PullRequestModel({
    required this.id,
    required this.number,
    required this.title,
    this.description,
    required this.targetBranch,
    required this.sourceBranch,
    required this.status,
    this.submitterName,
    this.submitDate,
  });

  factory PullRequestModel.fromJson(Map<String, dynamic> json) {
    DateTime? parsedDate;
    if (json['submitDate'] != null) {
      if (json['submitDate'] is int) {
        parsedDate = DateTime.fromMillisecondsSinceEpoch(json['submitDate'] as int);
      } else if (json['submitDate'] is String) {
        parsedDate = DateTime.tryParse(json['submitDate'] as String);
      }
    }

    String derivedStatus = 'OPEN';
    if (json['closeInfo'] != null && json['closeInfo'] is Map) {
      derivedStatus = json['closeInfo']['status']?.toString() ?? 'CLOSED';
    } else if (json['status'] != null) {
      derivedStatus = json['status'].toString();
    }

    return PullRequestModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      number: (json['number'] as num?)?.toInt() ?? (json['id'] as num?)?.toInt() ?? 0,
      title: json['title']?.toString() ?? 'Sin título',
      description: json['description']?.toString(),
      targetBranch: json['targetBranch']?.toString() ?? 'main',
      sourceBranch: json['sourceBranch']?.toString() ?? 'feature',
      status: derivedStatus.toUpperCase(),
      submitterName: json['submitterName']?.toString() ?? json['submitter']?['name']?.toString(),
      submitDate: parsedDate,
    );
  }

  bool get isOpen => status == 'OPEN';
  bool get isMerged => status == 'MERGED';
  bool get isDiscarded => status == 'DISCARDED';
}
