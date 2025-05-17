/*
 * Kiwii, a stupid Discord bot.
 * Copyright (C) 2019-2024 Lexedia
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

import 'package:nyxx/nyxx.dart';
import 'package:nyxx_commands/nyxx_commands.dart';
import 'package:nyxx_extensions/nyxx_extensions.dart';
import 'package:postgres/postgres.dart';

import '../../plugins/localization.dart';
import '../../src/models/tag.dart';
import '../../utils/extensions.dart';
import '../../src/settings.dart' as settings;

final tagCommand = ChatCommand(
  'tag',
  'Create/Delete tags in this guild',
  id('tag', (MessageChatContext _) {}),
  children: [
    ChatCommand(
      'create',
      'Create a tag',
      id('tag-create', (
        MessageChatContext ctx,
        @Description('The name of the tag to create.') String name,
        @Description('The contents of the tag.') List<String> contents,
      ) async {
        final commands = ctx.commands.walkCommands().whereType<ChatCommand>();
        if (commands.any((command) => command.root.name == name)) {
          await ctx.respond(MessageBuilder(content: ctx.guild.t.tag.command));
          return;
        }

        final tag = EditableTag(name: name, content: contents.join(' '), ownerId: ctx.user.id, locationId: ctx.guild!.id);

        try {
          await ctx.client.repositories.tags.create(tag);
        } on ServerException catch (e) {
          if (e.message.contains('UNIQUE constraint failed')) {
            await ctx.respond(MessageBuilder(content: ctx.guild.t.tag.tag));
            return;
          }

          await ctx.respond(MessageBuilder(content: ctx.guild.t.tag.createError(message: e.message)));
          return;
        }

        await ctx.respond(MessageBuilder(content: ctx.guild.t.tag.created(tag: name)));
        return;
      }),
    ),
    ChatCommand(
      'delete',
      'Delete a tag',
      id('tag-delete', (MessageChatContext ctx, Tag tag) async {
        bool shouldBypass = ctx.user.id == settings.ownerId || (await ctx.member!.computedPermissions).canManageMessages;
        try {
          String clause = r'LOWER(name)= $2 AND location_id= $3';

          if (!shouldBypass) {
            clause += r'AND owner_id = $4';
          }

          await ctx.client.repositories.tags.deleteWith(tag, clause);
        } catch (e) {
          await ctx.respond(MessageBuilder(content: ctx.guild.t.tag.deleteError(message: e.toString())));
          rethrow;
        }

        await ctx.respond(MessageBuilder(content: ctx.guild.t.tag.deleted(tag: tag.name)));
      }),
    ),
    ChatCommand(
      'edit',
      'Edit a tag',
      id('tag-edit', (
        MessageChatContext ctx,
        @Description('The name of the tag to edit.') Tag existing,
        @Description('The new contents of the tag.') List<String> contents,
      ) async {
        try {
          final tag = EditableTag(content: contents.join(' '), id: existing.id);

          await ctx.client.repositories.tags.edit(tag);
        } catch (e) {
          await ctx.respond(MessageBuilder(content: ctx.guild.t.tag.editError(message: e.toString())));
          return;
        }

        await ctx.respond(MessageBuilder(content: ctx.guild.t.tag.edited(tag: existing.name)));
      }),
    ),
    ChatCommand(
      'raw',
      'See the raw contents of the tag',
      id('tag-raw', (MessageChatContext ctx, Tag tag) async {
        await ctx.respond(
          MessageBuilder(
            content: codeBlock(
              tag.content.replaceAllMapped(
                RegExp(r'`{3}', multiLine: true),
                (m) =>
                    m[0]!
                        .split('')
                        .indexed
                        .map(
                          (e) => switch (e.$1) {
                            0 => '\u200b${e.$2}',
                            1 => '${e.$2}\u200b',
                            _ => e.$2,
                          },
                        )
                        .join(),
              ),
            ),
          ),
        );
      }),
    ),
    ChatCommand(
      'list',
      'List the tags in the guild',
      id('tag-list', (MessageChatContext ctx) async {
        final tags = await ctx.client.repositories.tags.findAll(ctx.guild!.id);

        if (tags.isEmpty) {
          await ctx.respond(MessageBuilder(content: ctx.guild.t.tag.noTagsFound));
          return;
        }

        final properTags = tags.indexed.map((data) => '${data.$1}. ${data.$2.name} (${userMention(data.$2.ownerId)})').join('\n');

        final builder = await pagination.split('${bold('🗒️ ${ctx.guild.t.tag.tagsInThisServer}')}\n\n$properTags');
        builder.allowedMentions = AllowedMentions.roles() & AllowedMentions.users();
        await ctx.respond(builder);
      }),
    ),
    ChatCommand(
      'info',
      'Get information about a tag',
      id('tag-info', (MessageChatContext ctx, Tag tag) async {
        final embed = EmbedBuilder(
          title: tag.name,
          author: EmbedAuthorBuilder(name: ctx.user.username, iconUrl: ctx.user.avatar.get(size: 4096)),
          description: tag.updatedAt != null ? ctx.guild.t.tag.lastUpdated + tag.updatedAt!.format(TimestampStyle.relativeTime) : null,
          fields: [
            EmbedFieldBuilder(name: ctx.guild.t.tag.owner, value: userMention(tag.ownerId), isInline: true),
            EmbedFieldBuilder(name: ctx.guild.t.tag.uses, value: tag.timesCalled.toString(), isInline: true),
          ],
          timestamp: tag.createdAt,
          footer: EmbedFooterBuilder(text: ctx.guild.t.tag.createdAt),
        );

        await ctx.respond(MessageBuilder(embeds: [embed]));
      }),
    ),
    ChatCommand(
      'claim',
      'Claims a tag if the owner isn\'t in the server anymore',
      id('tag-claim', (ChatContext ctx, Tag tag) async {
        final owner = await ctx.client.users.get(tag.ownerId);

        final member = await ctx.guild!.members.getSafe(owner.id);

        if (member != null) {
          return ctx.respond(MessageBuilder(content: ctx.guild.t.tag.claimMemberStillHere));
        }

        await ctx.client.repositories.tags.edit(EditableTag(id: tag.id, ownerId: ctx.user.id));

        await ctx.respond(MessageBuilder(content: ctx.guild.t.tag.claimSuccesful(tag: tag.name)));
      }),
    ),
  ],
  options: CommandOptions(type: CommandType.textOnly),
  checks: [GuildCheck.all()],
);
