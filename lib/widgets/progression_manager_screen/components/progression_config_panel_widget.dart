import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/progression_manager_screen/progression_manager_provider.dart';
import 'profile_selector_widget.dart';
import 'profile_config_widget.dart';
import 'rule_list_widget.dart';

class ProgressionConfigPanelWidget extends StatelessWidget {
  const ProgressionConfigPanelWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.purple[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.purple[100]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text(
            'Progressions-Manager',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 16),

          // Profilauswahl
          ProfileSelectorWidget(),
          SizedBox(height: 16),

          // Profilkonfiguration
          ProfileConfigWidget(),
          SizedBox(height: 16),

          // Regelliste
          RuleListWidget(),
        ],
      ),
    );
  }
}
