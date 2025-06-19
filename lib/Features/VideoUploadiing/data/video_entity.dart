import 'package:cloud_firestore/cloud_firestore.dart';

class VideoEntity {
  final String id;
  final String userId;
  final String videoUrl;
  final String caption;
  final DateTime createdAt;
  final List<String> likes;
  final List<String> saves;
  final String userEmail;
  final String userName;

  VideoEntity({
    required this.id,
    required this.userId,
    required this.videoUrl,
    required this.caption,
    required this.createdAt,
    required this.likes,
    required this.saves,
    required this.userEmail,
    required this.userName,
  });

  // Convert VideoEntity to a Map for Firebase storage
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'videoUrl': videoUrl,
      'caption': caption,
      'createdAt': createdAt,
      'likes': likes,
      'saves': saves,
      'userEmail': userEmail,
      'userName': userName,
    };
  }

  // Factory constructor to create a VideoEntity from Firestore data
  factory VideoEntity.fromMap(Map<String, dynamic> map, String documentId) {
    return VideoEntity(
      id: documentId,
      userId: map['userId'] ?? '',
      videoUrl: map['videoUrl'] ?? '',
      caption: map['caption'] ?? '',
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      likes: List<String>.from(map['likes'] ?? []),
      saves: List<String>.from(map['saves'] ?? []),
      userEmail: map['userEmail'] ?? '',
      userName: map['userName'] ?? '',
    );
  }

  // Copy with method for easy updates
  VideoEntity copyWith({
    String? id,
    String? userId,
    String? videoUrl,
    String? caption,
    DateTime? createdAt,
    List<String>? likes,
    List<String>? saves,
    String? userEmail,
    String? userName,
  }) {
    return VideoEntity(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      videoUrl: videoUrl ?? this.videoUrl,
      caption: caption ?? this.caption,
      createdAt: createdAt ?? this.createdAt,
      likes: likes ?? this.likes,
      saves: saves ?? this.saves,
      userEmail: userEmail ?? this.userEmail,
      userName: userName ?? this.userName,
    );
  }
}