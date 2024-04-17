import 'package:drift_postgres/drift_postgres.dart';
import 'package:get_it/get_it.dart';
import 'package:nyxx/nyxx.dart';
import 'package:nyxx_commands/nyxx_commands.dart';
import 'package:nyxx_extensions/nyxx_extensions.dart';
import 'package:postgres/postgres.dart';

import '../database.dart';
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
          if (commands.any((command) => command.fullName.contains(name))) {
            await ctx.respond(MessageBuilder(content: 'A command with that name already exists.'));
            return;
          }

          final db = GetIt.I.get<AppDatabase>();
          final tag = TagsCompanion.insert(
            name: name,
            content: contents.join(' '),
            ownerId: ctx.user.id.value,
            locationId: ctx.guild!.id.value,
            createdAt: PgDateTime(DateTime.now()),
          );

          try {
            await db.transaction(() async {
              return await db.into(db.tags).insert(tag);
            });
          } catch (e) {
            if (e is ServerException) {
              if (e.message.contains('duplicate key value violates unique constraint')) {
                await ctx.respond(MessageBuilder(content: 'A tag with that name already exists.'));
                return;
              }

              await ctx.respond(MessageBuilder(content: 'An error occurred while creating the tag.\n${e.message}\n${e.hint}'));
              return;
            }

            rethrow;
          }

          await ctx.respond(MessageBuilder(content: 'Tag `$name` created successfully.'));
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

          final properTags = tags.indexed.map((data) => '${data.$1}. ${data.$2.name} (${userMention(data.$2.ownerId.snowflake)})').join('\n');

          final builder = await pagination.split('${bold('🗒️Tags in this server')}\n\n$properTags');
          builder.allowedMentions = AllowedMentions.roles() & AllowedMentions.users();
          await ctx.respond(builder);
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
