import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'app_strings.dart';
import 'inventory_thumb_layout.dart';

/// Compact about / privacy / licenses page (DEV-30).
class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  PackageInfo? _info;

  @override
  void initState() {
    super.initState();
    PackageInfo.fromPlatform().then((info) {
      if (mounted) setState(() => _info = info);
    });
  }

  @override
  Widget build(BuildContext context) {
    final info = _info;
    final versionLine = info == null
        ? AppStrings.aboutVersionUnavailable
        : AppStrings.aboutVersionLine(info.version, info.buildNumber);
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.aboutTitle)),
      body: SafeArea(
        child: InventoryThumbBody(
          children: [
            Text(AppStrings.appTitle, style: textTheme.headlineSmall),
            const SizedBox(height: 6),
            Text(versionLine, style: textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(
              AppStrings.aboutPublisher,
              style: textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            Text(AppStrings.aboutDescription, style: textTheme.bodyLarge),
            const SizedBox(height: 24),
            Text(AppStrings.aboutLocalTitle, style: textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(AppStrings.aboutLocalBody, style: textTheme.bodyMedium),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: () {
                showLicensePage(
                  context: context,
                  applicationName: AppStrings.appTitle,
                  applicationVersion: info == null
                      ? null
                      : '${info.version}+${info.buildNumber}',
                  applicationLegalese: AppStrings.aboutPublisher,
                );
              },
              icon: const Icon(Icons.balance_outlined),
              label: const Text(AppStrings.aboutLicenses),
            ),
          ],
        ),
      ),
    );
  }
}
