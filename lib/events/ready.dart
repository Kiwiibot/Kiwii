import 'dart:async';
import 'dart:math';

import 'package:nyxx/nyxx.dart';
import 'package:shelf/shelf_io.dart' as io;

import '../services/api.dart';
import '../utils/jobs.dart';
import '../src/settings.dart' as settings;

Future<void> readyEvent(ReadyEvent event) async {
  await registerJobs();
  Timer.periodic(const Duration(seconds: 15), (timer) {
    final status = '${settings.prefix}help ─ ${settings.statuses[Random().nextInt(settings.statuses.length)]}';
    event.gateway.client.updatePresence(
      PresenceBuilder(
        isAfk: false,
        status: CurrentUserStatus.idle,
        activities: [
          ActivityBuilder(
            type: ActivityType.custom,
            name: status,
            state: status,
          ),
        ],
      ),
    );
  });

  final apiServer = await api();

  await io.serve(apiServer, 'localhost', 8080);
}
