import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String id;
  final String email;
  final String displayName;
  final String photoURL;
  final String profession;
  final String bio;
  final String address; // BARU
  final double? latitude;
  final double? longitude;
  final bool isOnline;
  final bool profileCompleted;
  final DateTime lastSeen;
  final DateTime createdAt;

  UserModel({
    required this.id,
    required this.email,
    required this.displayName,
    this.photoURL = "",
    this.profession = "",
    this.bio = "",
    this.address = "", // BARU
    this.latitude,
    this.longitude,
    this.isOnline = false,
    this.profileCompleted = false,
    required this.lastSeen,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'displayName': displayName,
      'photoURL': photoURL,
      'profession': profession,
      'bio': bio,
      'address': address, // BARU
      'latitude': latitude,
      'longitude': longitude,
      'isOnline': isOnline,
      'profileCompleted': profileCompleted,
      'lastSeen': lastSeen,
      'createdAt': createdAt,
    };
  }

  static UserModel fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] ?? '',
      email: map['email'] ?? '',
      displayName: map['displayName'] ?? '',
      photoURL: map['photoURL'] ?? '',
      profession: map['profession'] ?? '',
      bio: map['bio'] ?? '',
      address: map['address'] ?? '', // BARU
      latitude: map['latitude'] != null
          ? (map['latitude'] as num).toDouble()
          : null,
      longitude: map['longitude'] != null
          ? (map['longitude'] as num).toDouble()
          : null,
      isOnline: map['isOnline'] ?? false,
      profileCompleted: map['profileCompleted'] ?? false,
      lastSeen: map['lastSeen'] != null
          ? (map['lastSeen'] as Timestamp).toDate()
          : DateTime.now(),
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  UserModel copyWith({
    String? id,
    String? email,
    String? displayName,
    String? photoURL,
    String? profession,
    String? bio,
    String? address, // BARU
    double? latitude,
    double? longitude,
    bool? isOnline,
    bool? profileCompleted,
    DateTime? lastSeen,
    DateTime? createdAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoURL: photoURL ?? this.photoURL,
      profession: profession ?? this.profession,
      bio: bio ?? this.bio,
      address: address ?? this.address, // BARU
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      isOnline: isOnline ?? this.isOnline,
      profileCompleted: profileCompleted ?? this.profileCompleted,
      lastSeen: lastSeen ?? this.lastSeen,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  bool get isProfileComplete =>
      profileCompleted ||
      (displayName.isNotEmpty &&
          profession.isNotEmpty &&
          bio.isNotEmpty);
}