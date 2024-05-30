import 'dart:convert';

import 'package:get_it/get_it.dart';
import 'package:nyxx/nyxx.dart' hide Request;
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import '../../database.dart';
import '../../kiwii.dart';
import '../../src/moderation/case/create_case.dart';

part 'users.g.dart';

class UserService {
  final NyxxRest client = GetIt.I.get<NyxxGateway>();
  final db = GetIt.I.get<AppDatabase>();

  @Route.get('/<guildId>/<userId>')
  Future<Response> getUser(Request request, String guildId, String userId) async {
    final uId = Snowflake.parse(userId);
    final gId = Snowflake.parse(guildId);

    bool isBanned = false;

    try {
      await (await client.guilds.get(gId)).manager.fetchBan(gId, uId);
      isBanned = true;
    } catch (_) {
      isBanned = false;
    }

    if (isBanned) {
      final user = await client.users.fetch(uId);

      final ccase = await (db.select(db.cases)
            ..where((tbl) => tbl.guildId.equalsValue(gId) & tbl.targetId.equalsValue(uId) & tbl.action.equalsValue(CaseAction.ban))
            ..orderBy(
              [
                (u) => OrderingTerm.desc(u.createdAt),
              ],
            ))
          .getSingle();

      final mod = await client.users.fetch(ccase.modId!);

      final payload = {
        'user': user.toJson(),
        'moderator': mod.toJson(),
        'banned': isBanned,
        'case': ccase.toJson(serializer: JsonSerializerDb(serializeDateTimeValuesAsString: true)),
      };

      return Response.ok(
        jsonEncode(payload),
        headers: {'Content-Type': 'application/json'},
      );
    }

    return Response.ok(
      jsonEncode({
        'banned': isBanned,
      }),
      headers: {
        'Content-Type': 'application/json',
      },
    );
  }

  Router get router => _$UserServiceRouter(this);
}
