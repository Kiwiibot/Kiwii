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

import 'dart:convert';

import 'package:get_it/get_it.dart';
import 'package:nyxx/nyxx.dart' hide Request;
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import '../../kiwii.dart';

part 'cases.g.dart';

class CasesService {
  final client = GetIt.I.get<NyxxGateway>();

  @Route.get('/<gId>')
  Future<Response> listCases(Request request, String gId) async {
    final guildId = Snowflake.parse(gId);

    final cases = await (client.repositories.connection.execute(
      '''
      SELECT target_id, target_tag, count(*) cases_count
      FROM cases
      WHERE guild_id = \$1
      AND action not in (1, 8)
      GROUP BY target_id, target_tag
      ORDER BY MAX(created_at) DESC
      limit 50;
      ''',
      parameters: [guildId.value],
    ));

    final count = await (client.repositories.connection.execute(
      '''
      SELECT count(*) as total_cases
      FROM cases
      WHERE guild_id = \$1
      AND action not in (1, 8);
      ''',
      parameters: [guildId.value],
    )).then((r) => r.single.first as int);

    return Response.ok(
      jsonEncode({
        'cases':
            cases
                .map(
                  (e) => Map.fromEntries(
                    e.toColumnMap().entries.map(
                      (e) => e.value is int && (e.value > 0xffffffff || e.value < -0x80000000) ? MapEntry(e.key, e.value.toString()) : MapEntry(e.key, e.value),
                    ),
                  ),
                )
                .toList(),
        'count': count,
      }),
      headers: {'Content-Type': 'application/json'},
    );
  }

  @Route.get('/<gId>/<uId>')
  Future<Response> listUserCases(Request request, String gId, String uId) async {
    final guildId = Snowflake.parse(gId);
    final userId = Snowflake.parse(uId);

    final user = await client.users.fetch(userId);

    final cases = await (client.repositories.connection.execute(
      r'SELECT * FROM cases WHERE guild_id = $1 AND target_id = $2 AND action NOT IN (1, 8) ORDER BY created_at DESC;',
      parameters: [guildId.value, userId.value],
    )).then((r) => r.map((e) => e.toColumnMap()));

    final count = await (client.repositories.connection.execute(
      '''
      SELECT count(*)
      FROM cases
      WHERE guild_id = \$1
      AND target_id = \$2
      AND action not in (1, 8);
      ''',
      parameters: [guildId.value, userId.value],
    )).then((r) => r.single.single as int);

    return Response.ok(
      jsonEncode({
        'cases': cases.map(
          (e) => e.map(
            (k, v) => MapEntry(k, switch (v) {
              final DateTime time => time.toIso8601String(),
              final int val => (val > 0xffffffff || val < -0x80000000) ? val.toString() : val,
              _ => v,
            }),
          ),
        ).toList(),
        'count': count,
        'user': user.toJson(),
      }),
      headers: {'Content-Type': 'application/json'},
    );
  }

  Router get router => _$CasesServiceRouter(this);
}
