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

import 'package:darq/darq.dart';
import 'package:get_it/get_it.dart';
import 'package:neat_cache/neat_cache.dart';
import 'package:nyxx/nyxx.dart' hide Cache;
import 'package:nyxx_extensions/nyxx_extensions.dart';
import 'package:option/option.dart';

import '../src/models/appeal.dart';
import '../src/models/case.dart';
import '../src/moderation/appeal/create_appeal.dart';
import '../src/moderation/appeal/update_appeal.dart';
import '../src/moderation/case/create_case.dart';
import '../src/moderation/case/delete_case.dart';
import '../src/moderation/replies/acknowledge_case.dart';
import '../utils/extensions.dart';

Future<void> onGuildBanAdd(GuildBanAddEvent event) async {
  final cache = GetIt.I.get<Cache<String>>();

  try {
    final user = event.user;

    final guildSettings = await event.gateway.client.repositories.guilds.get(event.guild.id);
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
    event.guild.manager.client.logger.warning('Failed to create case for user ${event.user.id}', e, st);
  }
}

Future<void> onGuildBanRemove(GuildBanRemoveEvent event) async {
  final cache = GetIt.I.get<Cache<String>>();
  try {
    final user = event.user;

    final guildSettings = await event.gateway.client.repositories.guilds.get(event.guild.id);
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

    final appeal = await event.gateway.client.repositories.appeals.pending(user.id);

    if (appeal != null) {
      await updateAppeal(
        UpdateAppeal(
          appealId: appeal.appealId,
          guildId: event.guild.id,
          status: Some(AppealStatus.denied),
          modId: Some(logs.userId),
          modTag: Some((await logs.user?.get())?.tag),
        ),
      );
    }
  } catch (e, st) {
    event.guild.manager.client.logger.warning('Failed to create case for user ${event.user.id}', e, st);
  }
}
