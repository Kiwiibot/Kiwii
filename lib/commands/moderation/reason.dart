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

import 'dart:math';

import 'package:nyxx/nyxx.dart';
import 'package:nyxx_commands/nyxx_commands.dart';
import 'package:nyxx_extensions/nyxx_extensions.dart';

import '../../database.dart';
import '../../kiwii.dart';
import '../../plugins/localization.dart';
import '../../src/autocomplete/case.dart';
import '../../src/autocomplete/reason.dart';
import '../../src/models/case.dart';
import '../../src/moderation/case/update_case.dart';
import '../../src/moderation/replies/acknowledge_case.dart';

final reasonCommand = ChatCommand(
  'reason',
  'Sets the reason of the moderation action.',
  id(
    'reason',
    (
      ChatContext ctx,
      @Name('case', {
        Locale.de: 'fall',
        Locale.fr: 'cas',
      })
      @Description('The case to change, or the nth to nth with the last-case parameter', {
        Locale.de: 'Der Fall, der geändert werden soll, oder der n-te zu n-ten mit dem letzten-Fall-Parameter',
        Locale.fr: 'Le cas à modifier, ou le n-ième au n-ième avec le paramètre dernier-cas',
      })
      @Autocomplete(caseAutoCompleteNoHistory)
      @UseConverter(IntConverter(min: 1))
      int caseId,
      @Name('reason', {
        Locale.de: 'grund',
        Locale.fr: 'raison',
      })
      @Description('The reason to set', {
        Locale.de: 'Der Grund, der festgelegt werden soll',
        Locale.fr: 'La raison à définir',
      })
      @Autocomplete(reasonAutoComplete)
      String reason, [
      @Name('last-case', {
        Locale.de: 'letzter-fall',
        Locale.fr: 'dernier-cas',
      })
      @Description('The last case to change', {
        Locale.de: 'Der letzte Fall, der geändert werden soll',
        Locale.fr: 'Le dernier cas à modifier',
      })
      @Autocomplete(caseAutoCompleteNoHistory)
      @UseConverter(IntConverter(min: 1))
      int? lastCaseId,
    ]) async {
      final db = ctx.client.db;
      final guildSettings = await db.getGuildOrNull(ctx.guild!.id);

      final modLogChannel = guildSettings?.modLogChannelId;

      if (modLogChannel == null) {
        await ctx.send(ctx.guild.t.general.errors.noModChannel);
        return;
      }

      final low = min(caseId, lastCaseId ?? caseId);
      final up = max(caseId, lastCaseId ?? caseId);

      Case? caseLow;
      Case? caseUp;
      InteractiveContext context = ctx;

      if (lastCaseId != null) {
        final changeId = ComponentId.generate(allowedUser: ctx.user.id);
        final cancelId = ComponentId.generate(allowedUser: ctx.user.id);

        final changeButton = ButtonBuilder.primary(
          customId: changeId.toString(),
          label: ctx.guild.t.moderation.buttons.reason,
        );
        final cancelButton = ButtonBuilder.secondary(
          customId: cancelId.toString(),
          label: ctx.guild.t.general.buttons.cancel,
        );

        caseLow = await db.getCaseOrNull(low, ctx.guild!.id);
        caseUp = await db.getCaseOrNull(up, ctx.guild!.id);

        if (caseLow == null || caseUp == null) {
          await ctx.respond(
            MessageBuilder(
              content: ctx.guild.t.moderation.common.errors.caseRange(lower: low, upper: up),
              components: [],
            ),
          );
          return;
        }

        final msg = await ctx.respond(
          MessageBuilder(
            content: ctx.guild.t.moderation.reason.pendingMultiple(
              lower: hyperlink(
                '`#$low`',
                messageLink(
                  caseLow.logMessageId!,
                  modLogChannel,
                  ctx.guild!.id,
                ),
              ),
              upper: hyperlink(
                '`#$up`',
                messageLink(
                  caseUp.logMessageId!,
                  modLogChannel,
                  ctx.guild!.id,
                ),
              ),
              n: up - low + 1,
            ),
            components: [
              ActionRowBuilder(
                components: [
                  changeButton,
                  cancelButton,
                ],
              ),
            ],
          ),
        );

        ButtonComponentContext context = await ctx.getButtonPress(msg);

        if (context.parsedComponentId == cancelId) {
          await context.interaction.respond(
            MessageBuilder(
              content: ctx.guild.t.moderation.reason.canceled,
              components: [],
            ),
            updateMessage: true,
          );
          return;
        }

        await context.acknowledge();
      } else {
        caseLow = await db.getCaseOrNull(caseId, ctx.guild!.id);

        if (caseLow == null) {
          await ctx.respond(
            MessageBuilder(
              content: ctx.guild.t.moderation.common.errors.caseNotFound(caseId: caseId),
              components: [],
            ),
          );
          return;
        }
      }

      final succeeded = <int>[];
      final futures = <Future<UpdateCase?>>[];

      for (int i = low; i <= up; i++) {
        futures.add(() async {
          final case_ = await db.getCaseOrNull(i, ctx.guild!.id);

          if (case_ == null) {
            return null;
          }

          return UpdateCase(
            caseId: case_.caseId,
            reason: reason,
            guildId: ctx.guild!.id,
            actionExpiration: case_.actionExpiration,
          );
        }());
      }

      final updates = await Future.wait(futures);

      final cases = await batchUpdateCase(updates
          .where((c) {
            if (c == null) {
              return false;
            } else {
              succeeded.add(c.caseId!);
              return true;
            }
          })
          .cast<UpdateCase>()
          .toList());

      for (final ccase in cases) {
        await acknowledgeCase(ctx.guild!, ccase, ctx.realPrefix, ctx.user);
      }

      final message = lastCaseId != null
          ? ctx.guild.t.moderation.reason.successMultiple(
              lower: hyperlink(
                '#$low',
                messageLink(
                  caseUp!.logMessageId!,
                  modLogChannel,
                  ctx.guild!.id,
                ),
              ),
              upper: hyperlink(
                '#$up',
                messageLink(
                  caseUp.logMessageId!,
                  modLogChannel,
                  ctx.guild!.id,
                ),
              ),
              succeded: succeeded.length,
              n: up - low + 1,
            )
          : ctx.guild.t.moderation.reason.success(
              caseId: up,
            );

      await context.respond(
        MessageBuilder(content: cutText(message, 1000)),
      );
    },
  ),
  localizedNames: {
    Locale.fr: 'raison',
    Locale.de: 'grund',
  },
  localizedDescriptions: {
    Locale.fr: "Définit la raison de l'action de modération.",
    Locale.de: 'Legt den Grund der Moderationsaktion fest.',
  },
  checks: [
    GuildCheck.all(),
    PermissionsCheck(
      Permissions.manageMessages,
      allowsDm: false,
      allowsOverrides: false,
    ),
  ],
);
