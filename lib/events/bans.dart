import 'package:darq/darq.dart';
import 'package:get_it/get_it.dart';
import 'package:neat_cache/neat_cache.dart';
import 'package:nyxx/nyxx.dart' hide Cache;

import '../database.dart';
import '../kiwii.dart';
import '../src/models/appeal.dart';
import '../src/models/case.dart';
import '../src/moderation/appeal/create_appeal.dart';
import '../src/moderation/appeal/update_appeal.dart';
import '../src/moderation/case/create_case.dart';
import '../src/moderation/case/delete_case.dart';
import '../src/moderation/replies/acknowledge_case.dart';

Future<void> onGuildBanAdd(GuildBanAddEvent event) async {
  final db = GetIt.I.get<AppDatabase>();
  final cache = GetIt.I.get<Cache<String>>();
  final logger = GetIt.I.get<Logger>();

  try {
    final user = event.user;

    final guildSettings = await db.getGuild(event.guild.id);
    final modLogChannelId = guildSettings.modLogChannelId;

    if (modLogChannelId == null) {
      return;
    }

    final deleted = await cache['guild:${event.guild.id}:user:${event.user.id}:ban'].get();

    if (deleted != null) {
      await cache['guild:${event.guild.id}:user:${event.user.id}:ban'].purge();
      return;
    }

    await Future<void>.delayed(const Duration(seconds: 2, milliseconds: 500));

    final auditLogs = await event.guild.auditLogs.list(limit: 10, type: AuditLogEvent.memberBanAdd);

    final logs = auditLogs.firstWhereOrDefault((e) => e.targetId == user.id, defaultValue: null);

    if (logs == null) {
      return;
    }

    final newCase = await createCase(
      (await event.guild.get()),
      CreateCase(
        guildId: event.guildId,
        action: CaseAction.ban,
        targetId: user.id,
        targetTag: user.tag,
        modId: logs.userId,
        modTag: (await logs.user?.get())?.tag,
      ),
      skip: true,
    );

    await acknowledgeCase(await event.guild.get(), newCase, '/', await logs.user?.get());
  } catch (e, st) {
    logger.warning('Failed to create case for user ${event.user.id}', e, st);
  }
}

Future<void> onGuildBanRemove(GuildBanRemoveEvent event) async {
  final db = GetIt.I.get<AppDatabase>();
  final cache = GetIt.I.get<Cache<String>>();
  final logger = GetIt.I.get<Logger>();

  try {
    final user = event.user;

    final guildSettings = await db.getGuild(event.guild.id);
    final modLogChannelId = guildSettings.modLogChannelId;

    if (modLogChannelId == null) {
      return;
    }

    final deleted = await cache['guild:${event.guild.id}:user:${event.user.id}:unban'].get();

    if (deleted != null) {
      await cache['guild:${event.guild.id}:user:${event.user.id}:unban'].purge();
      return;
    }

    await Future<void>.delayed(const Duration(seconds: 2, milliseconds: 500));

    final auditLogs = await event.guild.auditLogs.list(limit: 10, type: AuditLogEvent.memberBanRemove);

    final logs = auditLogs.firstWhereOrDefault((e) => e.targetId == user.id, defaultValue: null);

    if (logs == null) {
      return;
    }

    final ccase = await deleteCase(
      DeleteCase(
        guildId: event.guildId,
        modId: logs.userId,
        modTag: (await logs.user?.get())?.tag,
        targetId: user.id,
        targetTag: user.tag,
        reason: logs.reason,
      ),
      await event.guild.get(),
      isManual: true,
      shouldSkip: true,
    );

    await acknowledgeCase(await event.guild.get(), ccase, '/', await logs.user?.get());

    final appeal = await db.pendingAppeal(user.id);

    if (appeal != null) {
      await updateAppeal(
        UpdateAppeal(
          appealId: appeal.appealId,
          guildId: event.guild.id,
          status: AppealStatus.denied,
          modId: logs.userId,
          modTag: (await logs.user?.get())?.tag,
        ),
      );
    }
  } catch (e, st) {
    logger.warning('Failed to create case for user ${event.user.id}', e, st);
  }
}
