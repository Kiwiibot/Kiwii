import 'package:get_it/get_it.dart';
import 'package:nyxx/nyxx.dart';

import '../../../database.dart' hide Guild;
import '../../../plugins/localization.dart';
import '../utils/generate.dart';

Future<void> acknowledgeCase(Guild guild, Case ccase, String prefix, [User? user]) async {
  final t = guild.t;
  final db = GetIt.I.get<AppDatabase>();
  final modLogChannelId = (await db.getGuild(guild.id)).modLogChannelId;

  final embed = await generateCaseEmbed(guild.id, modLogChannelId!, ccase, t, prefix, user);

  final channel = await guild.manager.client.channels.get(modLogChannelId) as GuildTextChannel;

  if (ccase.logMessageId != null) {
    final message = await channel.messages.fetch(ccase.logMessageId!);
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
}
