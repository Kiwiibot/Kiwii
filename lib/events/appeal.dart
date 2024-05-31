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

import 'package:nyxx/nyxx.dart';

import '../database.dart';
import '../kiwii.dart';
import '../plugins/localization.dart';
import '../src/models/appeal.dart';
import '../src/moderation/appeal/create_appeal.dart';
import '../src/moderation/appeal/update_appeal.dart';
import '../src/moderation/replies/acknowledge_appeal.dart';

Future<void> waitForAppeals(MessageCreateEvent event) async {
  final user = event.message.author as User;

  final hasPendingAppeal = await event.gateway.client.db.pendingAppeal(user.id);

  if (hasPendingAppeal == null) {
    return;
  }

  final guildSettings = await event.gateway.client.db.getGuild(hasPendingAppeal.guildId);

  final guild = await event.gateway.client.guilds.get(hasPendingAppeal.guildId);

  if (guildSettings.appealChannelId == null) {
    await user.sendMessage(MessageBuilder(content: guild.t.moderation.common.errors.noAppealChannel));
    return;
  }

  final updatedAppeal = await updateAppeal(UpdateAppeal(
    appealId: hasPendingAppeal.appealId,
    guildId: hasPendingAppeal.guildId,
    reason: event.message.content,
    status: AppealStatus.pending,
  ));

  await acknowledgeAppeal(updatedAppeal, guild, user, guildSettings.appealChannelId!);

  await user.sendMessage(MessageBuilder(content: guild.t.moderation.appeal.pending));
}

Future<void> onButtonAppeal(InteractionCreateEvent<MessageComponentInteraction> event) async {
  final parts = event.interaction.data.customId.split('-');

  final action = parts[1];
  final caseId = int.parse(parts[2]);
  final userId = Snowflake.parse(parts[3]);

  if (action == 'accept') {
    return acceptAppeal(event, caseId, userId);
  }

  if (action == 'reject') {
    return rejectAppeal(event, caseId, userId);
  }
}

Future<void> acceptAppeal(InteractionCreateEvent<MessageComponentInteraction> event, int caseId, Snowflake userId) async {
  final guild = await event.interaction.guild!.get();
  final client = event.gateway.client;

  final guildSettings = await client.db.getGuild(guild.id);

  final appeal = await (client.db.appeals.select()..where((tbl) => tbl.refId.equals(caseId))).getSingleOrNull();

  if (appeal == null) {
    await event.interaction.respond(
      MessageBuilder(content: guild.t.moderation.common.errors.appealNotFound),
      isEphemeral: true,
    );
  }

  final updatedAppeal = await updateAppeal(UpdateAppeal(
    appealId: appeal!.appealId,
    guildId: appeal.guildId,
    status: AppealStatus.accepted,
    reason: appeal.reason,
  ));

  final user = await client.users.fetch(userId);

  final mod = event.interaction.user ?? await client.users.get(event.interaction.member!.id);

  await user.sendMessage(MessageBuilder(content: guild.t.moderation.appeal.accepted));

  await acknowledgeAppeal(updatedAppeal, guild, user, guildSettings.appealChannelId!, mod);

  await event.interaction.respond(
    MessageBuilder(content: guild.t.moderation.appeal.modAccepted),
    isEphemeral: true,
  );
}

Future<void> rejectAppeal(InteractionCreateEvent<MessageComponentInteraction> event, int caseId, Snowflake userId) async {
  final guild = await event.interaction.guild!.get();
  final client = event.gateway.client;

  final guildSettings = await client.db.getGuild(guild.id);

  final appeal = await (client.db.appeals.select()..where((tbl) => tbl.refId.equals(caseId))).getSingleOrNull();

  if (appeal == null) {
    await event.interaction.respond(
      MessageBuilder(content: guild.t.moderation.common.errors.appealNotFound),
      isEphemeral: true,
    );
  }

  final updatedAppeal = await updateAppeal(UpdateAppeal(
    appealId: appeal!.appealId,
    guildId: appeal.guildId,
    status: AppealStatus.denied,
    reason: appeal.reason,
  ));

  final user = await client.users.fetch(userId);

  final mod = event.interaction.user ?? await client.users.get(event.interaction.member!.id);

  await user.sendMessage(MessageBuilder(content: guild.t.moderation.appeal.rejected));

  await acknowledgeAppeal(updatedAppeal, guild, user, guildSettings.appealChannelId!, mod);

  await event.interaction.respond(
    MessageBuilder(content: guild.t.moderation.appeal.modRejected),
    isEphemeral: true,
  );
}
