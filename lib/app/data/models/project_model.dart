enum ProjectType { web, app }

class ProjectModel {
  final String title;
  final String description;
  final List<String> imagePaths;
  final List<String> technologies;
  final String? githubUrl;
  final String? liveUrl;
  final String? appStoreUrl;
  final String? playStoreUrl;
  final ProjectType type;

  ProjectModel({
    required this.title,
    required this.description,
    required this.imagePaths,
    required this.technologies,
    this.githubUrl,
    this.liveUrl,
    this.appStoreUrl,
    this.playStoreUrl,
    this.type = ProjectType.web,
  });

  String get primaryImage => imagePaths.isNotEmpty ? imagePaths.first : '';
  bool get hasMultipleImages => imagePaths.length > 1;
}
