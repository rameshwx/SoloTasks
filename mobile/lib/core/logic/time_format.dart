import 'package:flutter/material.dart';

import '../models/user_preferences.dart';

String formatMinutesForPreference(
  BuildContext context,
  int totalMin,
  UserTimeFormat format,
) {
  final hour = totalMin ~/ 60;
  final minute = totalMin % 60;

  final use24h = switch (format) {
    UserTimeFormat.h24 => true,
    UserTimeFormat.h12 => false,
    UserTimeFormat.system => MediaQuery.of(context).alwaysUse24HourFormat,
  };

  if (use24h) {
    return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
  }

  final suffix = hour >= 12 ? 'PM' : 'AM';
  final h12 = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
  return '${h12.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')} $suffix';
}
