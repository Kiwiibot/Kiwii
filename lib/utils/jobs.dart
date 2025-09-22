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

import 'package:dartx/dartx.dart';
import 'package:get_it/get_it.dart';
import 'package:nyxx/nyxx.dart' hide Connection;
import 'package:nyxx_extensions/nyxx_extensions.dart';
import 'package:postgres/postgres.dart';
import 'package:sentry/sentry.dart';
// import 'package:style_cron_job/style_cron_job.dart';

// import '../database.dart';
import '../src/models/case.dart';
import '../src/moderation/case/delete_case.dart';
import '../src/moderation/replies/acknowledge_case.dart';

Future<void> registerJobs() async {
  final client = GetIt.I.get<NyxxGateway>();
  final connection = GetIt.I.get<Connection>();

  Timer.periodic(const Duration(minutes: 1), (time) async {
    await modActionTimers(connection, client);
  });
}

Future<void> modActionTimers(Connection connection, NyxxGateway client) async {
  final currentCases = await connection
      .execute(r'SELECT guild_id, case_id, action_expiration FROM cases WHERE action_expiration IS NOT NULL AND action_processed = false;')
      .then(
        (r) => r.map((c) {
          final row = c.toColumnMap();
          return (actionExpiration: row['action_expiration'] as DateTime, caseId: row['case_id'] as int, guildId: Snowflake.parse(row['guild_id']));
        }),
      );

  for (final ccase in currentCases) {
    if (ccase.actionExpiration <= DateTime.now().toUtc()) {
      final guild = client.guilds.cache[ccase.guildId];

      if (guild == null) {
        continue;
      }

      try {
        final newCase = await deleteCase(
          DeleteCase(guildId: guild.id, caseId: ccase.caseId, modId: client.user.id, modTag: (await client.user.get()).tag),
          guild,
        );
        await acknowledgeCase(guild, newCase, '/', await client.user.get());
      } catch (e) {
        Sentry.logger.fmt.warn('Failed to process mod action timer for case %s in guild %s', [ccase.caseId, ccase.guildId]);
      }
    }
  }
}
