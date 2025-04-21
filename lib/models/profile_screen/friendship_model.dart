// lib/models/profile_screen/friendship_model.dart
class FriendshipModel {
  final String id;
  final String userId;
  final String friendId;
  final String friendUsername;
  final String friendEmail;
  final DateTime createdAt;

  FriendshipModel({
    required this.id,
    required this.userId,
    required this.friendId,
    required this.friendUsername,
    required this.friendEmail,
    required this.createdAt,
  });

  factory FriendshipModel.fromMap(Map<String, dynamic> map) {
    return FriendshipModel(
      id: map['id'],
      userId: map['userId'],
      friendId: map['friendId'],
      friendUsername: map['friendUsername'],
      friendEmail: map['friendEmail'],
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'friendId': friendId,
      'friendUsername': friendUsername,
      'friendEmail': friendEmail,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
