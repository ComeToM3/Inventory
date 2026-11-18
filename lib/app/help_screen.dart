import 'package:flutter/material.dart';

import 'app_strings.dart';

/// Short in-app help (DEV-30). No onboarding, no network.
class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.helpTitle)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          children: [
            Text(AppStrings.helpIntro, style: textTheme.bodyMedium),
            const SizedBox(height: 20),
            _HelpSection(
              title: AppStrings.helpOrgTitle,
              body: AppStrings.helpOrgBody,
            ),
            _HelpSection(
              title: AppStrings.helpBrowseTitle,
              body: AppStrings.helpBrowseBody,
            ),
            _HelpSection(
              title: AppStrings.helpMoveTitle,
              body: AppStrings.helpMoveBody,
            ),
            _HelpSection(
              title: AppStrings.helpManageTitle,
              body: AppStrings.helpManageBody,
            ),
            _HelpSection(
              title: AppStrings.helpBackupTitle,
              body: AppStrings.helpBackupBody,
            ),
          ],
        ),
      ),
    );
  }
}

class _HelpSection extends StatelessWidget {
  const _HelpSection({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(body, style: textTheme.bodyMedium),
        ],
      ),
    );
  }
}
