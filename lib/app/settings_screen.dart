import 'dart:async';

import 'package:flutter/material.dart';

import '../core/backup/backup_contract.dart';
import '../core/database/inventory_database.dart';
import 'about_screen.dart';
import 'app_strings.dart';
import 'backup_export_controller.dart';
import 'backup_restore_controller.dart';
import 'help_screen.dart';
import 'inventory_messages.dart';
import 'inventory_thumb_layout.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({
    super.key,
    required this.database,
    this.onInventoryRestored,
  });

  final InventoryDatabase database;
  final Future<void> Function()? onInventoryRestored;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final BackupExportController _export;
  late final BackupRestoreController _restore;

  @override
  void initState() {
    super.initState();
    _export = BackupExportController(widget.database);
    _restore = BackupRestoreController(widget.database);
  }

  @override
  void dispose() {
    _export.dispose();
    _restore.dispose();
    super.dispose();
  }

  bool get _busy => _export.exporting || _restore.busy;

  Future<void> _startExport() async {
    if (_busy) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        var answered = false;
        void answer(bool value) {
          if (answered) return;
          answered = true;
          Navigator.pop(context, value);
        }

        return AlertDialog(
          title: const Text(AppStrings.backupPrivacyTitle),
          content: const SingleChildScrollView(
            child: Text(AppStrings.backupPrivacyMessage),
          ),
          actions: [
            TextButton(
              onPressed: () => answer(false),
              child: const Text(AppStrings.cancel),
            ),
            FilledButton(
              onPressed: () => answer(true),
              child: const Text(AppStrings.backupContinue),
            ),
          ],
        );
      },
    );
    if (!mounted || confirmed != true) return;
    await _export.export();
    if (!mounted) return;
    final message = _export.statusMessage;
    if (message != null) showInventoryMessage(context, message);
  }

  Future<void> _startRestore() async {
    if (_busy) return;
    final result = await _restore.restore(
      confirm: (summary) async {
        if (!mounted) return false;
        var answered = false;
        void answer(BuildContext dialogContext, bool value) {
          if (answered) return;
          answered = true;
          Navigator.pop(dialogContext, value);
        }

        final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text(AppStrings.restoreConfirmTitle),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(AppStrings.restoreConfirmLead),
                  const SizedBox(height: 16),
                  Text(
                    AppStrings.restoreSummary(
                      createdAtUtc: summary.createdAtUtc,
                      nodeCount: summary.nodeCount,
                      withdrawnCount: summary.withdrawnCount,
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => answer(context, false),
                child: const Text(AppStrings.cancel),
              ),
              FilledButton(
                onPressed: () => answer(context, true),
                style: FilledButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.error,
                  foregroundColor: Theme.of(context).colorScheme.onError,
                ),
                child: const Text(AppStrings.restoreConfirmAction),
              ),
            ],
          ),
        );
        return confirmed == true;
      },
    );
    if (!mounted) return;
    if (result.outcome == BackupRestoreOutcome.success) {
      await widget.onInventoryRestored?.call();
    }
    if (!mounted) return;
    final message = _restore.statusMessage;
    if (message != null) showInventoryMessage(context, message);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_export, _restore]),
      builder: (context, _) {
        final exportMessage = _export.statusMessage;
        final restoreMessage = _restore.statusMessage;
        return Scaffold(
          appBar: AppBar(title: const Text(AppStrings.settings)),
          body: SafeArea(
            child: InventoryThumbBody(
              footer: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  FilledButton(
                    onPressed: _busy ? null : () => unawaited(_startExport()),
                    child: Text(
                      _export.exporting
                          ? AppStrings.backupExporting
                          : AppStrings.saveInventory,
                    ),
                  ),
                  const SizedBox(height: 12),
                  FilledButton.tonal(
                    onPressed:
                        _busy ? null : () => unawaited(_startRestore()),
                    child: Text(
                      _restore.busy
                          ? (_restore.pendingSummary == null
                                ? AppStrings.restoreValidating
                                : AppStrings.restoreApplying)
                          : AppStrings.restoreInventory,
                    ),
                  ),
                  if (_busy)
                    const Padding(
                      padding: EdgeInsets.only(top: 16),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  if (restoreMessage != null &&
                      (_restore.lastResult?.outcome ==
                              BackupRestoreOutcome.failed ||
                          _restore.lastResult?.outcome ==
                              BackupRestoreOutcome.rejected))
                    TextButton(
                      onPressed:
                          _busy ? null : () => unawaited(_startRestore()),
                      child: const Text(AppStrings.restoreRetry),
                    ),
                ],
              ),
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.help_outline),
                  title: const Text(AppStrings.help),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.of(context).push<void>(
                      MaterialPageRoute(builder: (_) => const HelpScreen()),
                    );
                  },
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.info_outline),
                  title: const Text(AppStrings.about),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.of(context).push<void>(
                      MaterialPageRoute(builder: (_) => const AboutScreen()),
                    );
                  },
                ),
                const SizedBox(height: 8),
                const Divider(),
                const SizedBox(height: 16),
                Text(
                  AppStrings.saveInventory,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  AppStrings.backupPrivacyMessage,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                if (exportMessage != null) ...[
                  const SizedBox(height: 16),
                  Text(exportMessage),
                ],
                const SizedBox(height: 24),
                Text(
                  AppStrings.restoreInventory,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  AppStrings.restoreHelp,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                if (restoreMessage != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    restoreMessage,
                    style: TextStyle(
                      color: switch (_restore.lastResult?.outcome) {
                        BackupRestoreOutcome.failed ||
                        BackupRestoreOutcome.rejected =>
                          Theme.of(context).colorScheme.error,
                        _ => Theme.of(context).colorScheme.primary,
                      },
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
