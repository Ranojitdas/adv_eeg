class YogaPose {
  final String poseName;
  final String poseImage;
  final String description;
  final List<String> steps;
  final String videoUrl;
  final String difficulty;
  final int duration;
  final List<String> benefits;

  YogaPose({
    required this.poseName,
    required this.poseImage,
    required this.description,
    required this.steps,
    required this.videoUrl,
    required this.difficulty,
    required this.duration,
    required this.benefits,
  });
}
