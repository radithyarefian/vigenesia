class MotivationModel {
  final String id;
  final String userId;
  final String userDisplayName;
  final String userProfession;
  final String userPhotoURL;
  final String content;
  final String? imageURL;
  final String category;
  final int likesCount;
  final int commentsCount;
  final bool isLiked;
  final DateTime createdAt;

  MotivationModel({
    required this.id,
    required this.userId,
    required this.userDisplayName,
    required this.userProfession,
    required this.userPhotoURL,
    required this.content,
    this.imageURL,
    required this.category,
    required this.likesCount,
    required this.commentsCount,
    required this.isLiked,
    required this.createdAt,
  });

  factory MotivationModel.fromJson(Map<String, dynamic> json) {
    return MotivationModel(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? '',
      userDisplayName: json['user_display_name'] ?? '',
      userProfession: json['user_profession'] ?? '',
      userPhotoURL: json['user_photo_url'] ?? '',
      content: json['content'] ?? '',
      imageURL: json['image_url'],
      category: json['category'] ?? '',
      likesCount: json['likes_count'] ?? 0,
      commentsCount: json['comments_count'] ?? 0,
      isLiked: json['is_liked'] ?? false,
      createdAt: DateTime.parse(
        json['created_at'] ?? DateTime.now().toIso8601String(),
      ),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'user_id': userId,
    'user_display_name': userDisplayName,
    'user_profession': userProfession,
    'user_photo_url': userPhotoURL,
    'content': content,
    'image_url': imageURL,
    'category': category,
    'likes_count': likesCount,
    'comments_count': commentsCount,
    'is_liked': isLiked,
    'created_at': createdAt.toIso8601String(),
  };

  MotivationModel copyWith({
    String? id,
    String? userId,
    String? userDisplayName,
    String? userProfession,
    String? userPhotoURL,
    String? content,
    String? imageURL,
    bool clearImage = false,
    String? category,
    int? likesCount,
    int? commentsCount,
    bool? isLiked,
    DateTime? createdAt,
  }) {
    return MotivationModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userDisplayName: userDisplayName ?? this.userDisplayName,
      userProfession: userProfession ?? this.userProfession,
      userPhotoURL: userPhotoURL ?? this.userPhotoURL,
      content: content ?? this.content,
      imageURL: clearImage ? null : (imageURL ?? this.imageURL),
      category: category ?? this.category,
      likesCount: likesCount ?? this.likesCount,
      commentsCount: commentsCount ?? this.commentsCount,
      isLiked: isLiked ?? this.isLiked,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}