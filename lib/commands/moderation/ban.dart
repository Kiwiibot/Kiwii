/*
 * Kiwii, a stupid Discord bot.
 * Copyright (C) 2019-2024 Rapougnac
 * 
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 * 
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */

import 'package:get_it/get_it.dart';
import 'package:neat_cache/neat_cache.dart';
import 'package:nyxx/nyxx.dart' hide Cache;
import 'package:nyxx_commands/nyxx_commands.dart';
import 'package:nyxx_extensions/nyxx_extensions.dart';

import '../../kiwii.dart';
import '../../plugins/localization.dart';
import '../../src/autocomplete/case.dart';
import '../../src/autocomplete/reason.dart';
import '../../src/models/case.dart';
import '../../src/moderation/case/create_case.dart';
import '../../src/moderation/replies/acknowledge_case.dart';
import '../../src/moderation/utils/generate.dart';

final banCommand = ChatCommand(
  'ban',
  'Ban somebody from the server.',
  id(
    'ban',
    (
      ChatContext ctx,
      @Description('The member to ban') Member member, [
      @Description('The reason of this action') @Autocomplete(reasonAutoComplete) String? reason,
      @Name('reference-case') @Description('The reference case') @Autocomplete(caseAutoCompleteNoHistory) int? caseId,
    ]) async {
      final user = await ctx.client.users.get(member.id);
      final modLogChannelId = await ctx.client.db.getGuildOrNull(ctx.guild!.id);
      final cache = GetIt.I.get<Cache<String>>();

      if (modLogChannelId == null) {
        await ctx.send(ctx.guild.t.general.errors.noModChannel);
        return;
      }

      bool isBanned = false;
      try {
        await ctx.guild!.manager.fetchBan(ctx.guild!.id, member.id);
        isBanned = true;
      } catch (_) {}

      if (isBanned) {
        await ctx.send(ctx.guild.t.moderation.ban.alreadyBanned(user: user.mention));
        return;
      }

      // Check if the member is bannable
      if (await member.isUnbannable) {
        await ctx.send(ctx.guild.t.moderation.ban.cannotBan(user: user.mention));
        return;
      }

      final banId = ComponentId.generate(allowedUser: ctx.user.id);
      final cancelId = ComponentId.generate(allowedUser: ctx.user.id);

      final banButton = ButtonBuilder.danger(customId: banId.toString(), label: ctx.guild.t.moderation.buttons.ban);
      final cancelButton = ButtonBuilder.secondary(customId: cancelId.toString(), label: ctx.guild.t.general.buttons.cancel);

      final embed = cutEmbed(await generateHistory((member: member, user: user), ctx.guild!.id, ctx.guild.t));

      if (ctx is InteractionChatContext) {
        await ctx.acknowledge();
      }

      final msg = await ctx.respond(
        MessageBuilder(
          content: ctx.guild.t.moderation.ban.pending(user: '${user.mention} ${user.tag} (${user.id})'),
          components: [
            ActionRowBuilder(
              components: [
                banButton,
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

      if (buttonCtx.parsedComponentId == banId) {
        await cache['guild:${ctx.guild!.id}:user:${member.id}:ban'].set('', const Duration(seconds: 15));
        final case_ = await createCase(
          buttonCtx.guild!,
          CreateCase(
            action: CaseAction.ban,
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
            content: ctx.guild.t.moderation.ban.success(user: user.tag),
            components: [],
          ),
          updateMessage: true,
        );
      } else {
        await buttonCtx.interaction.respond(
          MessageUpdateBuilder(
            content: ctx.guild.t.moderation.ban.cancel(user: user.tag),
            components: [],
          ),
          updateMessage: true,
        );
      }
    },
  ),
  checks: [
    GuildCheck.all(),
    PermissionsCheck(
      Permissions.banMembers,
      allowsOverrides: false,
      allowsDm: false,
    ),
  ],
);
