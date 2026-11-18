import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../core/backup/backup_contract.dart';
import '../core/backup/backup_exporter.dart';
import '../core/backup/restoration_recovery.dart';
import '../core/database/inventory_database.dart';
import '../core/domain/inventory_engine.dart';
import 'app_strings.dart';
import 'app_theme.dart';
import 'main_navigation_screen.dart';

class InventoryApp extends StatefulWidget {
  const InventoryApp({super.key, required this.database});

  final InventoryDatabase database;

  @override
  State<InventoryApp> createState() => _InventoryAppState();
}

class _InventoryAppState extends State<InventoryApp> {
  late final InventoryDatabase _database;
  late InventoryEngine _engine;
  RestorationRecoveryState? _recovery;
  bool _recoveryBlocking = false;
  bool _booting = true;

  @override
  void initState() {
    super.initState();
    _database = widget.database;
    _engine = InventoryEngine(_database);
    unawaited(_boot());
  }

  Future<void> _boot() async {
    unawaited(BackupExporter.cleanupOrphanTemps());
    try {
      final recovery = await RestorationRecovery(_database).inspect();
      if (!mounted) return;
      setState(() {
        _recovery = recovery;
        _recoveryBlocking =
            recovery?.messageKind == RestorationRecoveryMessage.unreliable;
        _booting = false;
      });
    } on Exception {
      if (!mounted) return;
      setState(() {
        _recovery = const RestorationRecoveryState(
          status: RestorationJournalStatus.pending,
          operationId: 'unknown',
          messageKind: RestorationRecoveryMessage.unreliable,
        );
        _recoveryBlocking = true;
        _booting = false;
      });
    }
  }

  Future<void> _acknowledgeRecovery() async {
    final recovery = _recovery;
    if (recovery == null) return;
    if (recovery.messageKind == RestorationRecoveryMessage.unreliable) {
      return;
    }
    await RestorationRecovery(_database).acknowledge(recovery);
    if (!mounted) return;
    setState(() => _recovery = null);
  }

  Future<void> _retryBoot() async {
    if (_booting) return;
    setState(() {
      _booting = true;
      _recovery = null;
      _recoveryBlocking = false;
    });
    await _boot();
  }

  Future<void> _onInventoryRestored() async {
    // Tree controllers are owned by MainNavigationScreen and reset there.
  }

  @override
  void dispose() {
    unawaited(_closeDatabase());
    super.dispose();
  }

  Future<void> _closeDatabase() async {
    try {
      await _database.close();
    } on Exception {
      debugPrint('Impossible de fermer la base locale.');
    }
  }

  String _recoveryMessage(RestorationRecoveryState state) =>
      switch (state.messageKind) {
        RestorationRecoveryMessage.notApplied => AppStrings.recoveryNotApplied,
        RestorationRecoveryMessage.completed => AppStrings.recoveryCompleted,
        RestorationRecoveryMessage.unreliable => AppStrings.recoveryUnreliable,
      };

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppStrings.appTitle,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      locale: const Locale('fr'),
      supportedLocales: const [Locale('fr')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      home: _booting
          ? const Scaffold(body: Center(child: CircularProgressIndicator()))
          : _recovery != null
          ? Scaffold(
              body: SafeArea(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _recoveryMessage(_recovery!),
                          textAlign: TextAlign.center,
                        ),
                        if (_recoveryBlocking) ...[
                          const SizedBox(height: 24),
                          FilledButton(
                            onPressed: () => unawaited(_retryBoot()),
                            child: const Text(AppStrings.retry),
                          ),
                        ] else ...[
                          const SizedBox(height: 24),
                          FilledButton(
                            onPressed: () => unawaited(_acknowledgeRecovery()),
                            child: const Text(AppStrings.recoveryAcknowledge),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            )
          : MainNavigationScreen(
              engine: _engine,
              database: _database,
              onInventoryRestored: _onInventoryRestored,
            ),
    );
  }
}
