import 'package:nyxx/nyxx.dart';

import '../../../database.dart' hide Guild;
import '../../../plugins/localization.dart';
import '../../../utils/extensions.dart';
import '../../models/case.dart';
import '../appeal/create_appeal.dart';
import '../case/create_case.dart';
import '../utils/generate.dart';
import 'acknowledge_case.dart';

Future<void> acknowledgeAppeal(Appeal appeal, Guild guild, User user, Snowflake appealChannelId, [User? mod]) async {
  final db = guild.manager.client.db;
  final appealChannel = await guild.manager.client.channels.get(appealChannelId) as GuildTextChannel;

  final embed = await generateAppealEmbed(appeal, user, guild.t, mod);
  final components = await generateAppealComponents(appeal, user, guild.t);

  if (appeal.logPostId != null) {
    final message = await appealChannel.messages.fetch(appeal.logPostId!);
    await message.edit(
      MessageUpdateBuilder(
        embeds: [embed],
        components: components,
      ),
    );
  } else {
    final logMessage = await appealChannel.sendMessage(
      MessageBuilder(
        embeds: [embed],
        components: components,
      ),
    );

    await db.updateAppeal(
      appeal.copyWith(
        logPostId: Value(logMessage.id),
      ),
    );
  }

  if (appeal.status == AppealStatus.accepted) {
    final reason = guild.t.moderation.appeal.unbanned;
    final ccase= await createCase(
      guild,
      CreateCase(
        guildId: guild.id,
        action: CaseAction.unban,
        targetId: user.id,
        targetTag: user.tag,
        reason: reason,
        appealRefId: appeal.appealId,
        modId: mod?.id,
        modTag: mod?.tag,
        refId: appeal.refId,
      ),
    );

    await acknowledgeCase(guild, ccase, '/', mod);
  }
}
