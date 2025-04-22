// lib/widgets/friend_profile_screen/friend_training_plans_widget.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/friend_profile_screen/friend_profile_provider.dart';
import '../../models/training_plan_screen/training_plan_model.dart';

class FriendTrainingPlansWidget extends StatelessWidget {
  const FriendTrainingPlansWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<FriendProfileProvider>(context);
    final trainingPlans = provider.trainingPlans;

    if (trainingPlans.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.fitness_center,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Keine Trainingspläne verfügbar',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Dein Freund hat noch keine Trainingspläne erstellt',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Trainingspläne',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: trainingPlans.length,
              itemBuilder: (context, index) {
                final plan = trainingPlans[index];
                return _buildTrainingPlanCard(context, plan, plan.isActive);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrainingPlanCard(
      BuildContext context, TrainingPlanModel plan, bool isActive) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      elevation: 2,
      color: isActive ? Colors.blue[50] : null,
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        leading: CircleAvatar(
          backgroundColor: isActive ? Colors.blue : Colors.grey[300],
          child: Icon(
            Icons.fitness_center,
            color: Colors.white,
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                plan.name,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isActive ? Colors.blue[800] : null,
                ),
              ),
            ),
            if (isActive)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.blue,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'AKTIV',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6.0),
          child: Text(
            '${plan.days.length} Trainingstage • ${_getTotalExercises(plan)} Übungen',
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Kopier-Button
            ElevatedButton.icon(
              onPressed: () => _copyTrainingPlan(context, plan),
              icon: const Icon(Icons.copy, size: 16),
              label: const Text('Kopieren'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: () => _showTrainingPlanDetails(context, plan),
              style: ElevatedButton.styleFrom(
                backgroundColor: isActive ? Colors.blue : Colors.grey[200],
                foregroundColor: isActive ? Colors.white : Colors.black87,
              ),
              child: const Text('Details'),
            ),
          ],
        ),
        onTap: () => _showTrainingPlanDetails(context, plan),
      ),
    );
  }

  // Hilfsmethode, um den Profilnamen basierend auf der ID zu erhalten
  String _getProfileNameById(BuildContext context, String profileId) {
    final provider = Provider.of<FriendProfileProvider>(context, listen: false);

    try {
      final profile = provider.progressionProfiles.firstWhere(
        (profile) => profile.id == profileId,
      );
      return profile.name;
    } catch (e) {
      // Wenn kein Profil gefunden wird, geben wir die ID zurück
      return 'Profil: $profileId';
    }
  }

  int _getTotalExercises(TrainingPlanModel plan) {
    int total = 0;
    for (var day in plan.days) {
      total += day.exercises.length;
    }
    return total;
  }

  // Überarbeitete Kopier-Funktion mit verbesserter Dialog-Verwaltung
  void _copyTrainingPlan(BuildContext context, TrainingPlanModel plan) async {
    final provider = Provider.of<FriendProfileProvider>(context, listen: false);

    // Dialog-Kontext zur späteren Verwendung merken
    BuildContext? dialogContext;

    // Zeige Ladeanzeige mit Barrier
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        dialogContext = context;
        return WillPopScope(
          onWillPop: () async => false,
          child: const AlertDialog(
            content: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 20),
                Text('Trainingsplan wird kopiert...'),
              ],
            ),
          ),
        );
      },
    );

    try {
      // Versuche, den Plan zu kopieren
      final result = await provider.copyTrainingPlanToOwnCollection(plan);

      // Dialog schließen - hier mit verbesserten Sicherheitschecks
      if (dialogContext != null && Navigator.canPop(dialogContext!)) {
        Navigator.of(dialogContext!).pop();
      }

      // Kurze Verzögerung, um sicherzustellen, dass der Dialog geschlossen wurde
      await Future.delayed(const Duration(milliseconds: 200));

      // Nur einen neuen Dialog anzeigen, wenn der Kontext noch gültig ist
      if (context.mounted) {
        if (result['success'] == true) {
          final missingProfileIds = result['missingProfileIds'] as List;

          if (missingProfileIds.isNotEmpty) {
            // Es gibt fehlende Profile, frage Benutzer, ob diese kopiert werden sollen
            _showMissingProfilesDialog(
                context, missingProfileIds, plan, result['plan']);
          } else {
            // Erfolg ohne fehlende Profile
            _showSuccessDialog(context, plan);
          }
        } else {
          // Fehler beim Kopieren
          _showErrorDialog(context, result['error'] ?? 'Unbekannter Fehler');
        }
      }
    } catch (e) {
      // Exception abfangen, Dialog schließen und Fehlermeldung anzeigen
      if (dialogContext != null && Navigator.canPop(dialogContext!)) {
        Navigator.of(dialogContext!).pop();
      }

      await Future.delayed(const Duration(milliseconds: 200));

      if (context.mounted) {
        _showErrorDialog(context, e.toString());
      }
    }
  }

  // Dialog für fehlende Profile anzeigen
  void _showMissingProfilesDialog(BuildContext context, List missingProfileIds,
      TrainingPlanModel originalPlan, TrainingPlanModel copiedPlan) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Fehlende Progressionsprofile'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Der Trainingsplan verwendet Progressionsprofile, die in deiner Sammlung fehlen:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Container(
              constraints: const BoxConstraints(maxHeight: 200),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: missingProfileIds.length,
                itemBuilder: (context, index) {
                  final profileId = missingProfileIds[index];
                  return ListTile(
                    leading: const Icon(Icons.warning, color: Colors.orange),
                    title: Text('Profil ID: $profileId'),
                    dense: true,
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Möchtest du diese Profile ebenfalls kopieren?',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              _showSuccessDialog(context, originalPlan,
                  withWarning:
                      'Einige Übungen verwenden Profile, die du nicht kopiert hast.');
            },
            child: const Text('Nein, nur Plan kopieren'),
          ),
          ElevatedButton(
            onPressed: () async {
              // Dialog schließen, bevor der Kopiervorgang startet
              Navigator.of(dialogContext).pop();

              // Kurze Verzögerung einfügen
              await Future.delayed(const Duration(milliseconds: 200));

              // Halten des neuen Dialog-Kontexts
              BuildContext? loadingContext;

              if (context.mounted) {
                // Zeige Ladeanzeige mit Barrier
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (ctx) {
                    loadingContext = ctx;
                    return WillPopScope(
                      onWillPop: () async => false,
                      child: const AlertDialog(
                        content: Row(
                          children: [
                            CircularProgressIndicator(),
                            SizedBox(width: 20),
                            Text('Profile werden kopiert...'),
                          ],
                        ),
                      ),
                    );
                  },
                );
              }

              try {
                // Kopiere fehlende Profile
                final provider =
                    Provider.of<FriendProfileProvider>(context, listen: false);
                final success = await provider.copyMissingProfiles(
                    missingProfileIds.map((id) => id.toString()).toList());

                // Dialog schließen
                if (loadingContext != null &&
                    Navigator.canPop(loadingContext!)) {
                  Navigator.of(loadingContext!).pop();
                }

                await Future.delayed(const Duration(milliseconds: 200));

                // Erfolgs- oder Fehlermeldung anzeigen
                if (context.mounted) {
                  if (success) {
                    _showSuccessDialog(context, originalPlan,
                        withProfiles: true);
                  } else {
                    _showErrorDialog(
                        context,
                        provider.errorMessage ??
                            'Fehler beim Kopieren der Profile');
                  }
                }
              } catch (e) {
                // Exception abfangen, Dialog schließen und Fehlermeldung anzeigen
                if (loadingContext != null &&
                    Navigator.canPop(loadingContext!)) {
                  Navigator.of(loadingContext!).pop();
                }

                await Future.delayed(const Duration(milliseconds: 200));

                if (context.mounted) {
                  _showErrorDialog(context, e.toString());
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
            ),
            child: const Text('Ja, alle kopieren'),
          ),
        ],
      ),
    );
  }

  // Erfolgs-Dialog anzeigen
  void _showSuccessDialog(BuildContext context, TrainingPlanModel plan,
      {String? withWarning, bool withProfiles = false}) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Erfolgreich kopiert'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.check_circle,
              color: Colors.green,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              'Der Trainingsplan "${plan.name}" wurde erfolgreich in deine Sammlung kopiert.',
              textAlign: TextAlign.center,
            ),
            if (withProfiles) ...[
              const SizedBox(height: 12),
              const Text(
                'Alle benötigten Progressionsprofile wurden ebenfalls kopiert.',
                textAlign: TextAlign.center,
                style:
                    TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
              ),
            ],
            if (withWarning != null) ...[
              const SizedBox(height: 12),
              Text(
                withWarning,
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontWeight: FontWeight.bold, color: Colors.orange),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  // Fehler-Dialog anzeigen
  void _showErrorDialog(BuildContext context, String errorMessage) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Fehler'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error,
              color: Colors.red,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              'Beim Kopieren ist ein Fehler aufgetreten:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(errorMessage),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showTrainingPlanDetails(BuildContext context, TrainingPlanModel plan) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.4,
        expand: false,
        builder: (context, scrollController) {
          return SingleChildScrollView(
            controller: scrollController,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          plan.name,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (plan.isActive)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.blue,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'AKTIV',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Kopier-Button im Detail-Bereich
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(context); // Schließe Details
                            _copyTrainingPlan(
                                context, plan); // Starte Kopier-Prozess
                          },
                          icon: const Icon(Icons.copy),
                          label: const Text('In meine Sammlung kopieren'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 8),

                  // Trainingstage und Übungen anzeigen
                  for (int i = 0; i < plan.days.length; i++) ...[
                    _buildDayDetails(context, plan.days[i], i),
                    if (i < plan.days.length - 1) const Divider(),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDayDetails(BuildContext context, day, int index) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: Colors.blue[200],
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '${index + 1}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[800],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                day.name,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Übungen des Tages
          for (int i = 0; i < day.exercises.length; i++)
            Padding(
              padding: const EdgeInsets.only(left: 36, bottom: 8),
              child: Card(
                margin: EdgeInsets.zero,
                elevation: 0,
                color: Colors.grey[100],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              day.exercises[i].name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.blue[100],
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '${day.exercises[i].numberOfSets}×',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue[800],
                              ),
                            ),
                          ),
                          // Zeige Profil-Information an
                          if (day.exercises[i].progressionProfileId != null &&
                              day.exercises[i].progressionProfileId!
                                  .isNotEmpty) ...[
                            const SizedBox(width: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.purple[100],
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.trending_up,
                                    size: 12,
                                    color: Colors.purple[800],
                                  ),
                                  const SizedBox(width: 2),
                                  Text(
                                    _getProfileNameById(context,
                                        day.exercises[i].progressionProfileId!),
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.purple[800],
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                      if (day.exercises[i].primaryMuscleGroup.isNotEmpty ||
                          day.exercises[i].secondaryMuscleGroup.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          _getMuscleGroups(day.exercises[i]),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.timer, size: 12, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Text(
                            '${day.exercises[i].restPeriodSeconds}s Pause',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(Icons.trending_up,
                              size: 12, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Text(
                            '+${day.exercises[i].standardIncrease}kg',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
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

  String _getMuscleGroups(exercise) {
    List<String> groups = [];
    if (exercise.primaryMuscleGroup.isNotEmpty) {
      groups.add(exercise.primaryMuscleGroup);
    }
    if (exercise.secondaryMuscleGroup.isNotEmpty) {
      groups.add(exercise.secondaryMuscleGroup);
    }
    return groups.join(' • ');
  }
}
