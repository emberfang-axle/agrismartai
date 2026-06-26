/// Farmer evaluation record for admin dashboard (OBJECTIVE 4).
class EvaluationModel {
  final String id;
  final String farmerName;
  final int rating;
  final String? comment;
  final String? diseaseName;
  final DateTime createdAt;

  const EvaluationModel({
    required this.id,
    required this.farmerName,
    required this.rating,
    this.comment,
    this.diseaseName,
    required this.createdAt,
  });
}
