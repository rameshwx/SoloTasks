import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/local/drift/app_database.dart';

final appDatabaseProvider = Provider<AppDatabase>((_) {
  return AppDatabase();
});
