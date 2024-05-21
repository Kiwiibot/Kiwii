import 'package:dartx/dartx.dart';
import 'package:get_it/get_it.dart';
import 'package:nyxx/nyxx.dart' hide Cache;
import 'package:neat_cache/neat_cache.dart';
import 'package:nyxx_commands/nyxx_commands.dart';
import 'package:duration/duration.dart';
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
import '../../utils/constants.dart';

const validDurations = ['60s', '10m', '1h', '3h', '6h', '12h', '1d', '2d', '3d', '7d'];

final timeoutCommand = ChatCommand(
  'timeout',
  'Timeout somebody',
  id(
    'timeout',
    (
      ChatContext ctx,
      @Description('The user to timeout') Member member,
      @Description('The duration of the timeout')
      @Choices(
        {
          '1 minute': '60s',
          '5 minutes': '5m',
          '10 minutes': '10m',
          '1 hour': '1h',
          '3 hours': '3h',
          '6 hours': '6h',
          '12 hours': '12h',
          '1 day': '1d',
          '2 days': '2d',
          '3 days': '3d',
          '1 week': '7d',
        },
        timeoutLocalizations,
      )
      String duration, [
      @Description('The reason for the timeout') @Autocomplete(reasonAutoComplete) String? reason,
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

      if (member.communicationDisabledUntil != null && DateTime.now() < member.communicationDisabledUntil!) {
        await ctx.send(ctx.guild.t.moderation.timeout.alreadyTimedOut);
        return;
      }

      final timeoutId = ComponentId.generate(allowedUser: ctx.user.id);
      final cancelId = ComponentId.generate(allowedUser: ctx.user.id);

      final timeoutButton = ButtonBuilder.danger(
        customId: timeoutId.toString(),
        label: ctx.guild.t.moderation.buttons.timeout,
      );
      final cancelButton = ButtonBuilder.secondary(
        customId: cancelId.toString(),
        label: ctx.guild.t.general.buttons.cancel,
      );

      final user = await ctx.client.users.get(member.id);

      final embed = cutEmbed(await generateHistory((member: member, user: user), ctx.guild!.id, ctx.guild.t));

      if (ctx is InteractionChatContext) {
        await ctx.acknowledge(level: ResponseLevel.hint);
      }

      final msg = await ctx.respond(
        MessageBuilder(
          content: ctx.guild.t.moderation.timeout.pending(user: '${user.mention} ${user.tag} (${user.id})'),
          components: [
            ActionRowBuilder(
              components: [
                timeoutButton,
                cancelButton,
              ],
            ),
          ],
          embeds: [embed],
        ),
        level: ResponseLevel(
          hideInteraction: true,
          mention: false,
          isDm: false,
          preserveComponentMessages: true,
        ),
      );

      final buttonCtx = await ctx.getButtonPress(msg);

      if (buttonCtx.parsedComponentId == cancelId) {
        await buttonCtx.interaction.respond(
          MessageBuilder(
            content: ctx.guild.t.moderation.timeout.cancel(user: user.tag),
            components: [],
          ),
          updateMessage: true,
        );
      }

      if (buttonCtx.parsedComponentId == timeoutId) {
        await buttonCtx.acknowledge(level: ResponseLevel.hint);

        final cache = GetIt.I.get<Cache<String>>();

        await cache['guild:${ctx.guild!.id}:user:${member.id}:timeout'].set('', const Duration(seconds: 15));

        final ccase = await createCase(
          ctx.guild!,
          CreateCase(
            guildId: ctx.guild!.id,
            action: CaseAction.timeout,
            targetId: member.id,
            targetTag: user.tag,
            reason: reason,
            duration: parseDuration(duration),
            modId: buttonCtx.user.id,
            modTag: buttonCtx.user.tag,
            refId: caseId,
          ),
          target: member,
        );

        await acknowledgeCase(ctx.guild!, ccase, ctx.realPrefix, buttonCtx.user);

        await buttonCtx.interaction.updateOriginalResponse(
          MessageUpdateBuilder(
            content: ctx.guild.t.moderation.timeout.success(user: user.tag),
            components: [],
          ),
        );
      }
    },
  ),
  checks: [
    PermissionsCheck(
      Permissions.moderateMembers,
      allowsDm: false,
      allowsOverrides: false,
      requiresAll: true,
    ),
    GuildCheck.all(),
  ],
);
