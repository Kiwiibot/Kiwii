import 'package:nyxx/nyxx.dart';
import 'package:nyxx_commands/nyxx_commands.dart';
import 'package:nyxx_extensions/nyxx_extensions.dart';
import '../../kiwii.dart';
import '../../plugins/track_presences.dart';

final _infoCommandPermissions = Permissions.sendMessages | Permissions.viewChannel;
final _infoCommandClientPermissions = Permissions.sendMessages | Permissions.viewChannel | Permissions.manageGuild;

final infoCommand = ChatGroup(
  'info',
  'Get information about a user or the server',
  checks: [BasePermissionsCheck(_infoCommandPermissions), BaseSelfPermissionsCheck(_infoCommandClientPermissions), GuildCheck.all()],
  options: KiwiiCommandOptions(
    permissions: _infoCommandPermissions,
    clientPermissions: _infoCommandClientPermissions,
    usage: '',
    examples: [(command: '', description: '')],
  ),
  children: [
    ChatCommand(
      'user',
      'Get information about a user',
      id('info-user', (ChatContext ctx, Member member) async {
        final user = await ctx.client.users.fetch(member.id);

        final presence = presences[user];

        var status = presence?.status?.value;
        // final flags = user.flags;

        final devices = <String>[];

        if (presence?.clientStatus?.desktop case final desktop) {
          status ??= desktop?.value;
          devices.add('desktop');
        }

        if (presence?.clientStatus?.embedded case final console) {
          status ??= console?.value;
          devices.add('console');
        }

        if (presence?.clientStatus?.mobile case final mobile) {
          status ??= mobile?.value;
          devices.add('mobile');
        }

        if (presence?.clientStatus?.web case final web) {
          status ??= web?.value;
          devices.add('web');
        }

        status ??= 'N/A';

        final query = await ctx.guild!.members.query(orQuery: MemberFilterBuilder(userId: QueryBuilder(orQuery: [user.id])));

        final result = query.members.first;

        final embed = EmbedBuilder(
          author: EmbedAuthorBuilder(name: user.tag, iconUrl: user.avatar.url, url: user.url),
          description: 'TODO',
          fields: [
            EmbedFieldBuilder(name: 'Member', value: user.mention, isInline: true),
            EmbedFieldBuilder(name: 'Name', value: user.tag, isInline: true),
            EmbedFieldBuilder(name: 'Nickname', value: member.nick ?? 'Nah', isInline: true),
            EmbedFieldBuilder(name: 'Invited by', value: (await result.inviter?.get())?.tag ?? 'Unknown', isInline: true),
            EmbedFieldBuilder(name: 'Used invite', value: result.sourceInviteCode ?? 'Unknown', isInline: true),
          ],
        );

        if (member.banner?.url != null || user.banner?.url != null) {
          embed.image = EmbedImageBuilder(url: member.banner?.url ?? user.banner!.url);
        }

        await ctx.respond(MessageBuilder(embeds: [embed]));
      }),
    ),
  ],
);
