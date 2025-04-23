import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/progression_manager_screen/progression_manager_provider.dart';
import '../../widgets/progression_manager_screen/components/profile_card_widget.dart';
import 'profile_detail_screen.dart';
import 'profile_editor_screen.dart';

class ProgressionManagerScreen extends StatelessWidget {
  const ProgressionManagerScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => ProgressionManagerProvider(),
      child: const ProgressionManagerScreenContent(),
    );
  }
}

class ProgressionManagerScreenContent extends StatefulWidget {
  const ProgressionManagerScreenContent({Key? key}) : super(key: key);

  @override
  State<ProgressionManagerScreenContent> createState() =>
      _ProgressionManagerScreenContentState();
}

class _ProgressionManagerScreenContentState
    extends State<ProgressionManagerScreenContent> {
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Profile beim Start laden
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider =
          Provider.of<ProgressionManagerProvider>(context, listen: false);
      _loadProfiles(provider);
    });
  }

  Future<void> _loadProfiles(ProgressionManagerProvider provider) async {
    setState(() {
      _isLoading = true;
    });

    await provider.refreshProfiles();

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ProgressionManagerProvider>(context);
    final profiles = provider.progressionsProfile;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Progressionsprofile'),
      ),
      body: RefreshIndicator(
        onRefresh: () => _loadProfiles(provider),
        child: Column(
          children: [
            // Header mit Erklärung
            Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.purple[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.purple[100]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.trending_up, color: Colors.purple[700]),
                      const SizedBox(width: 8),
                      const Text(
                        'Progressionsprofile',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.deepPurple,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Hier kannst du deine Progressionsprofile verwalten. Klicke auf ein Profil, um es zu bearbeiten oder zu testen.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),

            // Profile-Liste
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : profiles.isEmpty
                      ? _buildEmptyProfilesView()
                      : _buildProfilesList(context, profiles),
            ),
          ],
        ),
      ),
      // Floating Action Button zum Erstellen eines neuen Profils
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _createNewProfile(context),
        icon: const Icon(Icons.add),
        label: const Text('Neues Profil'),
        backgroundColor: Colors.purple,
      ),
    );
  }

  Widget _buildEmptyProfilesView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.trending_up,
            size: 80,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 16),
          Text(
            'Keine Progressionsprofile vorhanden',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Erstelle dein erstes Profil mit dem Button unten',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfilesList(BuildContext context, List<dynamic> profiles) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: profiles.length,
      itemBuilder: (context, index) {
        final profile = profiles[index];
        return ProfileCardWidget(
          profile: profile,
          onTap: () => _openProfileDetail(context, profile),
          onDemo: () => _openProfileDemo(context, profile),
        );
      },
    );
  }

  // Methode zum Öffnen des Profildetails
  void _openProfileDetail(BuildContext context, dynamic profile) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ProfileDetailScreen(profile: profile),
      ),
    );
  }

  // Methode zum Öffnen der Demo für ein Profil
  void _openProfileDemo(BuildContext context, dynamic profile) {
    final provider =
        Provider.of<ProgressionManagerProvider>(context, listen: false);

    // Profil für die Demo aktivieren
    provider.wechsleProgressionsProfil(profile.id);

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ProfileDetailScreen(
          profile: profile,
          initialTab: 1, // Tab-Index für Demo
        ),
      ),
    );
  }

  // Korrigierte Methode zum Erstellen eines neuen Profils
  void _createNewProfile(BuildContext context) {
    // Erst zum Screen navigieren
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const NewProfileScreen(),
      ),
    );
  }
}

// Neuer Hilfsscreen zum Erstellen eines neuen Profils
class NewProfileScreen extends StatefulWidget {
  const NewProfileScreen({Key? key}) : super(key: key);

  @override
  State<NewProfileScreen> createState() => _NewProfileScreenState();
}

class _NewProfileScreenState extends State<NewProfileScreen> {
  @override
  void initState() {
    super.initState();

    // Nach dem ersten Build den Editor öffnen
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider =
          Provider.of<ProgressionManagerProvider>(context, listen: false);
      provider.openProfileEditor(null);
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ProgressionManagerProvider>(context);
    final profil = provider.bearbeitetesProfil;

    // Solange das Profil noch nicht erstellt wurde, zeige einen Ladebildschirm
    if (profil == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Neues Profil'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Profil wird erstellt...'),
            ],
          ),
        ),
      );
    }

    // Sobald das Profil erstellt wurde, zeige den Editor
    return ProfileEditorScreen();
  }
}
