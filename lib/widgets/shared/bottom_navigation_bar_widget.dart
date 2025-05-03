// lib/widgets/shared/bottom_navigation_bar_widget.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/shared/navigation_provider.dart';
import '../../providers/profile_screen/friendship_provider.dart';

class BottomNavigationBarWidget extends StatelessWidget {
  const BottomNavigationBarWidget({super.key});

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
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildNavItem(
                context: context,
                icon: Icons.fitness_center_rounded,
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
                icon: Icons.trending_up_rounded,
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
                icon: Icons.calendar_today_rounded,
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
                    icon: Icons.person_rounded,
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
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.grey[100] : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              children: [
                Icon(
                  icon,
                  size: 24,
                  color: isSelected ? Colors.black : Colors.grey[400],
                ),
                if (showBadge)
                  Positioned(
                    right: -2,
                    top: -2,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.white,
                          width: 1.5,
                        ),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Text(
                        badgeCount > 9 ? '9+' : '$badgeCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected ? Colors.black : Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
