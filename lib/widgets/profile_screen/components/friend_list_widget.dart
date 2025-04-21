// lib/widgets/profile_screen/components/friend_list_widget.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/profile_screen/friendship_provider.dart';
import '../../../models/profile_screen/friendship_model.dart'; // Korrekter Import

class FriendListWidget extends StatelessWidget {
  const FriendListWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final friendshipProvider = Provider.of<FriendshipProvider>(context);
    final friends = friendshipProvider.friends;

    if (friendshipProvider.isLoading) {
      return const Center(child: CircularProgressIndicator());
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
              'Füge Freunde hinzu, um gemeinsam zu trainieren',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => friendshipProvider.refreshFriendData(),
      child: ListView.builder(
        itemCount: friends.length,
        itemBuilder: (context, index) {
          return _buildFriendItem(context, friends[index], friendshipProvider);
        },
      ),
    );
  }

  Widget _buildFriendItem(
    BuildContext context,
    FriendshipModel friend,
    FriendshipProvider provider,
  ) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.blue,
          child: Text(
            friend.friendUsername.substring(0, 1).toUpperCase(),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(friend.friendUsername),
        subtitle: Text(friend.friendEmail),
        trailing: IconButton(
          icon: const Icon(Icons.more_vert),
          onPressed: () => _showFriendOptions(context, friend, provider),
        ),
      ),
    );
  }

  void _showFriendOptions(
    BuildContext context,
    FriendshipModel friend,
    FriendshipProvider provider,
  ) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.message),
            title: const Text('Nachricht senden'),
            onTap: () {
              Navigator.pop(context);
              // Hier könnte die Nachrichtenfunktionalität implementiert werden
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Diese Funktion ist noch nicht verfügbar'),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.remove_circle_outline, color: Colors.red),
            title: const Text('Freund entfernen'),
            onTap: () {
              Navigator.pop(context);
              _confirmRemoveFriend(context, friend, provider);
            },
          ),
        ],
      ),
    );
  }

  void _confirmRemoveFriend(
    BuildContext context,
    FriendshipModel friend,
    FriendshipProvider provider,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Freund entfernen'),
        content: Text(
            'Möchtest du ${friend.friendUsername} wirklich aus deiner Freundesliste entfernen?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Abbrechen'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await provider.removeFriend(friend.friendId);

              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      success
                          ? 'Freund erfolgreich entfernt'
                          : 'Fehler beim Entfernen des Freundes',
                    ),
                    backgroundColor: success ? Colors.green : Colors.red,
                  ),
                );
              }
            },
            child: const Text('Entfernen'),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
          ),
        ],
      ),
    );
  }
}
