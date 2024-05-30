import 'package:get_it/get_it.dart';
import 'package:nyxx/nyxx.dart';

import '../../../database.dart' hide Guild;
import '../../../plugins/localization.dart';
import '../case/create_case.dart';
import '../utils/generate.dart';

Future<void> acknowledgeCase(Guild guild, Case ccase, String prefix, [User? user]) async {
  final t = guild.t;
  final db = GetIt.I.get<AppDatabase>();
  final modLogChannelId = (await db.getGuild(guild.id)).modLogChannelId;

  final embed = await generateCaseEmbed(guild.id, modLogChannelId!, ccase, t, prefix, user);

  final channel = await guild.manager.client.channels.get(modLogChannelId) as GuildTextChannel;

  if (ccase.logMessageId != null) {
    final message = await channel.messages.get(ccase.logMessageId!);
    await message.edit(MessageUpdateBuilder(
      embeds: [embed],
    ));
  } else {
    final logMessage = await channel.sendMessage(MessageBuilder(embeds: [embed]));

    await db.updateCase(
      ccase.copyWith(
        logMessageId: Value(logMessage.id),
      ),
    );
  }

  if (ccase.logDmMessageId != null && ccase.action == CaseAction.ban) {
    final message = await (await guild.manager.client.users.createDm(ccase.targetId)).messages.get(ccase.logDmMessageId!);

    await message.edit(
      MessageUpdateBuilder(
        content: guild.t.moderation.ban.dm(
              caseId: ccase.caseId,
              guildName: guild.name,
              reason: ccase.reason ?? guild.t.moderation.common.noReason,
            ) +
            (ccase.appealRefId == null ? '' : guild.t.moderation.ban.dmAppeal),
      ),
    );
  } else if (ccase.action == CaseAction.ban && ccase.logDmMessageId == null) {
    final dmMessage = await (await guild.manager.client.users.createDm(ccase.targetId)).sendMessage(
      MessageBuilder(
        content: guild.t.moderation.ban.dm(
              caseId: ccase.caseId,
              guildName: guild.name,
              reason: ccase.reason ?? guild.t.moderation.common.noReason,
            ) +
            (ccase.appealRefId == null ? '' : guild.t.moderation.ban.dmAppeal),
      ),
    );

    await db.updateCase(
      ccase.copyWith(
        logDmMessageId: Value(dmMessage.id),
      ),
    );
  }
}