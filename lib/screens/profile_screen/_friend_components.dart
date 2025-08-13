// Friend Card Components for Profile Screen
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../friend_profile_screen/friend_profile_screen.dart';

// Friend Card Component
class FriendCard extends StatelessWidget {
  final dynamic friend; // FriendshipModel
  final dynamic friendshipProvider; // FriendshipProvider (optional)
  
  const FriendCard({super.key, required this.friend, this.friendshipProvider});

  // PROVER color system
  static const Color _void = Color(0xFF000000);
  static const Color _nebula = Color(0xFF0F0F12);
  static const Color _stellar = Color(0xFF18181C);
  static const Color _lunar = Color(0xFF242429);
  static const Color _comet = Color(0xFF65656F);
  static const Color _stardust = Color(0xFFA5A5B0);
  static const Color _nova = Color(0xFFF5F5F7);
  static const Color _proverCore = Color(0xFFFF4500);
  static const Color _proverGlow = Color(0xFFFF6B3D);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _stellar.withOpacity(0.6),
            _nebula.withOpacity(0.4),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _lunar.withOpacity(0.4),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: _void.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          // Profile Picture
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [_proverCore, _proverGlow],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: _proverCore.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              child: Text(
                friend.friendUsername.isNotEmpty
                    ? friend.friendUsername.substring(0, 1).toUpperCase()
                    : '?',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: _nova,
                ),
              ),
            ),
          ),
          
          const SizedBox(width: 16),
          
          // Friend Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  friend.friendUsername,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: _nova,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  friend.friendEmail,
                  style: TextStyle(
                    fontSize: 13,
                    color: _stardust,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          
          // Actions
          Row(
            children: [
              // View Profile Button
              GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => FriendProfileScreen(friendship: friend),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _lunar.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: _stellar.withOpacity(0.5)),
                  ),
                  child: Icon(
                    Icons.visibility_rounded,
                    color: _stardust,
                    size: 18,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // More Options
              GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  if (friendshipProvider != null) {
                    _showFriendOptions(context, friend, friendshipProvider);
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _lunar.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: _stellar.withOpacity(0.5)),
                  ),
                  child: Icon(
                    Icons.more_horiz_rounded,
                    color: _stardust,
                    size: 18,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showFriendOptions(BuildContext context, dynamic friend, dynamic friendshipProvider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [_stellar, _nebula],
          ),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          border: Border.all(
            color: _lunar.withOpacity(0.3),
            width: 1,
          ),
        ),
        padding: const EdgeInsets.all(20),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [_proverCore, _proverGlow]),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.people_rounded, color: _nova, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Freund Optionen',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.3,
                      color: _nova,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: Icon(Icons.close, size: 22, color: _stardust),
                    onPressed: () => Navigator.of(context).pop(),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              
              // Remove Friend Option
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [_lunar.withOpacity(0.3), _lunar.withOpacity(0.1)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.withOpacity(0.4), width: 1),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      Navigator.of(context).pop();
                      _confirmRemoveFriend(context, friend, friendshipProvider);
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                      child: Row(
                        children: [
                          Icon(Icons.person_remove_rounded, size: 18, color: Colors.red),
                          const SizedBox(width: 12),
                          Text(
                            'Freund entfernen',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              letterSpacing: -0.3,
                              color: Colors.red,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmRemoveFriend(BuildContext context, dynamic friend, dynamic friendshipProvider) {
    showDialog(
      context: context,
      barrierColor: _void.withOpacity(0.7),
      builder: (context) => AlertDialog(
        backgroundColor: _stellar,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: _lunar.withOpacity(0.3),
            width: 1,
          ),
        ),
        title: Text(
          'Freund entfernen',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: _nova,
            letterSpacing: 0.3,
          ),
        ),
        content: Text(
          'Möchtest du ${friend.friendUsername} aus deiner Freundesliste entfernen?',
          style: TextStyle(
            fontSize: 14,
            color: _stardust,
            height: 1.4,
          ),
        ),
        actions: [
          // Cancel button
          Container(
            decoration: BoxDecoration(
              color: _lunar.withOpacity(0.3),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: _lunar.withOpacity(0.5),
                width: 1,
              ),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  HapticFeedback.lightImpact();
                  Navigator.pop(context);
                },
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Text(
                    'ABBRECHEN',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: _stardust,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Remove button
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.red[600]!, Colors.red[400]!],
              ),
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.red.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () async {
                  HapticFeedback.lightImpact();
                  await friendshipProvider.removeFriend(friend.id);
                  Navigator.pop(context);
                },
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Text(
                    'ENTFERNEN',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: _nova,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Friend Request Card Component
class FriendRequestCard extends StatelessWidget {
  final dynamic request; // FriendRequestModel
  final dynamic provider; // FriendshipProvider
  
  const FriendRequestCard({super.key, required this.request, required this.provider});

  // PROVER color system
  static const Color _void = Color(0xFF000000);
  static const Color _nebula = Color(0xFF0F0F12);
  static const Color _stellar = Color(0xFF18181C);
  static const Color _lunar = Color(0xFF242429);
  static const Color _comet = Color(0xFF65656F);
  static const Color _stardust = Color(0xFFA5A5B0);
  static const Color _nova = Color(0xFFF5F5F7);
  static const Color _proverCore = Color(0xFFFF4500);
  static const Color _proverGlow = Color(0xFFFF6B3D);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _stellar.withOpacity(0.6),
            _nebula.withOpacity(0.4),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _proverCore.withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: _proverCore.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Profile Picture
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [_proverCore, _proverGlow],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: _proverCore.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    request.senderUsername.isNotEmpty
                        ? request.senderUsername.substring(0, 1).toUpperCase()
                        : '?',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: _nova,
                    ),
                  ),
                ),
              ),
              
              const SizedBox(width: 16),
              
              // Request Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      request.senderUsername,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: _nova,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Möchte dich als Freund hinzufügen',
                      style: TextStyle(
                        fontSize: 13,
                        color: _stardust,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Action Buttons
          Row(
            children: [
              // Accept Button
              Expanded(
                child: GestureDetector(
                  onTap: () async {
                    HapticFeedback.lightImpact();
                    await provider.acceptFriendRequest(request.id);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [_proverCore, _proverGlow],
                      ),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: _proverCore.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        'AKZEPTIEREN',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: _nova,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              
              const SizedBox(width: 12),
              
              // Decline Button
              Expanded(
                child: GestureDetector(
                  onTap: () async {
                    HapticFeedback.lightImpact();
                    await provider.declineFriendRequest(request.id);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: _lunar.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: _stellar.withOpacity(0.5),
                        width: 1,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        'ABLEHNEN',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: _stardust,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}