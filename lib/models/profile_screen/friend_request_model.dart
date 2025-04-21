// lib/models/profile_screen/friend_request_model.dart
enum FriendRequestStatus { pending, accepted, rejected }

class FriendRequestModel {
  final String id;
  final String senderId;
  final String senderUsername;
  final String receiverId;
  final FriendRequestStatus status;
  final DateTime createdAt;

  FriendRequestModel({
    required this.id,
    required this.senderId,
    required this.senderUsername,
    required this.receiverId,
    required this.status,
    required this.createdAt,
  });

  factory FriendRequestModel.fromMap(Map<String, dynamic> map) {
    print('Konvertiere Anfrage-Map: $map');
    FriendRequestStatus status;
    try {
      // Prüfen, ob der Status als String oder als Enum-Wert gespeichert ist
      if (map['status'] is String) {
        final statusString = map['status'] as String;
        print('Status-String: $statusString');

        // Enum parsen
        if (statusString.contains('FriendRequestStatus.')) {
          // Format ist "FriendRequestStatus.pending"
          final enumValue = statusString.split('.').last;
          status = FriendRequestStatus.values.firstWhere(
              (s) => s.toString().split('.').last == enumValue,
              orElse: () => FriendRequestStatus.pending);
        } else {
          // Format ist "pending"
          status = FriendRequestStatus.values.firstWhere(
              (s) => s.toString().split('.').last == statusString,
              orElse: () => FriendRequestStatus.pending);
        }
      } else {
        // Fallback
        status = FriendRequestStatus.pending;
      }
    } catch (e) {
      print('Fehler beim Parsen des Status: $e');
      status = FriendRequestStatus.pending;
    }

    print('Geparster Status: $status');

    return FriendRequestModel(
      id: map['id'] ?? '',
      senderId: map['senderId'] ?? '',
      senderUsername: map['senderUsername'] ?? 'Unbekannt',
      receiverId: map['receiverId'] ?? '',
      status: status,
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    final statusString = status.toString().split('.').last;
    print('Speichere Status als: $statusString');

    return {
      'id': id,
      'senderId': senderId,
      'senderUsername': senderUsername,
      'receiverId': receiverId,
      'status': statusString,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  // Erstellt eine Kopie mit aktualisierten Werten
  FriendRequestModel copyWith({
    String? id,
    String? senderId,
    String? senderUsername,
    String? receiverId,
    FriendRequestStatus? status,
    DateTime? createdAt,
  }) {
    return FriendRequestModel(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      senderUsername: senderUsername ?? this.senderUsername,
      receiverId: receiverId ?? this.receiverId,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
