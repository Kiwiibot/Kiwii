import 'package:nyxx/nyxx.dart';
import 'package:nyxx_commands/nyxx_commands.dart';
import 'package:nyxx_extensions/nyxx_extensions.dart';
import '../../kiwii.dart';
import '../../plugins/localization.dart';
import '../../plugins/track_presences.dart';
import '../../utils/emojis.dart';

const onlineColour = 0x40a258;
const idleColour = 0xcc954c;
const dndColour = 0xd83a41;
const offlineColour = 0x82838b;

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
      id('info-user', (ChatContext ctx, [Member? member]) async {
        member ??= ctx.member ?? await ctx.guild!.members.get(ctx.user.id);
        final user = await ctx.client.users.get(member.id);

        final t = ctx.guild.t.commands.info.user;

        final presence = presences[user.id];

        final platforms = <(String, String?)>[];

        if (presence?.clientStatus != null) {
          final statusMap = {
            'desktop': presence!.clientStatus!.desktop,
            'embedded': presence.clientStatus!.embedded,
            'mobile': presence.clientStatus!.mobile,
            'web': presence.clientStatus!.web,
          };

          for (final platform in statusMap.keys) {
            final status = statusMap[platform];
            if (status != null) {
              platforms.add((platform, status.value));
            }
          }
        }

        final correspondingPlatforms = platforms.map((e) => emojis['${e.$2}_${e.$1}']).nonNulls;

        final roles = await member.roles.get();

        final sortedRoles = roles.where((r) => r.id != ctx.guild?.id).toList().sorted.reversed.toList();

        final embed = EmbedBuilder(
          author: EmbedAuthorBuilder(name: user.globalName ?? user.tag, iconUrl: user.avatar.url, url: user.url),
          fields: [
            EmbedFieldBuilder(name: t.member, value: user.mention, isInline: true),
            EmbedFieldBuilder(name: t.name, value: user.tag, isInline: true),
            if (member.nick != null) EmbedFieldBuilder(name: t.nick, value: member.nick!, isInline: true),
            EmbedFieldBuilder(
              name: t.status,
              value: correspondingPlatforms.isEmpty ? emojis['offline_web']! : correspondingPlatforms.join(' '),
              isInline: true,
            ),
            // EmbedFieldBuilder(name: t.seenIn, value: (await user.fetchMutualGuilds()).entries.map((e) => e.key.name).join(', '), isInline: true),
            EmbedFieldBuilder(name: t.joinedAt, value: '${member.joinedAt.format()} (${member.joinedAt.format(TimestampStyle.relativeTime)})', isInline: false),
            EmbedFieldBuilder(name: t.createdAt, value: '${user.createdAt.format()} (${user.createdAt.format(TimestampStyle.relativeTime)})', isInline: false),
            EmbedFieldBuilder(
              name: t.roles(n: sortedRoles.length),
              value: sortedRoles.sublist(0, sortedRoles.length > 50 ? 50 : sortedRoles.length).map((r) => r.mention).join(' | '),
              isInline: false,
            ),
          ],
          thumbnail: EmbedThumbnailBuilder(url: member.avatar?.get(size: 4096) ?? user.avatar.get(size: 4096)),
          footer: EmbedFooterBuilder(text: t.id(id: user.id), iconUrl: user.avatar.get(size: 128)),
          color: user.accentColor ?? sortedRoles.firstOrNull?.color,
        );

        if (member.banner?.url != null || user.banner?.url != null) {
          embed.image = EmbedImageBuilder(url: member.banner?.get(size: 4096) ?? user.banner!.get(size: 4096));
        }

        await ctx.respond(MessageBuilder(embeds: [embed]));
      }),
      options: KiwiiCommandOptions(
        clientPermissions: Permissions.embedLinks,
        examples: [(command: '@user', description: 'Get information about the @user.'), (command: '', description: 'Get information about yourself.')],
        usage: '<user>',
      ),
    ),
  ],
);
