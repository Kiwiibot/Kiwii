import 'package:nyxx/nyxx.dart';
import 'package:nyxx_commands/nyxx_commands.dart';
import 'package:nyxx_extensions/nyxx_extensions.dart';
import '../../kiwii.dart';
import '../../plugins/localization.dart';
import '../../plugins/track_presences.dart';
import '../../plugins/tracking.dart';
import '../../utils/emojis.dart';

const onlineColour = 0x40a258;
const idleColour = 0xcc954c;
const dndColour = 0xd83a41;
const offlineColour = 0x82838b;

final _infoCommandPermissions = Permissions.sendMessages | Permissions.viewChannel;
final _infoCommandClientPermissions = Permissions.sendMessages | Permissions.viewChannel | Permissions.embedLinks;

final infoUserCommand = UserCommand(
  'Info User',
  id('user-info-user', (UserContext ctx) async {
    final user = await ctx.targetUser.fetch();

    final member = ctx.targetMember;

    await userInfoHandler(ctx, user, member, true);
  }),
  integrationTypes: [ApplicationIntegrationType.guildInstall, ApplicationIntegrationType.userInstall],
  contexts: [InteractionContextType.botDm, InteractionContextType.guild, InteractionContextType.privateChannel],
);

Future<void> userInfoHandler(CommandContext ctx, User user, [Member? member, bool hidden = false]) async {
  final level = hidden ? ResponseLevel.hint : ResponseLevel.public;
  await ctx.acknowledge(level: level);
  final t = ctx.guild.t.commands.info.user;
  final tracking = ctx.client.options.plugins.whereType<Tracking>().single;

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

  final hasActivityOnConsole =
      presence?.activities?.any((a) => [ActivityPlatform.ps4, ActivityPlatform.ps5, ActivityPlatform.xbox, ActivityPlatform.embedded].contains(a.platform)) ??
      false;

  final correspondingPlatforms = platforms.map((e) => emojis['${e.$2}_${e.$1}']).nonNulls.toList();

  if (hasActivityOnConsole) {
    final emoji = emojis['embedded_${presence?.status?.value}'];

    if (emoji != null) {
      correspondingPlatforms.add(emoji);
    }
  }

  List<Role>? roles;
  List<Role>? sortedRoles;
  List<String>? oldNicknames;
  const threshold = Duration(days: 90);

  final oldUsernames = await tracking.namesFor(user, threshold);
  final oldGlobalNames = await tracking.globalNamesFor(user, threshold);

  if (member != null) {
    roles = await member.roles.get();
    sortedRoles = roles.where((r) => r.id != ctx.guild?.id).toList().sorted.reversed.toList();
    oldNicknames = await tracking.nicknamesFor(member, threshold);
  }

  final embed = EmbedBuilder(
    author: EmbedAuthorBuilder(name: user.globalName ?? user.tag, iconUrl: user.avatar.url, url: user.url),
    fields: [
      EmbedFieldBuilder(name: t.member, value: user.mention, isInline: true),
      EmbedFieldBuilder(name: t.name, value: user.tag, isInline: true),
      if (member?.nick != null) EmbedFieldBuilder(name: t.nick, value: member!.nick!, isInline: true),
      EmbedFieldBuilder(name: t.status, value: correspondingPlatforms.isEmpty ? emojis['offline_web']! : correspondingPlatforms.join(' '), isInline: true),
      if (oldUsernames.isNotEmpty) EmbedFieldBuilder(name: t.pastUsernames, value: oldUsernames.take(3).join(', '), isInline: false),
      if (oldGlobalNames.isNotEmpty) EmbedFieldBuilder(name: t.pastGlobalNames, value: oldGlobalNames.take(3).join(', '), isInline: false),
      if (oldNicknames != null && oldNicknames.isNotEmpty) EmbedFieldBuilder(name: t.pastNicknames, value: oldNicknames.take(3).join(', '), isInline: false),
      EmbedFieldBuilder(name: t.seenIn, value: (await user.fetchMutualGuilds()).length.toString(), isInline: true),
      if (member != null)
        EmbedFieldBuilder(name: t.joinedAt, value: '${member.joinedAt.format()} (${member.joinedAt.format(TimestampStyle.relativeTime)})', isInline: false),
      EmbedFieldBuilder(name: t.createdAt, value: '${user.createdAt.format()} (${user.createdAt.format(TimestampStyle.relativeTime)})', isInline: false),
      if (sortedRoles != null)
        EmbedFieldBuilder(
          name: t.roles(n: sortedRoles.length),
          value: sortedRoles.sublist(0, sortedRoles.length > 50 ? 50 : sortedRoles.length).map((r) => r.mention).join(' | '),
          isInline: false,
        ),
    ],
    thumbnail: EmbedThumbnailBuilder(url: member?.avatar?.get(size: 4096) ?? user.avatar.get(size: 4096)),
    footer: EmbedFooterBuilder(text: t.id(id: user.id), iconUrl: user.avatar.get(size: 128)),
    color: user.accentColor ?? sortedRoles?.firstOrNull?.color,
  );

  if (member?.banner?.url != null || user.banner?.url != null) {
    embed.image = EmbedImageBuilder(url: member?.banner?.get(size: 4096) ?? user.banner!.get(size: 4096));
  }

  if (ctx is InteractionChatContext) {
    await ctx.interaction.respond(MessageBuilder(embeds: [embed]), isEphemeral: level.hideInteraction);
  } else {
    await ctx.respond(MessageBuilder(embeds: [embed]), level: level);
  }
}

final infoCommand = ChatGroup(
  'info',
  'Get information about a user or the server',
  checks: [BasePermissionsCheck(_infoCommandPermissions), BaseSelfPermissionsCheck(_infoCommandClientPermissions)],
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
      id('info-user', (ChatContext ctx, [User? user, bool hidden = false]) async {
        user = await (user ?? ctx.user).fetch();
        Member? member;

        if (ctx.guild != null) {
          try {
            member = await ctx.guild!.members.get(user.id);
          } on HttpResponseError {
            // do nothing.
          }
        }

        await userInfoHandler(ctx, user, member, hidden);
      }),
      options: KiwiiCommandOptions(
        clientPermissions: Permissions.embedLinks,
        examples: [(command: '@user', description: 'Get information about the @user.'), (command: '', description: 'Get information about yourself.')],
        usage: '<user>',
      ),
    ),
  ],
);

String displayNames(List<String> usernames, List<String> globalNames, [List<String>? nicks]) {
  final sb = StringBuffer();

  if (usernames.isNotEmpty) {
    sb.writeln('Usernames:');
    sb.writeAll(usernames, ', ');
    sb.writeln();
    sb.writeln();
  }

  if (globalNames.isNotEmpty) {
    sb.writeln('Display Names:');
    sb.writeAll(globalNames, ', ');
    sb.writeln();
    sb.writeln();
  }

  if (nicks != null && nicks.isNotEmpty) {
    sb.writeln('Nicknames:');
    sb.writeAll(nicks, ', ');
    sb.writeln();
    sb.writeln();
  }

  return sb.toString();
}

final namesCommand = ChatGroup(
  'names',
  'Get your past usernames, nicknames or display names',
  children: [
    ChatCommand(
      'all',
      'See all your nicknames, usernames and display names',
      id('names-all', (ChatContext ctx, [User? user, Duration? since]) async {
        user ??= ctx.user;
        final tracking = ctx.client.options.plugins.whereType<Tracking>().first;

        final usernames = await tracking.namesFor(user, since);

        final globalNames = await tracking.globalNamesFor(user, since);

        List<String>? nicknames;

        if (ctx.guild case final guild?) {
          final member = await guild.members.get(user.id);

          nicknames = await tracking.nicknamesFor(member, since);
        }

        final s = displayNames(usernames, globalNames, nicknames);

        await ctx.respond(
          MessageBuilder(content: 'Past usernames, display names and nicknames for ${user.mention}\n${codeBlock(s)}', allowedMentions: AllowedMentions.users()),
        );
      }),
    ),
    ChatCommand(
      'usernames',
      'See all your past usernames',
      id('names-usernames', (ChatContext ctx, [User? user, Duration? since]) async {
        user ??= ctx.user;
        final tracking = ctx.client.options.plugins.whereType<Tracking>().first;

        final usernames = await tracking.namesFor(user, since);

        final s = displayNames(usernames, []);

        await ctx.respond(
          MessageBuilder(content: 'Past usernames for ${user.mention}\n${codeBlock(s)}', allowedMentions: AllowedMentions.users()),
        );
      }),
    ),
    ChatCommand(
      'nicks',
      'See all your past nicknames',
      id('names-nicks', (ChatContext ctx, [Member? member, Duration? since]) async {
        member ??= ctx.member!;
        final tracking = ctx.client.options.plugins.whereType<Tracking>().first;

        final nicks = await tracking.nicknamesFor(member, since);

        final s = displayNames([], [], nicks);

        await ctx.respond(MessageBuilder(content: 'Past nicknames for ${member.user?.mention}\n${codeBlock(s)}', allowedMentions: AllowedMentions.users()));
      }),
      checks: [GuildCheck.all()],
    ),
    ChatCommand(
      'display-names',
      'See all your past display names',
      id('names-display-names', (ChatContext ctx, [User? user, Duration? since]) async {
        user ??= ctx.user;
        final tracking = ctx.client.options.plugins.whereType<Tracking>().first;

        final globalNames = await tracking.globalNamesFor(user, since);

        final s = displayNames([], globalNames);

        await ctx.respond(MessageBuilder(content: 'Past display names for ${user.mention}\n${codeBlock(s)}', allowedMentions: AllowedMentions.users()));
      }),
    ),
  ],
);
