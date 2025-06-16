import 'dart:async';
import 'dart:typed_data';

import 'package:get_it/get_it.dart';
import 'package:nyxx/nyxx.dart' hide Connection;
import 'package:postgres/postgres.dart';
// ignore: implementation_imports
import 'package:postgres/src/v3/query_description.dart';
import 'package:characters/characters.dart';

typedef PendingEntityUpdate = (SnowflakeEntity, DateTime);
typedef PendingEntitiesUpdates = List<PendingEntityUpdate>;
typedef ResolvedEntity = Map<Snowflake, (String, int)>;
typedef ResolvedGuildEntity = Map<(Snowflake, Snowflake), (String, int)>;
typedef NamesInserts = List<(int, String, DateTime, int, int?)>;
typedef ImageInserts = List<(int, String, Uint8List, DateTime, int, int?)>;

final tracking = Tracking();

class Tracking extends NyxxPlugin<NyxxGateway> {
  late final PendingEntitiesUpdates batchNameUpdates = [];
  late PendingEntitiesUpdates currentBatchNameUpdates = [];
  late int totalNameUpdates = 0;
  late int totalGlobalNameUpdates = 0;
  late int totalNicknameUpdates = 0;
  late int totalAvatarUpates = 0;
  late int totalBannerUpdates = 0;
  late int totalGuildAvatarUpates = 0;
  late int totalGuildBannerUpdates = 0;

  late final Timer doBatchNamesUpdateTask;

  late final StreamSubscription<GuildCreateEvent> _guildCreateSubscription;
  late final StreamSubscription<UserUpdateEvent> _userUpdateSubscription;
  late final StreamSubscription<GuildMemberUpdateEvent> _guildMemberUpdateSubscription;
  late final StreamSubscription<GuildMemberAddEvent> _guildMemberAddSubscription;

  final connection = GetIt.I.get<Connection>();

  @override
  Future<NyxxGateway> doConnect(ApiOptions apiOptions, ClientOptions clientOptions, Future<NyxxGateway> Function() connect) async {
    final client = await super.doConnect(apiOptions, clientOptions, connect);

    doBatchNamesUpdateTask = Timer.periodic(const Duration(seconds: 1), (_) async {
      await doBatchUpdate();
    });

    _guildCreateSubscription = client.on((event) {
      for (final member in event.members) {
        enqueueName(member);

        if (member.user != null) {
          enqueueName(member.user!);
        }
      }
    });

    _userUpdateSubscription = client.on((event) {
      enqueueName(event.user);
    });

    _guildMemberUpdateSubscription = client.on((event) {
      enqueueName(event.member);

      if (event.member.user != null) {
        enqueueName(event.member.user!);
      }
    });

    _guildMemberAddSubscription = client.on((event) {
      enqueueName(event.member);

      if (event.member.user != null) {
        enqueueName(event.member.user!);
      }
    });

    client.on<GuildMemberRemoveEvent>((event) {
      enqueueName(event.user);
    });

    client.on<GuildDeleteEvent>((event) {
      if (event.deletedGuild != null) {
        for (final member in event.deletedGuild!.members.cache.values) {
          enqueueName(member);

          if (member.user != null) {
            enqueueName(member.user!);
          }
        }
      }
    });

    client.on<GuildMembersChunkEvent>((event) {
      for (final member in event.members) {
        enqueueName(member);
        if (member.user != null) {
          enqueueName(member.user!);
        }
      }
    });

    client.onGuildUpdate.listen((event) {
      for (final member in event.guild.members.cache.values) {
        enqueueName(member);

        if (member.user != null) {
          enqueueName(member.user!);
        }
      }
    });

    client.users.cache.onCacheUpdate.listen((user) {
      enqueueName(user);
    });

    client.cache.onCachesUpdate.listen((entity) {
      switch (entity) {
        case Member():
          enqueueName(entity);
          if (entity.user != null) {
            enqueueName(entity.user!);
          }
      }
    });

    return client;
  }

  @override
  Future<void> doClose(client, close) async {
    await _guildCreateSubscription.cancel();
    await _guildMemberAddSubscription.cancel();
    await _guildMemberUpdateSubscription.cancel();
    await _userUpdateSubscription.cancel();

    doBatchNamesUpdateTask.cancel();
    currentBatchNameUpdates.clear();
    batchNameUpdates.clear();

    await super.doClose(client, close);
  }

  void enqueueName(SnowflakeEntity entity) {
    if (entity case User(isBot: true)) {
      return;
    }

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

  Future<List<(Uint8List, String)>> avatarsFor(User user, [Duration? since]) async {
    if (since != null) {
      return avatarsForSince(user, since);
    }

    final r = await connection.execute(
      r'SELECT avatar, hash, idx FROM avatar_changes WHERE id = $1 ORDER BY idx DESC;',
      parameters: [TypedValue(Type.bigInteger, user.id.value)],
    );

    return [for (final a in r) (a.first as Uint8List, a[1] as String)];
  }

  Future<List<(Uint8List, String)>> avatarsForSince(User user, Duration since) async {
    String baseQuery = r'SELECT avatar, hash, idx FROM avatar_changes WHERE id = $1 AND date >= $2 ORDER BY idx DESC';

    final DateTime sinceDate = DateTime.now().toUtc().subtract(since);

    final String unionQuery = r'(SELECT avatar, hash, idx FROM avatar_changes WHERE id = $1 AND date < $2 ORDER BY idx DESC LIMIT 1)';
    baseQuery = '$unionQuery UNION ($baseQuery) ORDER BY idx DESC';

    final r = await connection.execute(baseQuery, parameters: [TypedValue(Type.bigInteger, user.id.value), TypedValue(Type.timestampTz, sinceDate)]);

    return [for (final n in r) (n.first as Uint8List, r[1] as String)];
  }

  Future<List<(Uint8List, String)>> bannersFor(User user, [Duration? since]) async {
    if (since != null) {
      return bannersForSince(user, since);
    }

    final r = await connection.execute(
      r'SELECT banner, hash, idx FROM banner_changes WHERE id = $1 ORDER BY idx DESC;',
      parameters: [TypedValue(Type.bigInteger, user.id.value)],
    );

    return [for (final a in r) (a.first as Uint8List, a[1] as String)];
  }

  Future<List<(Uint8List, String)>> bannersForSince(User user, Duration since) async {
    String baseQuery = r'SELECT banner, hash, idx FROM banner_changes WHERE id = $1 AND date >= $2 ORDER BY idx DESC';

    final DateTime sinceDate = DateTime.now().toUtc().subtract(since);

    final String unionQuery = r'(SELECT banner, hash, idx FROM banner_changes WHERE id = $1 AND date < $2 ORDER BY idx DESC LIMIT 1)';
    baseQuery = '$unionQuery UNION ($baseQuery) ORDER BY idx DESC';

    final r = await connection.execute(baseQuery, parameters: [TypedValue(Type.bigInteger, user.id.value), TypedValue(Type.timestampTz, sinceDate)]);

    return [for (final n in r) (n.first as Uint8List, n[1] as String)];
  }

  Future<List<(Uint8List, String)>> guildAvatarsFor(Member member, [Duration? since]) async {
    if (since != null) {
      return guildAvatarsForSince(member, since);
    }

    final r = await connection.execute(
      r'SELECT avatar, hash, idx FROM guild_avatar_changes WHERE id = $1 AND guild_id = $2 ORDER BY idx DESC;',
      parameters: [TypedValue(Type.bigInteger, member.id.value), TypedValue(Type.bigInteger, member.manager.guildId.value)],
    );

    return [for (final a in r) (a.first as Uint8List, a[1] as String),];
  }

  Future<List<(Uint8List, String)>> guildAvatarsForSince(Member member, Duration since) async {
    String baseQuery = r'SELECT avatar, hash, idx FROM guild_avatar_changes WHERE id = $1 AND guild_id = $2 AND date >= $3 ORDER BY idx DESC';

    final DateTime sinceDate = DateTime.now().toUtc().subtract(since);

    final String unionQuery = r'(SELECT avatar, hash, idx FROM guild_avatar_changes WHERE id = $1 AND guild_id = $2 AND date < $3 ORDER BY idx DESC LIMIT 1)';
    baseQuery = '$unionQuery UNION ($baseQuery) ORDER BY idx DESC';

    final r = await connection.execute(
      baseQuery,
      parameters: [
        TypedValue(Type.bigInteger, member.id.value),
        TypedValue(Type.bigInteger, member.manager.guildId.value),
        TypedValue(Type.timestampTz, sinceDate),
      ],
    );

    return [for (final n in r) (n.first as Uint8List, n[1] as String)];
  }

  Future<List<(Uint8List, String)>> guildBannersFor(Member member, [Duration? since]) async {
    if (since != null) {
      return guildBannersForSince(member, since);
    }

    final r = await connection.execute(
      r'SELECT banner, hash, idx FROM guild_banner_changes WHERE id = $1 AND guild_id = $2 ORDER BY idx DESC;',
      parameters: [TypedValue(Type.bigInteger, member.id.value), TypedValue(Type.bigInteger, member.manager.guildId.value)],
    );

    return [for (final a in r) (a.first as Uint8List, a[1] as String)];
  }

  Future<List<(Uint8List, String)>> guildBannersForSince(Member member, Duration since) async {
    String baseQuery = r'SELECT banner, hash, idx FROM guild_banner_changes WHERE id = $1 AND guild_id = $2 AND date >= $3 ORDER BY idx DESC';

    final DateTime sinceDate = DateTime.now().toUtc().subtract(since);

    final String unionQuery = r'(SELECT banner, hash, idx FROM guild_banner_changes WHERE id = $1 AND guild_id = $2 AND date < $3 ORDER BY idx DESC LIMIT 1)';
    baseQuery = '$unionQuery UNION ($baseQuery) ORDER BY idx DESC';

    final r = await connection.execute(
      baseQuery,
      parameters: [
        TypedValue(Type.bigInteger, member.id.value),
        TypedValue(Type.bigInteger, member.manager.guildId.value),
        TypedValue(Type.timestampTz, sinceDate),
      ],
    );

    return [for (final n in r) (n.first as Uint8List, n[1] as String)];
  }

  Future<void> doBatchUpdate() async {
    final allNamesUpdates = List.of(batchNameUpdates);
    batchNameUpdates.clear();

    /// Maximum allowed parameters in an IN/ANY clause.
    const int chunkSize = 6553;

    while (allNamesUpdates.isNotEmpty) {
      final currentChunkSize = allNamesUpdates.length < chunkSize ? allNamesUpdates.length : chunkSize;
      currentBatchNameUpdates = allNamesUpdates.sublist(0, currentChunkSize);

      final (currentNames, currentGlobalNames, currentNicknames, currentAvatars, currentBanners, currentGuildAvatars, currentGuildBanners) = await batchGetData(
        currentBatchNameUpdates,
      );

      final (
        nameInserts,
        globalNameInserts,
        nicknameInserts,
        avatarInserts,
        bannerInserts,
        guildAvatarInserts,
        guildBannerInserts,
      ) = await calculateNeededInserts(
        currentBatchNameUpdates,
        currentNames,
        currentGlobalNames,
        currentNicknames,
        currentAvatars,
        currentBanners,
        currentGuildAvatars,
        currentGuildBanners,
      );

      await batchInsertUpdates(nameInserts, globalNameInserts, nicknameInserts, avatarInserts, bannerInserts, guildAvatarInserts, guildBannerInserts);

      allNamesUpdates.removeRange(0, currentChunkSize);
    }
  }

  Future<void> batchInsertUpdates(
    NamesInserts usernamesInserts,
    NamesInserts globalNamesInserts,
    NamesInserts nicknamesInserts,
    ImageInserts avatarInserts,
    ImageInserts bannerInserts,
    ImageInserts guildAvatarInserts,
    ImageInserts guildBannerInserts,
  ) async {
    if (usernamesInserts.isNotEmpty) {
      for (final (id, name, time, idx, _) in usernamesInserts) {
        totalNameUpdates +=
            (await connection.execute(
              r'INSERT INTO username_changes (id, name, date, idx) VALUES ($1, $2, $3, $4) ON CONFLICT (id, idx) DO NOTHING;',
              parameters: [id, name, time, idx],
            )).affectedRows;
      }
    }

    if (globalNamesInserts.isNotEmpty) {
      for (final (id, name, time, idx, _) in globalNamesInserts) {
        totalGlobalNameUpdates +=
            (await connection.execute(
              r'INSERT INTO global_name_changes (id, name, date, idx) VALUES ($1, $2, $3, $4) ON CONFLICT (id, idx) DO NOTHING;',
              parameters: [id, name, time, idx],
            )).affectedRows;
      }
    }

    if (nicknamesInserts.isNotEmpty) {
      for (final (id, name, time, idx, guildId) in nicknamesInserts) {
        totalNicknameUpdates +=
            (await connection.execute(
              r'INSERT INTO nickname_changes (id, guild_id, name, date, idx) VALUES ($1, $2, $3, $4, $5) ON CONFLICT (id, guild_id, idx) DO NOTHING;',
              parameters: [id, guildId, name, time, idx],
            )).affectedRows;
      }
    }

    if (avatarInserts.isNotEmpty) {
      for (final (id, hash, avatar, time, idx, _) in avatarInserts) {
        totalAvatarUpates +=
            (await connection.execute(
              InternalQueryDescription.direct(
                r'INSERT INTO avatar_changes (id, hash, avatar, date, idx) VALUES ($1, $2, $3, $4, $5) ON CONFLICT (id, idx) DO NOTHING;',
                types: [Type.bigInteger, Type.text, Type.byteArray, Type.timestampTz, Type.integer],
              ),
              parameters: [
                TypedValue(Type.bigInteger, id),
                TypedValue(Type.text, hash),
                TypedValue(Type.byteArray, avatar),
                TypedValue(Type.timestampTz, time),
                TypedValue(Type.integer, idx),
              ],
            )).affectedRows;
      }
    }

    if (bannerInserts.isNotEmpty) {
      for (final (id, hash, banner, time, idx, _) in bannerInserts) {
        totalBannerUpdates +=
            (await connection.execute(
              InternalQueryDescription.direct(
                r'INSERT INTO banner_changes (id, hash, banner, date, idx) VALUES ($1, $2, $3, $4, $5) ON CONFLICT (id, idx) DO NOTHING;',
                types: [Type.bigInteger, Type.text, Type.byteArray, Type.timestampTz, Type.integer],
              ),
              parameters: [id, hash, banner, time, idx],
            )).affectedRows;
      }
    }

    if (guildAvatarInserts.isNotEmpty) {
      for (final (id, hash, avatar, time, idx, guildId) in guildAvatarInserts) {
        totalGuildAvatarUpates +=
            (await connection.execute(
              InternalQueryDescription.direct(
                r'INSERT INTO guild_avatar_changes (id, guild_id, hash, avatar, date, idx) VALUES ($1, $2, $3, $4, $5, $6) ON CONFLICT (id, guild_id, idx) DO NOTHING;',
                types: [Type.bigInteger, Type.bigInteger, Type.text, Type.byteArray, Type.timestampTz, Type.integer],
              ),
              parameters: [id, guildId, hash, avatar, time, idx],
            )).affectedRows;
      }
    }

    if (guildBannerInserts.isNotEmpty) {
      for (final (id, hash, banner, time, idx, guildId) in guildBannerInserts) {
        totalGuildBannerUpdates +=
            (await connection.execute(
              InternalQueryDescription.direct(
                r'INSERT INTO guild_banner_changes (id, guild_id, hash, banner, date, idx) VALUES ($1, $2, $3, $4, $5, $6) ON CONFLICT (id, guild_id, idx) DO NOTHING;',
                types: [Type.bigInteger, Type.bigInteger, Type.text, Type.byteArray, Type.timestampTz, Type.integer],
              ),
              parameters: [id, guildId, hash, banner, time, idx],
            )).affectedRows;
      }
    }
  }

  Future<(NamesInserts, NamesInserts, NamesInserts, ImageInserts, ImageInserts, ImageInserts, ImageInserts)> calculateNeededInserts(
    PendingEntitiesUpdates pendingEntities,
    ResolvedEntity currentNames,
    ResolvedEntity currentGlobalNames,
    ResolvedGuildEntity currentNicknames,
    ResolvedEntity currentAvatars,
    ResolvedEntity currentBanners,
    ResolvedGuildEntity currentGuildAvatars,
    ResolvedGuildEntity currentGuildBanners,
  ) async {
    final NamesInserts nameInserts = [];
    final NamesInserts globalNameInserts = [];
    final NamesInserts nicknamesInserts = [];
    final ImageInserts avatarInserts = [];
    final ImageInserts bannerInserts = [];
    final ImageInserts guildAvatarInserts = [];
    final ImageInserts guildBannerInserts = [];

    for (final (member, timestamp) in pendingEntities) {
      final (currentName, currentIdx) = currentNames[member.id] ?? (null, 0);
      final (currentGlobalName, currentGlobalIdx) = currentGlobalNames[member.id] ?? (null, 0);
      final (currentAvatarHash, currentAvatarIdx) = currentAvatars[member.id] ?? (null, 0);
      final (currentBannerHash, currentBannerIdx) = currentBanners[member.id] ?? (null, 0);

      if (member case final User user) {
        if (currentName != user.username) {
          nameInserts.add((user.id.value, user.username, timestamp, currentIdx + 1, null));
        }

        if (user.globalName != null && currentGlobalName?.characters != user.globalName!.characters) {
          globalNameInserts.add((user.id.value, user.globalName!, timestamp, currentGlobalIdx + 1, null));
        }

        if (user.avatar.hash != currentAvatarHash) {
          avatarInserts.add((user.id.value, user.avatar.hash, await user.avatar.fetch(size: 4096), timestamp, currentAvatarIdx + 1, null));
        }

        if (user case User(:final banner?)) {
          if (banner.hash != currentBannerHash) {
            bannerInserts.add((user.id.value, banner.hash, await banner.fetch(size: 4096), timestamp, currentAvatarIdx + 1, null));
          }
        }
      }

      if (member case final Member member) {
        final (currentNickname, currentNicknameIdx) = currentNicknames[(member.id, member.manager.guildId)] ?? (null, 0);
        final (currentGuildAvatarHash, currentGuildAvatarIdx) = currentGuildAvatars[(member.id, member.manager.guildId)] ?? (null, 0);
        final (currentGuildBannerHash, currentGuildBannerIdx) = currentGuildBanners[(member.id, member.manager.guildId)] ?? (null, 0);

        if (member.nick != null && currentNickname != member.nick) {
          nicknamesInserts.add((member.id.value, member.nick!, timestamp, currentNicknameIdx + 1, member.manager.guildId.value));
        }

        if (member.avatar case final CdnAsset avatar when avatar.hash != currentGuildAvatarHash) {
          guildAvatarInserts.add((
            member.id.value,
            avatar.hash,
            await avatar.fetch(size: 4096),
            timestamp,
            currentGuildAvatarIdx + 1,
            member.manager.guildId.value,
          ));
        }

        if (member.banner case final CdnAsset banner when banner.hash != currentGuildBannerHash) {
          guildBannerInserts.add((member.id.value, banner.hash, await banner.fetch(size: 4096), timestamp, currentBannerIdx + 1, member.manager.guildId.value));
        }
      }
    }

    return (nameInserts, globalNameInserts, nicknamesInserts, avatarInserts, bannerInserts, guildAvatarInserts, guildBannerInserts);
  }

  Future<(ResolvedEntity, ResolvedEntity, ResolvedGuildEntity, ResolvedEntity, ResolvedEntity, ResolvedGuildEntity, ResolvedGuildEntity)> batchGetData(
    PendingEntitiesUpdates pendingUpdates,
  ) async {
    final usernames = await connection.execute(
      r'SELECT id, name, idx FROM username_changes WHERE id = ANY($1) ORDER BY idx ASC;',
      parameters: [
        [for (final (m, _) in pendingUpdates) m.id.value],
      ],
    );

    final globalNames = await connection.execute(
      r'SELECT id, name, idx FROM global_name_changes WHERE id = ANY($1) ORDER BY idx ASC;',
      parameters: [
        [for (final (m, _) in pendingUpdates) m.id.value],
      ],
    );

    final pendingMemberUpdates = pendingUpdates.whereType<(Member, DateTime)>();

    final nicknames = await connection.execute(
      r'SELECT id, guild_id, name, idx FROM nickname_changes WHERE id = ANY($1) AND guild_id = ANY($2) ORDER BY idx ASC;',
      parameters: [
        [for (final (m, _) in pendingMemberUpdates) m.id.value],
        [for (final (m, _) in pendingMemberUpdates) m.manager.guildId.value],
      ],
    );

    final avatars = await connection.execute(
      r'SELECT id, hash, idx FROM avatar_changes WHERE id = ANY($1) ORDER BY idx ASC;',
      parameters: [
        [for (final (u, _) in pendingUpdates) u.id.value],
      ],
    );

    final banners = await connection.execute(
      r'SELECT id, hash, idx FROM banner_changes WHERE id = ANY($1) ORDER BY idx ASC;',
      parameters: [
        [for (final (u, _) in pendingUpdates) u.id.value],
      ],
    );

    final guildAvatars = await connection.execute(
      r'SELECT id, guild_id, hash, idx FROM guild_avatar_changes WHERE id = ANY($1) AND guild_id = ANY($2) ORDER BY idx ASC;',
      parameters: [
        [for (final (m, _) in pendingMemberUpdates) m.id.value],
        [for (final (m, _) in pendingMemberUpdates) m.manager.guildId.value],
      ],
    );

    final guildBanners = await connection.execute(
      r'SELECT id, guild_id, hash, idx FROM guild_banner_changes WHERE id = ANY($1) AND guild_id = ANY($2) ORDER BY idx ASC;',
      parameters: [
        [for (final (m, _) in pendingMemberUpdates) m.id.value],
        [for (final (m, _) in pendingMemberUpdates) m.manager.guildId.value],
      ],
    );

    final foundUsernames = {for (final r in usernames) Snowflake.parse(r.first!): (r[1] as String, r[2] as int)};

    final foundGlobalNames = {for (final r in globalNames) Snowflake.parse(r.first!): (r[1] as String, r[2] as int)};

    final foundNicknames = {for (final r in nicknames) (Snowflake.parse(r.first!), Snowflake.parse(r[1] as int)): (r[2] as String, r[3] as int)};

    final foundAvatars = {for (final r in avatars) Snowflake.parse(r.first!): (r[1] as String, r[2] as int)};

    final foundBanners = {for (final r in banners) Snowflake.parse(r.first!): (r[1] as String, r[2] as int)};

    final foundGuildAvatars = {for (final r in guildAvatars) (Snowflake.parse(r.first!), Snowflake.parse(r[1] as int)): (r[2] as String, r[3] as int)};

    final foundGuildBanners = {for (final r in guildBanners) (Snowflake.parse(r.first!), Snowflake.parse(r[1] as int)): (r[2] as String, r[3] as int)};

    return (foundUsernames, foundGlobalNames, foundNicknames, foundAvatars, foundBanners, foundGuildAvatars, foundGuildBanners);
  }
}
