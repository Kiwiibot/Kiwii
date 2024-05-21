import 'package:nyxx/nyxx.dart';
import 'package:nyxx_commands/nyxx_commands.dart';

import '../../kiwii.dart';
import '../../plugins/localization.dart';
import '../../src/autocomplete/case.dart';
import '../../src/moderation/utils/generate.dart';

final caseCommand = ChatCommand(
  'case',
  'Lookup a moderation case.',
  id(
    'case',
    (
      ChatContext ctx,
      @Autocomplete(caseAutoCompleteWithHistory) String phrase, [
      bool hideReply = false,
    ]) async {
      final db = ctx.client.db;
      if (ctx is InteractionChatContext) {
        await ctx.acknowledge(level: hideReply ? ResponseLevel.hint : null);
      }

      final s = phrase.split(';');

      if (s.length != 2) {
        final n = int.tryParse(phrase);

        if (n == null) {
          return;
        }

        final ccase = await db.getCase(n, ctx.guild!.id);

        final guildSettings = await db.getGuild(ctx.guild!.id);

        if (guildSettings.modLogChannelId == null) {
          await ctx.send(ctx.guild.t.general.errors.noModChannel);
        }

        final modChannel = await ctx.client.channels.get(guildSettings.modLogChannelId!);

        final mod = await ctx.client.users.get(ccase.modId!);

        final goTo = ButtonBuilder.link(
          url: Uri.parse(
            messageLink(
              ccase.logMessageId!,
              modChannel.id,
              ctx.guild!.id,
            ),
          ),
          label: ctx.guild.t.moderation.history.cases.goto(
            ccase: ccase.caseId,
          ),
        );

        await ctx.respond(
          MessageBuilder(
            embeds: [
              cutEmbed(
                await generateCaseEmbed(
                  ctx.guild!.id,
                  modChannel.id,
                  ccase,
                  ctx.guild.t,
                  ctx.realPrefix,
                  mod,
                ),
              ),
            ],
            components: [
              ActionRowBuilder(
                components: [goTo],
              ),
            ],
          ),
          level: hideReply ? ResponseLevel.hint : null,
        );
        return;
      }

      final [op, id] = s;

      if (op == 'history') {
        final tuple = (
          member: await ctx.guild!.members.get(
            Snowflake.parse(id),
          ),
          user: await ctx.client.users.get(
            Snowflake.parse(id),
          ),
        );

        final embed = cutEmbed(
          await generateHistory(
            tuple,
            ctx.guild!.id,
            ctx.guild.t,
          ),
        );

        await ctx.respond(
          MessageBuilder(
            embeds: [embed],
          ),
          level: hideReply ? ResponseLevel.hint : null,
        );
      }
    },
  ),
  checks: [
    PermissionsCheck(
      Permissions.manageMessages,
      allowsOverrides: false,
      allowsDm: false,
    ),
    GuildCheck.all(),
  ],
);
