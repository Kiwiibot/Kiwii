import 'package:nyxx/nyxx.dart';
import 'package:nyxx_commands/nyxx_commands.dart';
import 'package:stdlibc/stdlibc.dart';

import '../../plugins/localization.dart';
import '../../utils/extensions.dart';

final infoCommand = ChatCommand(
  'info',
  'Get information about the bot',
  id(
    'info',
    (ChatContext ctx) async {
      final info = sysinfo();
      final unameInfo = uname();

      final root = ctx.guild.t;
      final nA = root.general.nonAvailable;

      final embed = EmbedBuilder()
        ..title = 'Bot Information'
        ..addField(name: 'OS Name', value: unameInfo?.sysname ?? nA, isInline: true)
        ..addField(name: 'OS Release', value: unameInfo?.release ?? nA, isInline: true)
        ..addField(name: 'OS Version', value: unameInfo?.version ?? nA, isInline: true)
        ..addField(name: 'Machine', value: unameInfo?.machine ?? nA, isInline: true)
        ..addField(name: 'Uptime', value: '${info?.uptime ?? nA} seconds', isInline: true)
        ..addField(name: 'Total RAM', value: '${info?.totalram ?? nA} bytes', isInline: true)
        ..color = DiscordColor(0x00FF00);

      await ctx.respond(MessageBuilder(embeds: [embed]));
    },
  ),
);
