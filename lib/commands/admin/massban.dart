import 'dart:convert';

import 'package:args/args.dart';
import 'package:nyxx/nyxx.dart';
// ignore: implementation_imports
import 'package:nyxx/src/utils/cache_helpers.dart';
import 'package:nyxx_commands/nyxx_commands.dart';

import '../../src/checks/checks.dart';

/// Mass ban multiple members from this server.
///
/// This command has a "command line" syntax.
///
/// `--reason` or `-r`: The reason for the ban.
/// `--regex` or `-R`: The regex the user's username must match. None flags are enabled.
/// `--[no-]show` or `-s`: Shows the members that will be bent instead of directly ban them.
/// `--no-avatar`: Matches members if they has a default profile picture given by Discord.
/// `--no-roles`: Matches members that have no roles.
/// `--[no-]bot`: Allows you to ban bots, `false` by default.
/// `--created`: Matches members whose accounts were created less than specified minutes ago.
/// `--joined`: Matches members that joined less than specified minutes ago.
/// `--joined-before`: Matches members who joined before the member id given.
/// `--joined-after`: Matches members who joined after the member id given.
///
/// If no arguments (unless `reason`) are provided, then all members will be bent.
/// Unless the bot has no permission to ban you.
final massbanCommand = ChatCommand(
  'massban',
  'Massban multiple members from this server.',
  id('massban', (MessageChatContext ctx, [List<String> args = const []]) async {
    final parser = ArgParser()
      ..addOption('reason', abbr: 'r', mandatory: true)
      ..addOption('regex', abbr: 'R')
      ..addFlag('show', abbr: 's', defaultsTo: false)
      ..addFlag('no-avatar', defaultsTo: false, negatable: false)
      ..addFlag('no-roles', defaultsTo: false, negatable: false)
      ..addFlag('bot', defaultsTo: false)
      ..addOption('created')
      ..addOption('joined')
      ..addOption('joined-before')
      ..addOption('joined-after');

    late ArgResults result;

    try {
      result = parser.parse(args);
    } on FormatException catch (e) {
      return await ctx.respond(
        MessageBuilder(content: 'There was an error while parsing the args; $e'),
      );
    }

    if (ctx.guild!.members.cache.isEmpty) {
      await ctx.client.gateway.listGuildMembers(ctx.guild!.id).forEach(ctx.client.updateCacheWith);
    }

    final predicatesUser = <bool Function(User)>[
      (u) => u.discriminator != '0000',
      if (!result['bot']) (u) => !u.isBot,
    ];

    final predicatesMember = <bool Function(Member)>[];

    RegExp? regExp;

    if (result['regex'] != null) {
      try {
        regExp = RegExp(result['regex'] as String);
      } on FormatException catch (e) {
        return await ctx.respond(
          MessageBuilder(content: 'Invalid regex passed to `--regex|-R`: $e'),
        );
      }

      predicatesUser.add((u) => regExp!.hasMatch(u.username));
    }

    if (result['no-avatar']) {
      predicatesUser.add((u) => u.avatarHash == null);
    }

    if (result['no-roles']) {
      predicatesMember.add((m) => m.roles.isEmpty);
    }

    Exception? err;

    final nowInUtc = DateTime.now().toUtc();

    if (result['created'] != null) {
      predicatesUser.add((u) {
        try {
          final offset = nowInUtc.subtract(Duration(days: int.parse(result['created'])));
          return u.id.timestamp.isAfter(offset);
        } on FormatException catch (e) {
          err = e;
          return false;
        }
      });
    }

    if (result['joined'] != null) {
      predicatesMember.add((m) {
        try {
          final offset = nowInUtc.subtract(Duration(days: int.parse(result['joined'])));
          return m.joinedAt.isAfter(offset);
        } on FormatException catch (e) {
          err = e;
          return false;
        }
      });
    }

    if (result['joined-before'] != null) {
      Member? member;
      try {
        member = await ctx.guild!.members.get(Snowflake.parse(result['joined-before']));
      } on Exception catch (e) {
        err = e;
      }

      predicatesMember.add((m) => m.joinedAt.isBefore(member!.joinedAt));
    }

    if (result['joined-after'] != null) {
      Member? member;
      try {
        member = await ctx.guild!.members.get(Snowflake.parse(result['joined-after']));
      } on Exception catch (e) {
        err = e;
      }

      // if (member == null) {
      //   return await ctx.respond(
      //     MessageBuilder.content(
      //       'This member was not found, try again; have you made a typo on their id?',
      //     ),
      //     mention: false,
      //   );
      // }

      predicatesMember.add((m) => m.joinedAt.isAfter(member!.joinedAt));
    }

    final membersFound = [
      if (err != null)
        // This seems overcomplicated..
        for (final m in ctx.guild!.members.cache.values)
          if (predicatesUser.every(
                (p) => p(m.user ?? ctx.client.users.cache[m.id]!),
              ) &&
              predicatesMember.every(
                (p) => p(
                  m,
                ),
              ))
            m
    ];

    if (result['show'] as bool && err == null) {
      membersFound.sort((a, b) => a.joinedAt.compareTo(b.joinedAt));
      User u;
      final str = [
        for (final m in membersFound)
          '${m.id}\tJoined: ${m.joinedAt}\tCreated: ${m.id.timestamp}\t${(u = await m.user!.get()).isBot ? '[BOT] ' : ''}${u.username}'
      ].join('\n');
      final content = 'Current time: ${DateTime.now().toUtc()}\nTotal members found: ${membersFound.length}\n\n$str';
      final attachment = AttachmentBuilder(data: utf8.encode(content), fileName: 'members.txt');
      return await ctx.respond(
        MessageBuilder(attachments: [attachment]),
      );
    } else if (err != null) {
      return ctx.respond(
        MessageBuilder(content: 'There was likely an error: $err'),
      );
    }

    final condition = await ctx.getConfirmation(
      MessageBuilder(
        content: 'This will ban **${membersFound.length} member${membersFound.length == 1 ? '' : 's'}**\nAre you sure?',
      ),
    );

    if (!condition) {
      return await ctx.channel.sendMessage(
        MessageBuilder(content: 'The operation was cancelled'),
      );
    }

    var count = 0;

    for (final member in membersFound) {
      try {
        await ctx.guild!.createBan(member.id, auditLogReason: result['reason']);
        count++;
      } on HttpResponseError {
        continue;
      }
    }

    return await ctx.respond(
      MessageBuilder(
        content: 'Banned $count/${membersFound.length} member${membersFound.length == 1 ? '' : 's'}',
      ),
    );
  }),
  checks: [
    GuildCheck.all(),
    SelfPermissionsCheck(Permissions.banMembers),
    BasePermissionsCheck(Permissions.banMembers)
  ],
);
