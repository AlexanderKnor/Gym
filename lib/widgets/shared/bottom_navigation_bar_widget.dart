// lib/widgets/shared/bottom_navigation_bar_widget.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/shared/navigation_provider.dart';
import '../../providers/profile_screen/friendship_provider.dart';

class BottomNavigationBarWidget extends StatelessWidget {
  const BottomNavigationBarWidget({super.key});

  // Dark theme colors matching the app
  static const Color _void = Color(0xFF000000);
  static const Color _charcoal = Color(0xFF1A1A1A);
  static const Color _slate = Color(0xFF2A2A2A);
  static const Color _ember = Color(0xFFFF4500);
  static const Color _flame = Color(0xFFFF6B35);
  static const Color _pure = Color(0xFFFFFFFF);
  static const Color _ash = Color(0xFF888888);
  static const Color _smoke = Color(0xFF555555);

  @override
  Widget build(BuildContext context) {
    final navigationProvider = Provider.of<NavigationProvider>(context);
    final friendshipProvider =
        Provider.of<FriendshipProvider>(context, listen: false);

    // Initialize provider if not already initialized
    if (!friendshipProvider.isInitialized) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) {
          friendshipProvider.init();
        }
      });
    }

    return Container(
      decoration: BoxDecoration(
        color: _void,
        border: Border(
          top: BorderSide(
            color: _charcoal,
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildNavItem(
                context: context,
                icon: Icons.fitness_center,
                label: 'Training',
                index: 0,
                isSelected: navigationProvider.currentIndex == 0,
                onTap: () {
                  HapticFeedback.selectionClick();
                  navigationProvider.setCurrentIndex(0);
                },
              ),
              _buildNavItem(
                context: context,
                icon: Icons.trending_up,
                label: 'Progression',
                index: 1,
                isSelected: navigationProvider.currentIndex == 1,
                onTap: () {
                  HapticFeedback.selectionClick();
                  navigationProvider.setCurrentIndex(1);
                },
              ),
              _buildNavItem(
                context: context,
                icon: Icons.calendar_month,
                label: 'Pläne',
                index: 2,
                isSelected: navigationProvider.currentIndex == 2,
                onTap: () {
                  HapticFeedback.selectionClick();
                  navigationProvider.setCurrentIndex(2);
                },
              ),
              Consumer<FriendshipProvider>(
                builder: (context, provider, child) {
                  final hasRequests =
                      provider.isInitialized && provider.hasReceivedRequests;

                  return _buildNavItem(
                    context: context,
                    icon: Icons.person,
                    label: 'Profil',
                    index: 3,
                    isSelected: navigationProvider.currentIndex == 3,
                    showBadge: hasRequests,
                    badgeCount: provider.receivedRequests.length,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      navigationProvider.setCurrentIndex(3);

                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (context.mounted &&
                            friendshipProvider.isInitialized) {
                          friendshipProvider.refreshFriendData();
                        }
                      });
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required BuildContext context,
    required IconData icon,
    required String label,
    required int index,
    required bool isSelected,
    bool showBadge = false,
    int badgeCount = 0,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        splashColor: _ember.withOpacity(0.1),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? _ember.withOpacity(0.15) : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            border: isSelected 
                ? Border.all(color: _ember.withOpacity(0.3), width: 1)
                : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: isSelected ? _ember.withOpacity(0.2) : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      icon,
                      size: 20,
                      color: isSelected ? _ember : _ash,
                    ),
                  ),
                  if (showBadge)
                    Positioned(
                      right: -2,
                      top: -2,
                      child: Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [_ember, _flame],
                          ),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: _void,
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: _ember.withOpacity(0.5),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            badgeCount > 9 ? '9+' : '$badgeCount',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                label.toUpperCase(),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? _ember : _smoke,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}