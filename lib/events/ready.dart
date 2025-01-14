/*
 * Kiwii, a stupid Discord bot.
 * Copyright (C) 2019-2024 Lexedia
 * 
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 * 
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */

import 'dart:async';
import 'dart:math';

import 'package:nyxx/nyxx.dart';
import 'package:shelf/shelf_io.dart' as io;

import '../kiwii.dart';
import '../services/api.dart';
import '../utils/jobs.dart';
import '../src/settings.dart' as settings;

Future<void> readyEvent(ReadyEvent event) async {
  final client = event.gateway.client;
  await registerJobs();
  Timer.periodic(const Duration(seconds: 15), (timer) {
    final status = '${settings.prefix}help ─ ${settings.statuses[Random().nextInt(settings.statuses.length)]}';
    client.updatePresence(
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

  Timer.periodic(const Duration(seconds: 30), (timer) async {
    await client.httpHandler.httpClient.head(Uri.parse(settings.statusUrl));
  });

  client.logger.info('Connected as ${(await client.user.get()).tag}');

  final apiServer = await api();

  await io.serve(apiServer, 'localhost', 8080);
}
