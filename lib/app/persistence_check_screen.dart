import 'dart:async';

import 'package:flutter/material.dart';

import 'app_strings.dart';
import 'persistence_check_controller.dart';

const _contentPadding = 16.0;
const _spacing = 16.0;

class PersistenceCheckScreen extends StatefulWidget {
  const PersistenceCheckScreen({super.key, required this.controller});

  final PersistenceCheckController controller;

  @override
  State<PersistenceCheckScreen> createState() => _PersistenceCheckScreenState();
}

class _PersistenceCheckScreenState extends State<PersistenceCheckScreen> {
  final _valueController = TextEditingController();

  @override
  void dispose() {
    _valueController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) {
        final controller = widget.controller;
        return Scaffold(
          appBar: AppBar(title: const Text(AppStrings.screenTitle)),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(_contentPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(AppStrings.description),
                  const SizedBox(height: _spacing),
                  if (controller.loading) ...[
                    const CircularProgressIndicator(),
                    const SizedBox(height: _spacing),
                    const Text(AppStrings.loading),
                  ] else if (controller.ready) ...[
                    const Text(AppStrings.databaseReady),
                    const SizedBox(height: _spacing),
                    if (controller.savedValue case final value?) ...[
                      const Text(AppStrings.savedValueLabel),
                      SelectableText(value),
                    ] else
                      const Text(AppStrings.noSavedValue),
                    const SizedBox(height: _spacing),
                    TextField(
                      controller: _valueController,
                      enabled: !controller.saving,
                      decoration: const InputDecoration(
                        labelText: AppStrings.inputLabel,
                      ),
                    ),
                    const SizedBox(height: _spacing),
                    FilledButton(
                      onPressed: controller.saving
                          ? null
                          : () => unawaited(
                              controller.save(_valueController.text),
                            ),
                      child: Text(
                        controller.saving ? AppStrings.saving : AppStrings.save,
                      ),
                    ),
                  ],
                  if (controller.message case final message?) ...[
                    const SizedBox(height: _spacing),
                    Text(message),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
