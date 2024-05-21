import 'package:nyxx/nyxx.dart';
import 'package:nyxx_commands/nyxx_commands.dart';

import '../../kiwii.dart';

final runAsCommand = ChatCommand(
  'runas',
  'Run a command as another user',
  id(
    'runas',
    (MessageChatContext ctx, User who, ChatCommand command) async {
      if (command.options.type == CommandType.slashOnly) {
        return ctx.send('Cannot run slash commands with runas');
      }

      final member = await ctx.guild?.members.get(who.id);
      final rawArguments = ctx.rawArguments.split(' ').skip(2 + command.fullName.split(' ').length).join(' ');
      final newCtx = MessageChatContext(
        message: ctx.message,
        prefix: ctx.prefix,
        rawArguments: rawArguments,
        command: command,
        user: who,
        member: member,
        guild: ctx.guild,
        channel: ctx.channel,
        commands: ctx.commands,
        client: ctx.client,
      );

      await command.invoke(newCtx);
    },
  ),
  options: CommandOptions(
    type: CommandType.textOnly,
  ),
  checks: [
    PermissionsCheck(
      Permissions.administrator,
      allowsDm: false,
      allowsOverrides: false,
      requiresAll: true,
    )
  ],
);
