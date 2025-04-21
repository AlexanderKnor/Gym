// lib/widgets/profile_screen/components/friend_list_widget.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/profile_screen/friendship_model.dart';
import '../../../providers/profile_screen/friendship_provider.dart';

class FriendListWidget extends StatelessWidget {
  const FriendListWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final friendshipProvider = Provider.of<FriendshipProvider>(context);
    final friends = friendshipProvider.friends;

    if (friendshipProvider.isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (friends.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people_outline,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Noch keine Freunde',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Füge Freunde hinzu, um deine Fortschritte zu teilen',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: friends.length,
      itemBuilder: (context, index) {
        final friend = friends[index];
        return _buildFriendItem(context, friend, friendshipProvider);
      },
    );
  }

  Widget _buildFriendItem(BuildContext context, FriendshipModel friend,
      FriendshipProvider friendshipProvider) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.blue,
          child: Text(
            friend.friendUsername.isNotEmpty
                ? friend.friendUsername.substring(0, 1).toUpperCase()
                : '?',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          friend.friendUsername,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(friend.friendEmail),
        trailing: IconButton(
          icon: const Icon(
            Icons.delete,
            color: Colors.red,
          ),
          onPressed: () =>
              _confirmRemoveFriend(context, friend, friendshipProvider),
        ),
      ),
    );
  }

  // Dialog zur Bestätigung beim Entfernen eines Freundes
  void _confirmRemoveFriend(BuildContext context, FriendshipModel friend,
      FriendshipProvider friendshipProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Freund entfernen'),
        content: Text(
            'Möchtest du ${friend.friendUsername} aus deiner Freundesliste entfernen?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('Abbrechen'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await friendshipProvider.removeFriend(friend.friendId);

              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${friend.friendUsername} wurde entfernt'),
                  ),
                );
              }
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Entfernen'),
          ),
        ],
      ),
    );
  }
}
