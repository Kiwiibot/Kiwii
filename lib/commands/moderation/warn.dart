import 'package:get_it/get_it.dart';
import 'package:nyxx/nyxx.dart';
import 'package:nyxx_commands/nyxx_commands.dart';
import 'package:nyxx_extensions/nyxx_extensions.dart';

import '../../database.dart';
import '../../kiwii.dart';
import '../../plugins/localization.dart';
import '../../src/autocomplete/case.dart';
import '../../src/autocomplete/reason.dart';
import '../../src/models/case.dart';
import '../../src/moderation/case/create_case.dart';
import '../../src/moderation/replies/acknowledge_case.dart';
import '../../src/moderation/utils/generate.dart';

final warnCommand = ChatCommand(
  'warn',
  'Warn somebody',
  id(
    'warn',
    (
      ChatContext ctx,
      @Description('The member to warn') Member member, [
      @Description('The reason of this action') @Autocomplete(reasonAutoComplete) String? reason,
      @Name('reference-case') @Description('The reference case') @Autocomplete(caseAutoCompleteNoHistory) int? caseId,
      @Name('report-reference') @Description('The reference report') int? reportId,
    ]) async {
      final db = GetIt.I.get<AppDatabase>();
      final guildSettings = await db.getGuildOrNull(ctx.guild!.id);

      final modLogChannel = guildSettings?.modLogChannelId;

      if (modLogChannel == null) {
        await ctx.send(ctx.guild.t.general.errors.noModChannel);
        return;
      }

      final warnId = ComponentId.generate(allowedUser: ctx.user.id);
      final cancelId = ComponentId.generate(allowedUser: ctx.user.id);

      final warnButton = ButtonBuilder.danger(
        customId: warnId.toString(),
        label: ctx.guild.t.moderation.buttons.warn,
      );

      final cancelButton = ButtonBuilder.secondary(
        customId: cancelId.toString(),
        label: ctx.guild.t.general.buttons.cancel,
      );

      final user = await ctx.client.users.get(member.id);

      final embed = cutEmbed(await generateHistory((member: member, user: user), ctx.guild!.id, ctx.guild.t));

      if (ctx is InteractionChatContext) {
        await ctx.acknowledge();
      }

      final msg = await ctx.respond(
        MessageBuilder(
          content: ctx.guild.t.moderation.warn.pending(user: '${user.mention} ${user.tag} (${user.id})'),
          components: [
            ActionRowBuilder(
              components: [
                warnButton,
                cancelButton,
              ],
            ),
          ],
          embeds: [embed],
        ),
      );

      final buttonCtx = await ctx.getButtonPress(msg);

      if (buttonCtx.parsedComponentId == warnId) {
        final case_ = await createCase(
          buttonCtx.guild!,
          CreateCase(
            action: CaseAction.warn,
            reason: reason,
            targetId: member.id,
            targetTag: user.tag,
            modId: buttonCtx.user.id,
            modTag: buttonCtx.user.tag,
            guildId: ctx.guild!.id,
            refId: caseId,
          ),
          target: member,
        );

        await acknowledgeCase(ctx.guild!, case_, ctx.realPrefix, buttonCtx.user);

        await buttonCtx.interaction.respond(
          MessageUpdateBuilder(
            content: ctx.guild.t.moderation.warn.success(user: '${user.mention} ${user.tag} (${user.id})'),
            components: [],
            embeds: [],
          ),
          updateMessage: true,
        );
      } else if (buttonCtx.parsedComponentId == cancelId) {
        await buttonCtx.interaction.respond(
          MessageUpdateBuilder(
            content: ctx.guild.t.moderation.warn.cancel(user: '${user.mention} ${user.tag} (${user.id})'),
            components: [],
            embeds: [],
          ),
          updateMessage: true,
        );
      }
    },
  ),
  options: CommandOptions(
    defaultResponseLevel: ResponseLevel(
      isDm: false,
      hideInteraction: true,
      mention: false,
      preserveComponentMessages: true,
    ),
  ),
  checks: [
    PermissionsCheck(
      Permissions.moderateMembers,
      allowsOverrides: false,
      allowsDm: false,
    ),
    GuildCheck.all(),
  ],
);
