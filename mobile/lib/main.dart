import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'core/services/local_notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  runApp(const ProviderScope(child: KronosApp()));

  WidgetsBinding.instance.addPostFrameCallback((_) {
    unawaited(_initializeNotifications());
  });
}

Future<void> _initializeNotifications() async {
  try {
    await localNotificationService.initialize();
  } catch (error, stackTrace) {
    FlutterError.reportError(
      FlutterErrorDetails(
        exception: error,
        stack: stackTrace,
        library: 'local_notification_service',
        context: ErrorDescription('while initializing local notifications'),
      ),
    );
  }
}
