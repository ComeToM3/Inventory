import 'package:flutter/material.dart';

import 'app_strings.dart';

Future<bool> confirmDiscardChanges(
  BuildContext context, {
  required String title,
}) async =>
    await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: const Text(AppStrings.discardMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(AppStrings.continueEditing),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(AppStrings.discard),
          ),
        ],
      ),
    ) ==
    true;
