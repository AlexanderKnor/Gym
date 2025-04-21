// lib/widgets/profile_screen/components/friend_request_widget.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/profile_screen/friendship_provider.dart';
import '../../../models/profile_screen/friend_request_model.dart';

class FriendRequestWidget extends StatelessWidget {
  const FriendRequestWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final friendshipProvider = Provider.of<FriendshipProvider>(context);
    final requests = friendshipProvider.receivedRequests;

    if (friendshipProvider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (requests.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.mail_outline,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Keine ausstehenden Anfragen',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => friendshipProvider.refreshFriendData(),
      child: ListView.builder(
        itemCount: requests.length,
        itemBuilder: (context, index) {
          return _buildRequestItem(
              context, requests[index], friendshipProvider);
        },
      ),
    );
  }

  Widget _buildRequestItem(
    BuildContext context,
    FriendRequestModel request,
    FriendshipProvider provider,
  ) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.orange,
          child: Text(
            request.senderUsername.substring(0, 1).toUpperCase(),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(request.senderUsername),
        subtitle: Text('Möchte mit dir befreundet sein'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Ablehnen-Button
            IconButton(
              icon: const Icon(Icons.close, color: Colors.red),
              onPressed: () => _rejectRequest(context, request, provider),
            ),
            // Annehmen-Button
            IconButton(
              icon: const Icon(Icons.check, color: Colors.green),
              onPressed: () => _acceptRequest(context, request, provider),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _acceptRequest(
    BuildContext context,
    FriendRequestModel request,
    FriendshipProvider provider,
  ) async {
    final success = await provider.acceptFriendRequest(request);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'Freundschaftsanfrage akzeptiert'
                : 'Fehler beim Akzeptieren der Anfrage',
          ),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    }
  }

  Future<void> _rejectRequest(
    BuildContext context,
    FriendRequestModel request,
    FriendshipProvider provider,
  ) async {
    final success = await provider.rejectFriendRequest(request);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'Freundschaftsanfrage abgelehnt'
                : 'Fehler beim Ablehnen der Anfrage',
          ),
          backgroundColor: success ? Colors.grey : Colors.red,
        ),
      );
    }
  }
}
