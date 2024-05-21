import 'package:nyxx/nyxx.dart';
import 'package:nyxx_commands/nyxx_commands.dart';

import '../../plugins/localization.dart';
import '../../src/moderation/utils/generate.dart';
import '../../utils/utils.dart';

Future<void> lookupCommandFunc(ContextData ctx, Member member, User user) async {
  final embed = cutEmbed(
    await generateHistory((member: member, user: user), ctx.guild!.id, ctx.guild.t, HistoryType.case_),
  );

  await (ctx as dynamic).respond(MessageBuilder(embeds: [embed]), level: ResponseLevel.hint);
}

final lookupCommand = ChatCommand(
  'lookup',
  'Lookup the moderation history of a user.',
  id(
    'lookup',
    (ChatContext ctx, Member member) async {
      await lookupCommandFunc(ctx, member, await ctx.client.users.get(member.id));
    },
  ),
  checks: [
    GuildCheck.all(),
    PermissionsCheck(
      Permissions.manageMessages,
      allowsDm: false,
      allowsOverrides: false,
    )
  ],
);

final userLookupCommand = UserCommand(
  'Lookup',
  id(
    'user-lookup',
    (UserContext ctx) async {
      final member = await ctx.guild!.members.get(ctx.targetUser.id);

      await lookupCommandFunc(ctx, member, ctx.targetUser);
    },
  ),
  checks: [
    GuildCheck.all(),
    PermissionsCheck(
      Permissions.manageMessages,
      allowsDm: false,
      allowsOverrides: false,
    )
  ],
);
