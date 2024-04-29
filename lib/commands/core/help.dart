import 'package:nyxx/nyxx.dart';
import 'package:nyxx_commands/nyxx_commands.dart';

final helpCommand = ChatCommand(
  'help',
  'Help command',
  id('help', (ChatContext ctx, [ChatCommand? command]) async {
    if (command == null) {
      final commands = ctx.commands.walkCommands().whereType<ChatCommand>();
      final embed = EmbedBuilder(fields: [])
        ..title = 'Help'
        ..description = 'Use `${ctx is MessageChatContext ? ctx.prefix : '/'}help <command>` to get more information about a command.'
        ..color = DiscordColor(0x00ff00)
        ..footer = EmbedFooterBuilder(
          text: 'Kiwii',
          iconUrl: (await ctx.client.user.get()).avatar.url,
        );

      for (final command in commands) {
        embed.fields!.add(EmbedFieldBuilder(
          name: command.fullName,
          value: command.description,
          isInline: false,
        ));
      }

      await ctx.respond(MessageBuilder(embeds: [embed]));
      return;
    }
    final embed = EmbedBuilder(fields: [])
      ..title = command.fullName
      ..description = command.description
      ..color = DiscordColor.parseHexString('#00ff00')
      ..footer = EmbedFooterBuilder(
        text: 'Kiwii',
        iconUrl: (await ctx.client.user.get()).avatar.url,
      );

    if (command.children.isNotEmpty) {
      embed.fields!.add(EmbedFieldBuilder(
        name: 'Subcommands',
        value: command.children.map((e) => e.fullName).join(', '),
        isInline: false,
      ));
    }
    await ctx.respond(MessageBuilder(embeds: [embed]));
    return;
  }),
);
