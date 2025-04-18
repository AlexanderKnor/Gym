import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/create_training_plan_screen/create_training_plan_provider.dart';
import '../../screens/create_training_plan_screen/training_day_editor_screen.dart';

class CreateTrainingPlanFormWidget extends StatefulWidget {
  const CreateTrainingPlanFormWidget({Key? key}) : super(key: key);

  @override
  _CreateTrainingPlanFormWidgetState createState() =>
      _CreateTrainingPlanFormWidgetState();
}

class _CreateTrainingPlanFormWidgetState
    extends State<CreateTrainingPlanFormWidget> {
  final _formKey = GlobalKey<FormState>();
  final _planNameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _planNameController.addListener(_updatePlanName);
  }

  @override
  void dispose() {
    _planNameController.removeListener(_updatePlanName);
    _planNameController.dispose();
    super.dispose();
  }

  void _updatePlanName() {
    Provider.of<CreateTrainingPlanProvider>(context, listen: false)
        .setPlanName(_planNameController.text);
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<CreateTrainingPlanProvider>(context);

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Planname
            const Text(
              'Trainingsplan Name',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _planNameController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'z.B. Ganzkörperplan, Push/Pull/Legs, ...',
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Bitte gib einen Namen ein';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),

            // Trainingsfrequenz
            const Text(
              'Trainingsfrequenz',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'An wie vielen Tagen pro Woche möchtest du trainieren?',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Slider(
                    value: provider.frequency.toDouble(),
                    min: 1,
                    max: 7,
                    divisions: 6,
                    label:
                        '${provider.frequency} ${provider.frequency == 1 ? "Tag" : "Tage"}',
                    onChanged: (value) => provider.setFrequency(value.round()),
                  ),
                ),
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Theme.of(context).primaryColor,
                  ),
                  child: Center(
                    child: Text(
                      '${provider.frequency}',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Trainingstage
            const Text(
              'Trainingstage',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Du kannst die Namen der Trainingstage anpassen',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: provider.frequency,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Row(
                    children: [
                      Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.blue[100],
                        ),
                        child: Center(
                          child: Text(
                            '${index + 1}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue[800],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextFormField(
                          initialValue: provider.dayNames.length > index
                              ? provider.dayNames[index]
                              : 'Tag ${index + 1}',
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                          ),
                          onChanged: (value) =>
                              provider.setDayName(index, value),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 24),

            // Weiter-Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                key: const Key('next_to_exercises_button'),
                onPressed: () {
                  print("Button gedrückt");
                  if (_formKey.currentState!.validate()) {
                    print("Formular validiert");
                    // Entwurfsplan erstellen
                    provider.createDraftPlan();
                    print(
                        "Entwurfsplan erstellt: ${provider.draftPlan != null}");

                    // Zum Tag-Editor navigieren, dabei den Provider-Wert weitergeben
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChangeNotifierProvider.value(
                          value: provider,
                          child: const TrainingDayEditorScreen(),
                        ),
                      ),
                    );
                  } else {
                    print("Validierung fehlgeschlagen");
                  }
                },
                child: const Text('Weiter zu den Übungen'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
