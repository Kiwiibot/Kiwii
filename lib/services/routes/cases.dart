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

    // final cases = await (client.repositories.connection.execute(
    //   '''
    //   SELECT target_id, target_tag, count(*) cases_count
    //   FROM cases
    //   WHERE guild_id = \$1
    //   AND action not in (1, 8)
    //   GROUP BY target_id, target_tag
    //   ORDER BY MAX(created_at) DESC
    //   limit 50;
    //   ''',
    //   parameters: [guildId.value],
    // ));

    // final count = await (client.repositories.connection.execute(
    //   '''
    //   SELECT count(*) as total_cases
    //   FROM cases
    //   WHERE guild_id = \$1
    //   AND action not in (1, 8);
    //   ''',
    //   parameters: [guildId.value],
    // )).then((r) => r.single.first as int);

    final result = await (client.repositories.connection.execute(
      r'''
    SELECT
      jsonb_build_object(
        'cases',
        COALESCE(
          (
            SELECT
              jsonb_agg(
                jsonb_build_object(
                  'target_id', sub.target_id::text,
                  'target_tag', sub.target_tag,
                  'cases_count', sub.cases_count
                )
              )
            FROM (
              SELECT
                target_id,
                target_tag,
                COUNT(*) AS cases_count
              FROM cases
              WHERE guild_id = $1
                AND action NOT IN (1, 8)
              GROUP BY
                target_id,
                target_tag
              ORDER BY
                MAX(created_at) DESC
              LIMIT 50
            ) AS sub
          ),
          '[]'::jsonb
        ),
        'count',
        (
          SELECT COUNT(*)
          FROM cases
          WHERE guild_id = $1
            AND action NOT IN (1, 8)
        )
      )::text AS result_json;
    ''',
      parameters: [guildId.value],
    ));

    final jsonString = result.single.first as String;

    return Response.ok(jsonString, headers: {'Content-Type': 'application/json'});
  }

  @Route.get('/<gId>/<uId>')
  Future<Response> listUserCases(Request request, String gId, String uId) async {
    final guildId = Snowflake.parse(gId);
    final userId = Snowflake.parse(uId);

    final user = await client.users.fetch(userId);

    final result = await (client.repositories.connection.execute(
      r'''
    SELECT
      jsonb_build_object(
        'cases',
        COALESCE(
          (
            SELECT
              jsonb_agg(
                jsonb_build_object(
                  'guild_id', c.guild_id::text,
                  'log_message_id', c.log_message_id::text,
                  'case_id', c.case_id,
                  'ref_id', c.ref_id,
                  'target_id', c.target_id::text,
                  'target_tag', c.target_tag,
                  'mod_id', c.mod_id::text,
                  'mod_tag', c.mod_tag,
                  'action', c.action,
                  'reason', c.reason,
                  'action_expiration', c.action_expiration::text,
                  'action_processed', c.action_processed,
                  'created_at', c.created_at::text,
                  'context_message_id', c.context_message_id::text,
                  'role_id', c.role_id::text,
                  'multi', c.multi,
                  'report_ref_id', c.report_ref_id,
                  'appeal_ref_id', c.appeal_ref_id,
                  'log_dm_message_id', c.log_dm_message_id::text
                ) ORDER BY c.created_at DESC
              )
            FROM cases AS c
            WHERE c.guild_id = $1
              AND c.target_id = $2
              AND c.action NOT IN (1, 8)
          ),
          '[]'::jsonb
        ),
        'count',
        (
          SELECT COUNT(*)
          FROM cases
          WHERE guild_id = $1
            AND target_id = $2
            AND action NOT IN (1, 8)
        )
      )::text AS result_json;
    ''',
      parameters: [guildId.value, userId.value],
    ));

    // The query returns a single row with a single column 'result_json'
    final jsonString = result.single.first as String;

    // Decode the JSON string into a Dart Map
    final Map<String, dynamic> responseData = jsonDecode(jsonString);

    // 3. Add the 'user' data fetched separately to the response map
    responseData['user'] = user.toJson();

    // Encode the combined Map back to a JSON string for the HTTP response body.
    return Response.ok(jsonEncode(responseData), headers: {'Content-Type': 'application/json'});
  }

  Router get router => _$CasesServiceRouter(this);
}
