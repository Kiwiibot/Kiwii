// import 'package:drift_postgres/drift_postgres.dart';
import 'package:drift/isolate.dart';
import 'package:drift/native.dart';
import 'package:drift_postgres/drift_postgres.dart';
import 'package:get_it/get_it.dart';
import 'package:nyxx/nyxx.dart';
import 'package:nyxx_commands/nyxx_commands.dart';
import 'package:nyxx_extensions/nyxx_extensions.dart';

import '../database.dart';
import '../plugins/localization.dart';
import '../utils/extensions.dart';

final tag = ChatCommand(
  'tag',
  'Create/Delete tags in this guild',
  id('tag', (MessageChatContext _) {}),
  children: [
    ChatCommand(
      'create',
      'Create a tag',
      id(
        'tag-create',
        (
          MessageChatContext ctx,
          @Description('The name of the tag to create.') String name,
          @Description('The contents of the tag.') List<String> contents,
        ) async {
          final commands = ctx.commands.walkCommands().whereType<ChatCommand>();
          if (commands.any((command) => command.root.name == name)) {
            await ctx.respond(MessageBuilder(content: ctx.guild.t.tag.command));
            return;
          }

          final db = GetIt.I.get<AppDatabase>();
          final tag = TagsCompanion.insert(
            name: name,
            content: contents.join(' '),
            ownerId: ctx.user.id,
            locationId: ctx.guild!.id.value,
            createdAt: Value(
              PgDateTime(
                DateTime.now(),
              ),
            ),
          );

          try {
            await db.transaction(() {
              return db.into(db.tags).insert(tag);
            });
          } catch (e) {
            if (e is DriftRemoteException) {
              final error = e.remoteCause as SqliteException;
              if (error.message.contains('UNIQUE constraint failed')) {
                await ctx.respond(MessageBuilder(content: ctx.guild.t.tag.tag));
                return;
              }

              await ctx.respond(MessageBuilder(content: ctx.guild.t.tag.error(message: error.message, explanation: error.explanation ?? '')));
              return;
            }

            rethrow;
          }

          await ctx.respond(MessageBuilder(content: ctx.guild.t.tag.created(tag: name)));
          return;
        },
      ),
    ),
    ChatCommand(
      'delete',
      'Delete a tag',
      id(
        'tag-delete',
        (MessageChatContext ctx, String name) async {
          final db = GetIt.I.get<AppDatabase>();
          try {
            await db.transaction(() async {
              await (db.delete(db.tags)..where((tag) => tag.name.equals(name) & tag.locationId.equals(ctx.guild!.id.value))).go();
            });
          } catch (e) {
            await ctx.respond(MessageBuilder(content: 'An error occurred while deleting the tag.'));
            return;
          }

          await ctx.respond(MessageBuilder(content: 'Tag `$name` deleted successfully.'));
        },
      ),
    ),
    ChatCommand(
      'edit',
      'Edit a tag',
      id(
        'tag-edit',
        (
          MessageChatContext ctx,
          @Description('The name of the tag to edit.') String name,
          @Description('The new contents of the tag.') List<String> contents,
        ) async {
          final db = GetIt.I.get<AppDatabase>();
          try {
            await db.transaction(() async {
              await (db.update(db.tags)..where((tag) => tag.name.equals(name) & tag.locationId.equals(ctx.guild!.id.value)))
                  .write(TagsCompanion(content: Value(contents.join(' '))));
            });
          } catch (e) {
            await ctx.respond(MessageBuilder(content: 'An error occurred while editing the tag.'));
            return;
          }

          await ctx.respond(MessageBuilder(content: 'Tag `$name` edited successfully.'));
        },
      ),
    ),
    ChatCommand(
      'raw',
      'See the raw contents of the tag',
      id(
        'tag-raw',
        (MessageChatContext ctx, String name) async {
          final db = GetIt.I.get<AppDatabase>();
          final tag = await (db.select(db.tags)..where((tag) => tag.name.equals(name) & tag.locationId.equals(ctx.guild!.id.value))).getSingleOrNull();

          if (tag == null) {
            await ctx.respond(MessageBuilder(content: 'Tag `$name` not found.'));
            return;
          }

          await ctx.respond(MessageBuilder(content: codeBlock(tag.content)));
        },
      ),
    ),
    ChatCommand(
      'list',
      'List the tags in the guild',
      id(
        'tag-list',
        (MessageChatContext ctx) async {
          final db = GetIt.I.get<AppDatabase>();
          final tags = await (db.select(db.tags)..where((tag) => tag.locationId.equals(ctx.guild!.id.value))).get();

          if (tags.isEmpty) {
            await ctx.respond(MessageBuilder(content: 'No tags found.'));
            return;
          }

          final properTags = tags.indexed.map((data) => '${data.$1}. ${data.$2.name} (${userMention(data.$2.ownerId)})').join('\n');

          final builder = await pagination.split('${bold('🗒️Tags in this server')}\n\n$properTags');
          builder.allowedMentions = AllowedMentions.roles() & AllowedMentions.users();
          await ctx.respond(builder);
        },
      ),
    ),
    ChatCommand(
      'info',
      'Get information about a tag',
      id(
        'tag-info',
        (MessageChatContext ctx, String name) async {
          final db = GetIt.I.get<AppDatabase>();
          final tag = await (db.select(db.tags)
                ..where((tag) => tag.name.equals(name) & tag.locationId.equals(ctx.guild!.id.value))
                ..limit(1))
              .getSingleOrNull();

          if (tag == null) {
            await ctx.respond(MessageBuilder(content: 'Tag `$name` not found.'));
            return;
          }

          final embed = EmbedBuilder(
            title: tag.name,
            author: EmbedAuthorBuilder(
              name: ctx.user.username,
              iconUrl: ctx.user.avatar.url,
            ),
            fields: [
              EmbedFieldBuilder(
                name: 'Owner',
                value: userMention(tag.ownerId),
                isInline: true,
              ),
              EmbedFieldBuilder(
                name: 'Uses',
                value: tag.timesCalled.toString(),
                isInline: true,
              ),
            ],
            timestamp: tag.createdAt.dateTime,
          );

          await ctx.respond(MessageBuilder(embeds: [embed]));
        },
      ),
    )
  ],
  options: CommandOptions(
    type: CommandType.textOnly,
  ),
  checks: [
    GuildCheck.all(),
  ],
);
