import 'user_role.dart';

/// Modèle utilisateur correspondant à la réponse de l'API NestJS.
///
/// Format backend :
/// ```json
/// {
///   "id": 1,
///   "email": "jean@example.com",
///   "nom": "Dupont",
///   "prenom": "Jean",
///   "role": "ETUDIANT",
///   "createdAt": "2026-09-16T00:00:00.000Z"
/// }
/// ```
class UserModel {
  const UserModel({
    required this.id,
    required this.nom,
    required this.prenom,
    required this.email,
    required this.role,
    this.createdAt,
  });

  final int id;
  final String nom;
  final String prenom;
  final String email;
  final UserRole role;
  final DateTime? createdAt;

  /// « Jean Dupont »
  String get fullName => '$prenom $nom';

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as int,
      nom: json['nom'] as String,
      prenom: json['prenom'] as String,
      email: json['email'] as String,
      role: UserRole.fromApi(json['role'] as String),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
    );
  }
}
