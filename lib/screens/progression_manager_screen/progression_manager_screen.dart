import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui'; // Import für BackdropFilter
import 'package:provider/provider.dart';
import '../../providers/progression_manager_screen/progression_manager_provider.dart';
import 'profile_detail_screen.dart';
import 'profile_editor_screen.dart';

class ProgressionManagerScreen extends StatelessWidget {
  const ProgressionManagerScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final provider =
        Provider.of<ProgressionManagerProvider>(context, listen: false);
    return ChangeNotifierProvider.value(
      value: provider,
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
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ));

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
    final isTablet = MediaQuery.of(context).size.width > 600;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Progressionsprofile',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: Colors.black,
              letterSpacing: -0.3,
            )),
        centerTitle: false,
        elevation: 0,
        backgroundColor: Colors.white,
        shadowColor: Colors.black.withOpacity(0.05),
        systemOverlayStyle: SystemUiOverlayStyle.dark,
      ),
      body: RefreshIndicator(
        color: Colors.black,
        strokeWidth: 2,
        onRefresh: () => _loadProfiles(provider),
        child: _isLoading
            ? Center(
                child: CircularProgressIndicator(
                  color: Colors.black,
                  strokeWidth: 2,
                  backgroundColor: Colors.grey[100],
                ),
              )
            : profiles.isEmpty
                ? _buildEmptyState()
                : _buildProfileGrid(profiles, isTablet),
      ),
      bottomSheet: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: () => _createNewProfile(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.add_rounded,
                  size: 20,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Neues Profil',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                Icons.insights,
                size: 28,
                color: Colors.grey[400],
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Keine Profile',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Erstelle ein Profil, um deine Trainingsprogression zu optimieren',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                letterSpacing: -0.3,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileGrid(List<dynamic> profiles, bool isTablet) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
      child: isTablet
          // Grid für Tablet
          ? GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 1.2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: profiles.length,
              itemBuilder: (context, index) {
                final profile = profiles[index];
                return ProfileCard(
                  profile: profile,
                  onTap: () => _openProfileDetail(context, profile),
                  onDemo: () => _openProfileDemo(context, profile),
                  isCompact: true,
                );
              },
            )
          // Liste für Smartphone
          : ListView.builder(
              padding: EdgeInsets.zero,
              itemCount: profiles.length,
              itemBuilder: (context, index) {
                final profile = profiles[index];
                return ProfileCard(
                  profile: profile,
                  onTap: () => _openProfileDetail(context, profile),
                  onDemo: () => _openProfileDemo(context, profile),
                  isCompact: false,
                );
              },
            ),
    );
  }

  void _openProfileDetail(BuildContext context, dynamic profile) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ProfileDetailScreen(profile: profile),
      ),
    );
  }

  void _openProfileDemo(BuildContext context, dynamic profile) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ProfileDetailScreen(
          profile: profile,
          initialTab: 1,
        ),
      ),
    );
  }

  void _createNewProfile(BuildContext context) {
    final provider =
        Provider.of<ProgressionManagerProvider>(context, listen: false);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.all(20),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header mit Titel
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.add_rounded,
                        color: Colors.black,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Neues Profil erstellen',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close, size: 22),
                      onPressed: () => Navigator.of(context).pop(),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Option 1: Leeres Profil
                _buildOptionButton(
                  icon: Icons.note_add_outlined,
                  label: 'Leeres Profil erstellen',
                  onTap: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const NewProfileScreen(),
                      ),
                    );
                  },
                  isPrimary: false,
                ),

                const SizedBox(height: 12),

                // Option 2: Duplizieren
                _buildOptionButton(
                  icon: Icons.content_copy_rounded,
                  label: 'Bestehendes Profil duplizieren',
                  onTap: () {
                    Navigator.of(context).pop();
                    _showProfileSelectionSheet(context, provider);
                  },
                  isPrimary: true,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOptionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required bool isPrimary,
  }) {
    return Material(
      color: isPrimary ? Colors.black : Colors.grey[100],
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          child: Row(
            children: [
              Icon(
                icon,
                size: 18,
                color: isPrimary ? Colors.white : Colors.grey[800],
              ),
              const SizedBox(width: 12),
              Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  letterSpacing: -0.3,
                  color: isPrimary ? Colors.white : Colors.grey[800],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showProfileSelectionSheet(
      BuildContext context, ProgressionManagerProvider provider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.7,
          ),
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 8, 0),
                child: Row(
                  children: [
                    const Text(
                      'Profil auswählen',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close, size: 22),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),

              const Divider(height: 16),

              // Liste der Profile
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: provider.progressionsProfile.length,
                  itemBuilder: (context, index) {
                    final profile = provider.progressionsProfile[index];
                    final bool isSystemProfile = _isStandardProfile(profile.id);

                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 4,
                        horizontal: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      leading: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: isSystemProfile
                              ? Colors.blue[50]
                              : Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          isSystemProfile
                              ? Icons.verified_outlined
                              : Icons.settings_outlined,
                          size: 18,
                          color: isSystemProfile
                              ? Colors.blue[700]
                              : Colors.grey[700],
                        ),
                      ),
                      title: Text(
                        profile.name,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          letterSpacing: -0.3,
                        ),
                      ),
                      subtitle: Text(
                        profile.description,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                        ),
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () {
                        Navigator.of(context).pop();
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) =>
                                DuplicateProfileScreen(profileId: profile.id),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool _isStandardProfile(String profileId) {
    return profileId == 'double-progression' ||
        profileId == 'linear-periodization' ||
        profileId == 'rir-based' ||
        profileId == 'set-consistency';
  }
}

class ProfileCard extends StatelessWidget {
  final dynamic profile;
  final VoidCallback onTap;
  final VoidCallback onDemo;
  final bool isCompact;

  const ProfileCard({
    Key? key,
    required this.profile,
    required this.onTap,
    required this.onDemo,
    this.isCompact = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bool isSystemProfile = _isStandardProfile(profile.id);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header mit Badges und Aktionen
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 6, 0),
            child: Row(
              children: [
                // Badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: isSystemProfile ? Colors.blue[50] : Colors.grey[100],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    isSystemProfile ? 'Standard' : 'Benutzerdefiniert',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color:
                          isSystemProfile ? Colors.blue[700] : Colors.grey[700],
                    ),
                  ),
                ),

                const Spacer(),

                // Aktionen
                if (!isSystemProfile)
                  _buildIconButton(
                    icon: Icons.delete_outline,
                    onTap: () => _confirmDeleteProfile(context, profile),
                  ),
                _buildIconButton(
                  icon: Icons.edit_outlined,
                  onTap: onTap,
                ),
              ],
            ),
          ),

          // Hauptinhalt
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 6, 14, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name
                Text(
                  profile.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.3,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),

                const SizedBox(height: 4),

                // Beschreibung
                Text(
                  profile.description,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
                  maxLines: isCompact ? 1 : 2,
                  overflow: TextOverflow.ellipsis,
                ),

                const SizedBox(height: 10),

                // Konfiguration mit Icons (nur für Regeln)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Wiederholungen (ohne Icon)
                    _buildConfigItem(
                      value:
                          '${profile.config['targetRepsMin']}-${profile.config['targetRepsMax']}',
                      label: 'Wdh',
                      showIcon: false,
                    ),
                    // RIR (ohne Icon)
                    _buildConfigItem(
                      value:
                          '${profile.config['targetRIRMin']}-${profile.config['targetRIRMax']}',
                      label: 'RIR',
                      showIcon: false,
                    ),
                    // Regeln (mit Icon)
                    _buildConfigItem(
                      icon: Icons.rule_rounded,
                      value: '${profile.rules.length}',
                      label: 'Regeln',
                      showIcon: true,
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Demo-Button
          Material(
            color: Colors.grey[100],
            child: InkWell(
              onTap: onDemo,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(color: Colors.grey[200]!),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.play_circle_outline,
                      size: 16,
                      color: Colors.grey[800],
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Demo testen',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[800],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIconButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return IconButton(
      icon: Icon(icon, size: 18),
      onPressed: onTap,
      visualDensity: VisualDensity.compact,
      padding: const EdgeInsets.all(6),
      constraints: const BoxConstraints(),
      splashRadius: 20,
    );
  }

  Widget _buildConfigItem({
    IconData? icon,
    required String value,
    required String label,
    required bool showIcon,
  }) {
    return Column(
      children: [
        // Nur ein Text oder Row mit Icon + Text, je nach showIcon Parameter
        if (showIcon && icon != null)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 14,
                color: Colors.grey[600],
              ),
              const SizedBox(width: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          )
        else
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey[500],
          ),
        ),
      ],
    );
  }

  bool _isStandardProfile(String profileId) {
    return profileId == 'double-progression' ||
        profileId == 'linear-periodization' ||
        profileId == 'rir-based' ||
        profileId == 'set-consistency';
  }

  void _confirmDeleteProfile(BuildContext context, dynamic profile) {
    final provider =
        Provider.of<ProgressionManagerProvider>(context, listen: false);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.red[50],
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.delete_outline,
                        color: Colors.red[700],
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Profil löschen',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Möchtest du das Profil "${profile.name}" wirklich löschen?',
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    // Löschen-Button (jetzt links)
                    Expanded(
                      child: TextButton(
                        onPressed: () async {
                          Navigator.of(context).pop();
                          await provider.deleteProfile(profile.id);
                        },
                        style: TextButton.styleFrom(
                          backgroundColor: Colors.red[600],
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text(
                          'Löschen',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Abbrechen-Button (jetzt rechts)
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: TextButton.styleFrom(
                          backgroundColor: Colors.grey[100],
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text(
                          'Abbrechen',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class DuplicateProfileScreen extends StatefulWidget {
  final String profileId;

  const DuplicateProfileScreen({
    Key? key,
    required this.profileId,
  }) : super(key: key);

  @override
  State<DuplicateProfileScreen> createState() => _DuplicateProfileScreenState();
}

class _DuplicateProfileScreenState extends State<DuplicateProfileScreen> {
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider =
          Provider.of<ProgressionManagerProvider>(context, listen: false);
      provider.duplicateProfile(widget.profileId);
      setState(() {
        _isInitialized = true;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return Scaffold(
        appBar: AppBar(
          title: const Text(
            'Profil duplizieren',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: Colors.black,
              letterSpacing: -0.3,
            ),
          ),
          centerTitle: false,
          backgroundColor: Colors.white,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.black),
        ),
        body: const Center(
          child: CircularProgressIndicator(
            color: Colors.black,
            strokeWidth: 2,
          ),
        ),
      );
    }

    return const ProfileEditorScreen();
  }
}

class NewProfileScreen extends StatefulWidget {
  const NewProfileScreen({Key? key}) : super(key: key);

  @override
  State<NewProfileScreen> createState() => _NewProfileScreenState();
}

class _NewProfileScreenState extends State<NewProfileScreen> {
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider =
          Provider.of<ProgressionManagerProvider>(context, listen: false);
      provider.openProfileEditor(null);
      setState(() {
        _isInitialized = true;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return Scaffold(
        appBar: AppBar(
          title: const Text(
            'Neues Profil',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: Colors.black,
              letterSpacing: -0.3,
            ),
          ),
          centerTitle: false,
          backgroundColor: Colors.white,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.black),
        ),
        body: const Center(
          child: CircularProgressIndicator(
            color: Colors.black,
            strokeWidth: 2,
          ),
        ),
      );
    }

    return const ProfileEditorScreen();
  }
}
