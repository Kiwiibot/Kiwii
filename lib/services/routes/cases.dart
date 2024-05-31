/*
 * Kiwii, a stupid Discord bot.
 * Copyright (C) 2019-2024 Rapougnac
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

import '../../database.dart';
import '../../kiwii.dart';

part 'cases.g.dart';

class CasesService {
  final db = GetIt.I.get<AppDatabase>();
  final client = GetIt.I.get<NyxxGateway>();

  @Route.get('/<gId>')
  Future<Response> listCases(Request request, String gId) async {
    final guildId = Snowflake.parse(gId);

    final cases = await (db.customSelect(
      '''
      SELECT target_id, target_tag, count(*) cases_count
      FROM cases
      WHERE guild_id = \$1
      AND action not in (1, 8)
      GROUP BY target_id, target_tag
      ORDER BY MAX(created_at) DESC
      limit 50;
      ''',
      variables: [Variable.withBigInt(guildId.toBigInt())],
    ).get());

    final count = await (db.customSelect(
      '''
      SELECT count(*) as total_cases
      FROM cases
      WHERE guild_id = \$1
      AND action not in (1, 8);
      ''',
      variables: [Variable.withBigInt(guildId.toBigInt())],
    ).getSingle());

    return Response.ok(
      jsonEncode({
        'cases': cases
            .map(
              (e) => Map.fromEntries(e.data.entries.map(
                (e) => e.value is int && (e.value > 0xffffffff || e.value < -0x80000000)
                    ? MapEntry(
                        e.key,
                        e.value.toString(),
                      )
                    : MapEntry(
                        e.key,
                        e.value,
                      ),
              )),
            )
            .toList(),
        'count': count.data['total_cases'],
      }),
      headers: {
        'Content-Type': 'application/json',
      },
    );
  }

  @Route.get('/<gId>/<uId>')
  Future<Response> listUserCases(Request request, String gId, String uId) async {
    final guildId = Snowflake.parse(gId);
    final userId = Snowflake.parse(uId);

    final user = await client.users.fetch(userId);

    final cases = await (db.cases.select()
          ..where(
            (tbl) => tbl.guildId.equalsValue(guildId) & tbl.targetId.equalsValue(userId) & tbl.action.isNotIn([1, 8]),
          )
          ..orderBy(
            [
              (tbl) => OrderingTerm.desc(tbl.createdAt),
            ],
          ))
        .get();

    final count = await (db.customSelect(
      '''
      SELECT count(*)
      FROM cases
      WHERE guild_id = \$1
      AND target_id = \$2
      AND action not in (1, 8);
      ''',
      variables: [Variable.withBigInt(guildId.toBigInt()), Variable.withBigInt(userId.toBigInt())],
    ).getSingle());

    return Response.ok(
      jsonEncode({
        'cases': cases
            .map((e) => e.toJson(
                  serializer: JsonSerializerDb(
                    serializeDateTimeValuesAsString: true,
                  ),
                ))
            .toList(),
        'count': count.data['count'],
        'user': user.toJson(),
      }),
      headers: {
        'Content-Type': 'application/json',
      },
    );
  }

  Router get router => _$CasesServiceRouter(this);
}
