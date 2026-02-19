import 'package:flutter_riverpod/flutter_riverpod.dart';

enum SyncStatus { synced, syncing, offline, error }

final syncStatusProvider = StateProvider<SyncStatus>((_) => SyncStatus.synced);
