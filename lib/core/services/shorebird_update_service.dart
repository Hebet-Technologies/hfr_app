import 'dart:async';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:shorebird_code_push/shorebird_code_push.dart';

import 'app_navigation_service.dart';

class ShorebirdUpdateService {
  ShorebirdUpdateService._();

  static final ShorebirdUpdateService instance = ShorebirdUpdateService._();

  final ShorebirdUpdater _updater = ShorebirdUpdater();
  bool _isChecking = false;
  bool _hasShownRestartPrompt = false;

  Future<void> checkForUpdate({bool showUpToDateMessage = false}) async {
    if (_isChecking || !_updater.isAvailable) return;

    _isChecking = true;
    try {
      final status = await _updater.checkForUpdate();
      switch (status) {
        case UpdateStatus.outdated:
          await _downloadUpdate();
        case UpdateStatus.restartRequired:
          _showRestartPrompt();
        case UpdateStatus.upToDate:
          if (showUpToDateMessage) {
            _showSnackBar('App is up to date.');
          }
        case UpdateStatus.unavailable:
          break;
      }
    } catch (error, stackTrace) {
      log(
        'Failed to check Shorebird update: $error',
        name: 'SHOREBIRD',
        stackTrace: stackTrace,
      );
    } finally {
      _isChecking = false;
    }
  }

  Future<void> _downloadUpdate() async {
    try {
      await _updater.update();
      _showRestartPrompt();
    } on UpdateException catch (error, stackTrace) {
      log(
        'Failed to download Shorebird update: ${error.message}',
        name: 'SHOREBIRD',
        stackTrace: stackTrace,
      );
    } catch (error, stackTrace) {
      log(
        'Failed to download Shorebird update: $error',
        name: 'SHOREBIRD',
        stackTrace: stackTrace,
      );
    }
  }

  void _showRestartPrompt() {
    if (_hasShownRestartPrompt) return;
    _hasShownRestartPrompt = true;

    final context = AppNavigationService.navigatorKey.currentContext;
    if (context == null || !context.mounted) {
      _hasShownRestartPrompt = false;
      return;
    }

    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) {
      _hasShownRestartPrompt = false;
      return;
    }

    messenger
      ..hideCurrentMaterialBanner()
      ..showMaterialBanner(
        MaterialBanner(
          content: const Text(
            'An app update is ready. Close and reopen the app to apply it.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                messenger.hideCurrentMaterialBanner();
                _hasShownRestartPrompt = false;
              },
              child: const Text('Later'),
            ),
          ],
        ),
      );
  }

  void _showSnackBar(String message) {
    final context = AppNavigationService.navigatorKey.currentContext;
    if (context == null || !context.mounted) return;

    final messenger = ScaffoldMessenger.maybeOf(context);
    messenger
      ?..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}
