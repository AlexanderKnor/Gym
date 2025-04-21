// lib/widgets/profile_screen/components/add_friend_dialog_widget.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/profile_screen/friendship_provider.dart';
import '../../../models/auth/user_model.dart';

class AddFriendDialogWidget extends StatefulWidget {
  const AddFriendDialogWidget({Key? key}) : super(key: key);

  @override
  State<AddFriendDialogWidget> createState() => _AddFriendDialogWidgetState();
}

class _AddFriendDialogWidgetState extends State<AddFriendDialogWidget> {
  final _formKey = GlobalKey<FormState>();
  final _searchController = TextEditingController();
  bool _isSearching = false;
  List<UserModel> _foundUsers = [];
  String? _errorMessage;

  // Suchtyp: Benutzername oder E-Mail
  bool _searchByUsername = true; // Standard: Nach Benutzername suchen

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: double.maxFinite,
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Freund hinzufügen',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // Suchtyp-Umschalter
            Row(
              children: [
                const Text('Suchen nach:'),
                const SizedBox(width: 16),
                ChoiceChip(
                  label: const Text('Benutzername'),
                  selected: _searchByUsername,
                  onSelected: (selected) {
                    setState(() {
                      _searchByUsername = true;
                      _foundUsers = []; // Ergebnisse zurücksetzen
                    });
                  },
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('E-Mail'),
                  selected: !_searchByUsername,
                  onSelected: (selected) {
                    setState(() {
                      _searchByUsername = false;
                      _foundUsers = []; // Ergebnisse zurücksetzen
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Suchformular
            Form(
              key: _formKey,
              child: TextFormField(
                controller: _searchController,
                decoration: InputDecoration(
                  labelText:
                      _searchByUsername ? 'Benutzername' : 'E-Mail-Adresse',
                  hintText: _searchByUsername
                      ? 'Gib den Benutzernamen ein'
                      : 'Gib die E-Mail-Adresse ein',
                  border: const OutlineInputBorder(),
                  prefixIcon: _searchByUsername
                      ? const Icon(Icons.person)
                      : const Icon(Icons.email),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.search),
                    onPressed: () => _searchUsers(context),
                  ),
                ),
                keyboardType: _searchByUsername
                    ? TextInputType.text
                    : TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return _searchByUsername
                        ? 'Bitte gib einen Benutzernamen ein'
                        : 'Bitte gib eine E-Mail-Adresse ein';
                  }
                  if (!_searchByUsername &&
                      (!value.contains('@') || !value.contains('.'))) {
                    return 'Bitte gib eine gültige E-Mail-Adresse ein';
                  }
                  return null;
                },
                onFieldSubmitted: (_) => _searchUsers(context),
              ),
            ),

            // Suchstatus und Ergebnisse
            const SizedBox(height: 16),
            if (_isSearching)
              const Center(child: CircularProgressIndicator())
            else if (_errorMessage != null)
              Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.red),
              )
            else if (_foundUsers.isEmpty && _hasSearched)
              Center(
                child: Column(
                  children: [
                    Icon(Icons.person_off, size: 48, color: Colors.grey[400]),
                    const SizedBox(height: 8),
                    Text(
                      'Keine Benutzer gefunden',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              )
            else if (_foundUsers.isNotEmpty)
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _foundUsers.length,
                  itemBuilder: (context, index) =>
                      _buildUserItem(_foundUsers[index]),
                ),
              ),

            // Aktionsbuttons
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Schließen'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Hilfsvariable, um zu prüfen, ob bereits gesucht wurde
  bool get _hasSearched => _foundUsers.isNotEmpty || _errorMessage != null;

  Widget _buildUserItem(UserModel user) {
    final friendshipProvider = Provider.of<FriendshipProvider>(context);
    final sentRequests = friendshipProvider.sentRequests;
    final friends = friendshipProvider.friends;

    bool isAlreadyFriend = friends.any((f) => f.friendId == user.uid);
    bool requestAlreadySent = sentRequests.any((r) => r.receiverId == user.uid);

    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.green,
          child: Text(
            user.username.isNotEmpty
                ? user.username.substring(0, 1).toUpperCase()
                : '?',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(user.username),
        subtitle: Text(user.email),
        trailing: isAlreadyFriend
            ? const Chip(
                label: Text('Bereits Freund'),
                backgroundColor: Colors.grey,
              )
            : requestAlreadySent
                ? const Chip(
                    label: Text('Anfrage gesendet'),
                    backgroundColor: Colors.amber,
                  )
                : ElevatedButton(
                    onPressed: () => _sendRequest(friendshipProvider, user),
                    child: const Text('Hinzufügen'),
                  ),
      ),
    );
  }

  Future<void> _searchUsers(BuildContext context) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSearching = true;
      _foundUsers = [];
      _errorMessage = null;
    });

    try {
      final friendshipProvider =
          Provider.of<FriendshipProvider>(context, listen: false);
      final searchText = _searchController.text.trim();

      if (_searchByUsername) {
        // Nach Benutzername suchen
        final users = await friendshipProvider.findUsersByUsername(searchText);
        setState(() {
          _foundUsers = users;
          if (users.isEmpty) {
            _errorMessage = 'Keine Benutzer mit diesem Namen gefunden';
          }
        });
      } else {
        // Nach E-Mail suchen (bisherige Funktionalität)
        final user = await friendshipProvider.findUserByEmail(searchText);
        setState(() {
          _foundUsers = user != null ? [user] : [];
          if (user == null) {
            _errorMessage = 'Kein Benutzer mit dieser E-Mail-Adresse gefunden';
          }
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Fehler bei der Suche: $e';
      });
    } finally {
      setState(() {
        _isSearching = false;
      });
    }
  }

  Future<void> _sendRequest(FriendshipProvider provider, UserModel user) async {
    setState(() {
      _isSearching = true;
    });

    try {
      final success = await provider.sendFriendRequest(user);

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Freundschaftsanfrage erfolgreich gesendet'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      } else if (mounted) {
        setState(() {
          _errorMessage = 'Fehler beim Senden der Anfrage';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Fehler: $e';
      });
    } finally {
      setState(() {
        _isSearching = false;
      });
    }
  }
}
