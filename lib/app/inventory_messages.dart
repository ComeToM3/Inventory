import 'dart:async';

import 'package:flutter/material.dart';

import 'app_strings.dart';

/// Shows a brief message under the AppBar so bottom actions stay free.
void showInventoryMessage(BuildContext context, String message) {
  showInventoryMessageOn(
    ScaffoldMessenger.of(context),
    MediaQuery.of(context),
    message,
  );
}

/// Same as [showInventoryMessage] when the route is about to pop.
///
/// Uses [MaterialBanner] (not a floating [SnackBar] with a huge bottom margin):
/// the previous SnackBar layout reported a near-fullscreen semantics region
/// even though the visible bar was compact (UI-005).
///
/// The [media] argument is kept for call-site compatibility with the prior API.
void showInventoryMessageOn(
  ScaffoldMessengerState messenger,
  MediaQueryData media,
  String message,
) {
  messenger.hideCurrentSnackBar();
  messenger.clearMaterialBanners();
  messenger.showMaterialBanner(
    MaterialBanner(
      padding: const EdgeInsetsDirectional.only(
        start: 16,
        end: 4,
        top: 8,
        bottom: 8,
      ),
      leading: const Icon(Icons.check_circle_outline, size: 22),
      content: Text(message),
      actions: [
        IconButton(
          tooltip: AppStrings.dismissMessage,
          onPressed: messenger.hideCurrentMaterialBanner,
          icon: const Icon(Icons.close),
        ),
      ],
    ),
  );
  // Auto-dismiss; a newer banner clears this one via [clearMaterialBanners].
  unawaited(
    Future<void>.delayed(const Duration(seconds: 3), () {
      messenger.hideCurrentMaterialBanner();
    }),
  );
}
