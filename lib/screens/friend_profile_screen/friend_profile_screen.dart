import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/profile_screen/friendship_model.dart';
import '../../providers/friend_profile_screen/friend_profile_provider.dart';
import '../../widgets/friend_profile_screen/friend_training_plans_widget.dart';
import '../../widgets/friend_profile_screen/friend_progression_profiles_widget.dart';

class FriendProfileScreen extends StatefulWidget {
  final FriendshipModel friendship;

  const FriendProfileScreen({
    Key? key,
    required this.friendship,
  }) : super(key: key);

  @override
  State<FriendProfileScreen> createState() => _FriendProfileScreenState();
}

class _FriendProfileScreenState extends State<FriendProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (_tabController.index != _selectedTabIndex) {
        setState(() {
          _selectedTabIndex = _tabController.index;
        });
      }
    });

    // Daten beim Öffnen des Bildschirms laden
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadFriendData();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadFriendData() async {
    final provider = Provider.of<FriendProfileProvider>(context, listen: false);
    await provider.loadFriendData(widget.friendship);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Profil von ${widget.friendship.friendUsername}'),
        bottom: _buildTabBar(),
      ),
      body: _buildBody(),
    );
  }

  PreferredSizeWidget? _buildTabBar() {
    final provider = Provider.of<FriendProfileProvider>(context);

    if (!provider.isTabViewEnabled) {
      return null;
    }

    return TabBar(
      controller: _tabController,
      tabs: const [
        Tab(
          icon: Icon(Icons.fitness_center),
          text: 'Trainingspläne',
        ),
        Tab(
          icon: Icon(Icons.trending_up),
          text: 'Progressionsprofile',
        ),
      ],
    );
  }

  Widget _buildBody() {
    final provider = Provider.of<FriendProfileProvider>(context);

    if (provider.isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (provider.errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red[300],
            ),
            const SizedBox(height: 16),
            Text(
              'Fehler beim Laden',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.red[700],
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                provider.errorMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey[600],
                ),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadFriendData,
              child: const Text('Erneut versuchen'),
            ),
          ],
        ),
      );
    }

    if (!provider.isTabViewEnabled) {
      return _buildInitialView();
    }

    return TabBarView(
      controller: _tabController,
      children: const [
        // Trainingspläne
        FriendTrainingPlansWidget(),

        // Progressionsprofile
        FriendProgressionProfilesWidget(),
      ],
    );
  }

  Widget _buildInitialView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 50,
            backgroundColor: Colors.blue,
            child: Text(
              widget.friendship.friendUsername.isNotEmpty
                  ? widget.friendship.friendUsername
                      .substring(0, 1)
                      .toUpperCase()
                  : '?',
              style: const TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            widget.friendship.friendUsername,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.friendship.friendEmail,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: _loadFriendData,
            icon: const Icon(Icons.refresh),
            label: const Text('Daten laden'),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(200, 48),
            ),
          ),
        ],
      ),
    );
  }
}
