import 'dart:async';

import 'package:get_it/get_it.dart';
import 'package:nyxx/nyxx.dart' hide Connection;
import 'package:postgres/postgres.dart';
import 'package:characters/characters.dart';

typedef PendingEntityUpdate = (SnowflakeEntity, DateTime);
typedef PendingEntitiesUpdates = List<PendingEntityUpdate>;
typedef ResolvedEntity = Map<Snowflake, (String, int)>;
typedef ResolvedGuildEntity = Map<(Snowflake, Snowflake), (String, int)>;
typedef NamesInserts = List<(int, String, DateTime, int, int?)>;

final tracking = Tracking();

class Tracking extends NyxxPlugin<NyxxGateway> {
  late final PendingEntitiesUpdates batchNameUpdates = [];
  late final PendingEntitiesUpdates batchNicknamesUpdates = [];

  final connection = GetIt.I.get<Connection>();

  @override
  Future<NyxxGateway> doConnect(ApiOptions apiOptions, ClientOptions clientOptions, Future<NyxxGateway> Function() connect) async {
    final client = await super.doConnect(apiOptions, clientOptions, connect);

    Timer.periodic(const Duration(seconds: 30), (_) async {
      await doBatchNamesUpdate();
    });

    client.on<GuildCreateEvent>((event) {
      for (final member in event.members) {
        enqueueName(member);

        if (member.user != null) {
          enqueueName(member.user!);
        }
      }
    });

    client.on<UserUpdateEvent>((event) {
      enqueueName(event.user);
    });

    client.on<GuildMemberUpdateEvent>((event) {
      enqueueName(event.member);

      if (event.member.user != null) {
        enqueueName(event.member.user!);
      }
    });

    client.on<GuildMemberAddEvent>((event) {
      enqueueName(event.member);

      if (event.member.user != null) {
        enqueueName(event.member.user!);
      }
    });

    return client;
  }

  void enqueueName(SnowflakeEntity entity) {
    batchNameUpdates.add((entity, DateTime.now()));
  }

  Future<List<String>> nicknamesFor(Member member, [Duration? since]) async {
    if (since != null) {
      return nicknamesForSince(member, since);
    }

    final r = await connection.execute(
      r'SELECT name, idx FROM nickname_changes WHERE id = $1 AND guild_id = $2 ORDER BY idx DESC;',
      parameters: [member.id.value, member.manager.guildId.value],
    );

    return [for (final n in r) n.first as String];
  }

  Future<List<String>> nicknamesForSince(Member member, Duration since) async {
    String baseQuery = r'SELECT name, idx FROM nickname_changes WHERE id = $1 AND guild_id = $2 AND date >= $3 ORDER BY idx DESC';

    final DateTime sinceDate = DateTime.now().toUtc().subtract(since);

    final String unionQuery = r'(SELECT name, idx FROM nickname_changes WHERE id = $1 AND guild_id = $2 AND date < $3 ORDER BY idx DESC LIMIT 1)';
    baseQuery = '$unionQuery UNION ($baseQuery) ORDER BY idx DESC';

    final r = await connection.execute(baseQuery, parameters: [member.id.value, member.manager.guildId.value, sinceDate]);

    return [for (final n in r) n.first as String];
  }

  Future<List<String>> namesFor(User user, [Duration? since]) async {
    if (since != null) {
      return namesForSince(user, since);
    }

    final r = await connection.execute(r'SELECT name, idx FROM username_changes WHERE id = $1 ORDER BY idx DESC;', parameters: [user.id.value]);

    return [for (final n in r) n.first as String];
  }

  Future<List<String>> namesForSince(User user, Duration since) async {
    String baseQuery = r'SELECT name, idx FROM username_changes WHERE id = $1 AND date >= $2 ORDER BY idx DESC';

    final DateTime sinceDate = DateTime.now().toUtc().subtract(since);

    final String unionQuery = r'(SELECT name, idx FROM username_changes WHERE id = $1 AND date < $2 ORDER BY idx DESC LIMIT 1)';
    baseQuery = '$unionQuery UNION ($baseQuery) ORDER BY idx DESC';

    final r = await connection.execute(baseQuery, parameters: [user.id.value, sinceDate]);

    return [for (final n in r) n.first as String];
  }

  Future<List<String>> globalNamesFor(User user, [Duration? since]) async {
    if (since != null) {
      return globalNamesForSince(user, since);
    }

    final r = await connection.execute(r'SELECT name, idx FROM global_name_changes WHERE id = $1 ORDER BY idx DESC;', parameters: [user.id.value]);

    return [for (final n in r) n.first as String];
  }

  Future<List<String>> globalNamesForSince(User user, Duration since) async {
    String baseQuery = r'SELECT name, idx FROM global_name_changes WHERE id = $1 AND date >= $2 ORDER BY idx DESC';

    final DateTime sinceDate = DateTime.now().toUtc().subtract(since);

    final String unionQuery = r'(SELECT name, idx FROM global_name_changes WHERE id = $1 AND date < $2 ORDER BY idx DESC LIMIT 1)';
    baseQuery = '$unionQuery UNION ($baseQuery) ORDER BY idx DESC';

    final r = await connection.execute(baseQuery, parameters: [user.id.value, sinceDate]);

    return [for (final n in r) n.first as String];
  }

  Future<void> doBatchNamesUpdate() async {
    final allNamesUpdates = List.of(batchNameUpdates);
    batchNameUpdates.clear();

    /// Maximum allowed parameters in an IN/ANY clause.
    const int chunkSize = 6553;

    while (allNamesUpdates.isNotEmpty) {
      final currentChunkSize = allNamesUpdates.length < chunkSize ? allNamesUpdates.length : chunkSize;
      final chunk = allNamesUpdates.sublist(0, currentChunkSize);

      final (currentNames, currentGlobalNames, currentNicknames) = await batchGetNames(chunk);

      final (nameInserts, globalNameInserts, nicknameInserts) = await calculateNeededInserts(chunk, currentNames, currentGlobalNames, currentNicknames);

      await batchInsertNamesUpdates(nameInserts, globalNameInserts, nicknameInserts);

      allNamesUpdates.removeRange(0, currentChunkSize);
    }
  }

  Future<void> batchInsertNamesUpdates(NamesInserts usernamesInserts, NamesInserts globalNamesInserts, NamesInserts nicknamesInserts) async {
    if (usernamesInserts.isNotEmpty) {
      for (final (id, name, time, idx, _) in usernamesInserts) {
        await connection.execute(
          r'INSERT INTO username_changes (id, name, date, idx) VALUES ($1, $2, $3, $4) ON CONFLICT (id, idx) DO NOTHING;',
          parameters: [id, name, time, idx],
        );
      }
    }

    if (globalNamesInserts.isNotEmpty) {
      for (final (id, name, time, idx, _) in globalNamesInserts) {
        await connection.execute(
          r'INSERT INTO global_name_changes (id, name, date, idx) VALUES ($1, $2, $3, $4) ON CONFLICT (id, idx) DO NOTHING;',
          parameters: [id, name, time, idx],
        );
      }
    }

    if (nicknamesInserts.isNotEmpty) {
      for (final (id, name, time, idx, guildId) in nicknamesInserts) {
        await connection.execute(
          r'INSERT INTO nickname_changes (id, guild_id, name, date, idx) VALUES ($1, $2, $3, $4, $5) ON CONFLICT (id, guild_id, idx) DO NOTHING;',
          parameters: [id, guildId, name, time, idx],
        );
      }
    }
  }

  Future<(NamesInserts, NamesInserts, NamesInserts)> calculateNeededInserts(
    PendingEntitiesUpdates pendingNames,
    ResolvedEntity currentNames,
    ResolvedEntity currentGlobalNames,
    ResolvedGuildEntity currentNicknames,
  ) async {
    final NamesInserts nameInserts = [];
    final NamesInserts globalNameInserts = [];
    final NamesInserts nicknamesInserts = [];

    for (final (member, timestamp) in pendingNames) {
      final (currentName, currentIdx) = currentNames[member.id] ?? (null, 0);
      final (currentGlobalName, currentGlobalIdx) = currentGlobalNames[member.id] ?? (null, 0);

      if (member case final User user) {
        if (currentName != user.username) {
          nameInserts.add((user.id.value, user.username, timestamp, currentIdx + 1, null));
        }

        if (user.globalName != null && currentGlobalName?.characters != user.globalName!.characters) {
          globalNameInserts.add((user.id.value, user.globalName!, timestamp, currentGlobalIdx + 1, null));
        }
      }

      if (member case final Member member) {
        final (currentNickname, currentNicknameIdx) = currentNicknames[(member.id, member.manager.guildId)] ?? (null, 0);

        if (member.nick != null && currentNickname?.characters != member.nick!.characters) {
          nicknamesInserts.add((member.id.value, member.nick!, timestamp, currentNicknameIdx + 1, member.manager.guildId.value));
        }
      }
    }

    return (nameInserts, globalNameInserts, nicknamesInserts);
  }

  Future<(ResolvedEntity, ResolvedEntity, ResolvedGuildEntity)> batchGetNames(PendingEntitiesUpdates pendingNamesUpdates) async {
    final usernames = await connection.execute(
      r'SELECT id, name, idx FROM username_changes WHERE id = ANY($1) ORDER BY idx ASC;',
      parameters: [
        [for (final (m, _) in pendingNamesUpdates) m.id.value],
      ],
    );

    final globalNames = await connection.execute(
      r'SELECT id, name, idx FROM global_name_changes WHERE id = ANY($1) ORDER BY idx ASC;',
      parameters: [
        [for (final (m, _) in pendingNamesUpdates) m.id.value],
      ],
    );

    final pendingNicknamesUpdates = pendingNamesUpdates.where((e) => e.$1 is Member).cast<(Member, DateTime)>();

    final nicknames = await connection.execute(
      r'SELECT id, guild_id, name, idx FROM nickname_changes WHERE id = ANY($1) AND guild_id = ANY($2) ORDER BY idx ASC;',
      parameters: [
        [for (final (m, _) in pendingNicknamesUpdates) m.id.value],
        [for (final (m, _) in pendingNicknamesUpdates) m.manager.guildId.value],
      ],
    );

    final foundUsernames = {for (final r in usernames) Snowflake.parse(r.first!): (r[1] as String, r[2] as int)};

    final foundGlobalNames = {for (final r in globalNames) Snowflake.parse(r.first!): (r[1] as String, r[2] as int)};

    final foundNicknames = {for (final r in nicknames) (Snowflake.parse(r.first!), Snowflake.parse(r[1] as int)): (r[2] as String, r[3] as int)};

    return (foundUsernames, foundGlobalNames, foundNicknames);
  }
}
