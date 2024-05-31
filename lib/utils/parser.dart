// ignore_for_file: implementation_imports

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

import 'dart:convert';
import 'dart:math' as math;

import 'package:dartx/dartx.dart';
import 'package:http/http.dart' as http;
import 'package:nyxx/nyxx.dart';
import 'package:nyxx_commands/nyxx_commands.dart';
import 'package:nyxx_commands/src/converters/built_in/member.dart';
import 'package:nyxx_commands/src/converters/built_in/snowflake.dart';

import '../database.dart';
import '../plugins/tag/tag.dart';
import 'node.dart';

const permissions = {
  'CREATE_INSTANT_INVITE': Permissions.createInstantInvite,
  'KICK_MEMBERS': Permissions.kickMembers,
  'BAN_MEMBERS': Permissions.banMembers,
  'ADMINISTRATOR': Permissions.administrator,
  'MANAGE_CHANNELS': Permissions.manageChannels,
  'MANAGE_GUILD': Permissions.manageGuild,
  'ADD_REACTIONS': Permissions.addReactions,
  'VIEW_AUDIT_LOG': Permissions.viewAuditLog,
  'PRIORITY_SPEAKER': Permissions.prioritySpeaker,
  'STREAM': Permissions.stream,
  'VIEW_CHANNEL': Permissions.viewChannel,
  'SEND_MESSAGES': Permissions.sendMessages,
  'SEND_TTS_MESSAGES': Permissions.sendTtsMessages,
  'MANAGE_MESSAGES': Permissions.manageMessages,
  'EMBED_LINKS': Permissions.embedLinks,
  'ATTACH_FILES': Permissions.attachFiles,
  'READ_MESSAGE_HISTORY': Permissions.readMessageHistory,
  'MENTION_EVERYONE': Permissions.mentionEveryone,
  'USE_EXTERNAL_EMOJIS': Permissions.useExternalEmojis,
  'VIEW_GUILD_INSIGHTS': Permissions.viewGuildInsights,
  'CONNECT': Permissions.connect,
  'SPEAK': Permissions.speak,
  'MUTE_MEMBERS': Permissions.muteMembers,
  'DEAFEN_MEMBERS': Permissions.deafenMembers,
  'MOVE_MEMBERS': Permissions.moveMembers,
  'USE_VAD': Permissions.useVad,
  'CHANGE_NICKNAME': Permissions.changeNickname,
  'MANAGE_NICKNAMES': Permissions.manageNicknames,
  'MANAGE_ROLES': Permissions.manageRoles,
  'MANAGE_WEBHOOKS': Permissions.manageWebhooks,
  'MANAGE_GUILD_EXPRESSIONS': Permissions.manageEmojisAndStickers,
  'USE_APPLICATION_COMMANDS': Permissions.useApplicationCommands,
  'REQUEST_TO_SPEAK': Permissions.requestToSpeak,
  'MANAGE_THREADS': Permissions.manageThreads,
  'MANAGE_EVENTS': Permissions.manageEvents,
  'CREATE_PUBLIC_THREADS': Permissions.createPublicThreads,
  'CREATE_PRIVATE_THREADS': Permissions.createPrivateThreads,
  'USE_EXTERNAL_STICKERS': Permissions.useExternalStickers,
  'SEND_MESSAGES_IN_THREADS': Permissions.sendMessagesInThreads,
  'USE_EMDEDDED_ACTIVITIES': Permissions.useEmbeddedActivities,
  'MODERATE_MEMBERS': Permissions.moderateMembers,
  'USE_SOUNDBOARD': Permissions.useSoundboard,
  'VIEW_CREATOR_MONETIZATION_ANALYTICS': Permissions.viewCreatorMonetizationAnalytics,
  // 'USE_EXTERNAL_SOUNDS': Permissions.useExternalSounds,
  // 'SEND_VOICE_MESSAGES': Permissions.sendVoiceMessages,
};

class Parser {
  int _stackSize = 0;

  final NyxxGateway client;
  final ContextBaseWithMessage ctx;

  Parser(this.client, this.ctx);

  Future<Object?> getData(String key, String rawArgs, List<String> split, List<String> args, Tag tag) async {
    key = key.trim();
    rawArgs = rawArgs.trim();
    split = split.map((e) => e.trim()).toList();

    switch (key) {
      case 'user':
      case 'username':
        final member = rawArgs.isNotEmpty ? await memberFromString(rawArgs) : ctx.member;
        return member?.user?.username ?? '';

      case 'id':
      case 'userid':
        final member = rawArgs.isNotEmpty ? await memberFromString(rawArgs) : ctx.member;
        return member?.user?.id.toString() ?? '';

      case 'avatar':
        final member = rawArgs.isNotEmpty ? await memberFromString(rawArgs) : ctx.member;
        return member?.user?.avatar.url.toString();

      case 'avatarhash':
        final member = rawArgs.isNotEmpty ? await memberFromString(rawArgs) : ctx.member;
        return member?.user?.avatar.hash ?? '';
      case 'randuser':
        final guild = ctx.guild;

        if (guild == null) {
          return ctx.user.username;
        }

        final random = math.Random();
        final members = guild.members.cache.values;
        final member = members.elementAt(random.nextInt(members.length));
        return member.user?.username ?? '';
      case 'randchannel':
        final guild = ctx.guild;

        if (guild == null) {
          final name = switch (ctx.channel) {
            GuildTextChannel(:final name) => name,
            _ => '',
          };

          return name;
        }

        final random = math.Random();
        final channels = client.channels.cache.values.whereType<GuildTextChannel>().where((c) => c.guildId == guild.id);
        final channel = channels.elementAt(random.nextInt(channels.length));
        return channel.name;
      case 'tagname':
        return tag.name;
      case 'tagowner':
        final owner = await client.users.get(tag.ownerId);
        return owner.username;
      case 'dm':
        return ctx.guild != null ? false : true;
      case 'channels':
        final channels = client.channels.cache.values.whereType<GuildChannel>().where((c) => c.guildId == ctx.guild?.id);
        return channels.length;
      case 'members':
      case 'servercount':
        return ctx.guild?.approximateMemberCount ?? ctx.guild?.members.cache.length ?? 0;
      case 'messageid':
        return ctx.message.id.toString();
      case 'owner':
        final owner = await ctx.guild?.owner.get();
        return owner?.username ?? '';
      case 'server':
        return ctx.guild?.name ?? '';
      case 'serverid':
        return ctx.guild?.id.toString() ?? '';
      case 'haspermission':
      case 'hasperm':
        if (split.isEmpty || ctx.guild == null) {
          return null;
        }
        final permission = split.first;
        Member? member;
        if (split.asMap().containsKey(1) && split[1].isNotEmpty) {
          member = ctx.member;
        } else {
          member = await memberFromString(split[1]);
        }

        if (member == null) {
          return null;
        }

        final resolved = permissions[permission] ?? (throw Exception('Unknown permission: $permission'));
        return member.permissions?.has(resolved);
      case 'hasrole':
        if (split.isEmpty || ctx.guild == null) {
          return null;
        }
        final roleName = split.first;
        Member? member;
        if (split.asMap().containsKey(1) && split[1].isNotEmpty) {
          member = ctx.member;
        } else {
          member = await memberFromString(split[1]);
        }

        if (member == null) {
          return null;
        }

        final role = ctx.guild?.roles.cache.values.firstOrNullWhere((r) => r.name == roleName);
        return member.roles.contains(role);
      case 'created':
        if (split.isEmpty) {
          return null;
        }

        final type = split.first;
        if (type case 'channel') {
          return ctx.channel.id.timestamp.toLocal().toString();
        } else if (type case 'guild' || 'server') {
          return ctx.guild?.id.timestamp.toLocal().toString();
        }
      case 'channelid':
        return ctx.channel.id.toString();
      case 'channel':
        if (ctx.guild == null) {
          return null;
        } else {
          return (ctx.channel as GuildTextChannel).name;
        }
      case 'me':
        return (await client.user.get()).username;
      case 'range':
        final lower = split.map(int.parse).reduce(math.min);
        final upper = split.map(int.parse).reduce(math.max);
        return math.Random().nextInt(upper - lower) + lower;
      case 'random':
      case 'choose':
        return split[math.Random().nextInt(split.length)];
      case 'select':
        final index = int.parse(split.first);
        return split[index];
      case 'args':
        return args.join(' ');
      case 'argsfrom':
        final index = int.parse(split.first);
        return args.sublist(index).join(' ');
      case 'argindex':
        return args.indexOf(split.first) + 1;
      case 'argsto':
        final index = int.parse(split.first);
        return args.sublist(0, index).join(' ');
      case 'argsrange':
        final cargs = args.sublist(int.parse(split.first), int.parse(split[1]));
        return cargs.join(' ');
      case 'arg':
        final index = int.parse(split.first);
        return args[index];
      // Same as arg, but return empty string if it's OOB.
      case 'tryarg':
        final index = int.parse(split.first);
        return args.elementAtOrNull(index) ?? '';
      case 'argslen':
      case 'argscount':
      case 'argslength':
        return args.length;
      case 'replace':
        final [replace, replacement, text] = split;
        return text.replaceAll(replace, replacement);
      case 'replaceregex':
        final [replace, replacement, text] = split;
        return text.replaceAll(RegExp(replace), replacement);
      case 'upper':
        return rawArgs.toUpperCase();
      case 'lower':
        return rawArgs.toLowerCase();
      case 'trim':
        return rawArgs.trim();
      case 'length':
        return rawArgs.length;
      case 'url':
        return Uri.encodeFull(rawArgs);
      case 'urlc':
      case 'urlcomponent':
        return Uri.encodeComponent(rawArgs);
      // TODO: Time
      case 'abs':
      case 'absolute':
        return double.parse(rawArgs).abs();
      case 'pi':
        return math.pi;
      case 'e':
        return math.e;
      case 'min':
        return split.map(double.parse).reduce(math.min);
      case 'max':
        return split.map(double.parse).reduce(math.max);
      case 'round':
        return double.parse(rawArgs).round();
      case 'floor':
        return double.parse(rawArgs).floor();
      case 'ceil':
        return double.parse(rawArgs).ceil();
      case 'sign':
        return double.parse(rawArgs).sign;
      case 'sin':
        return math.sin(double.parse(rawArgs));
      case 'cos':
        return math.cos(double.parse(rawArgs));
      case 'tan':
        return math.tan(double.parse(rawArgs));
      case 'sqrt':
        return math.sqrt(double.parse(rawArgs));
      case 'root':
        final root = double.parse(split.removeLast());
        return math.pow(double.parse(split.removeLast()), 1 / root);
      case 'if':
        // final value = split.removeLast();
        // final op = split.removeLast();
        // final compareValue = split.removeLast();
        // String? onMatch, onNoMatch;

        // for (final part in split) {
        //   final splitPart = part.split(':');
        //   final action = splitPart.removeLast();
        //   if (action == 'then') {
        //     onMatch = splitPart.join(':');
        //   } else {
        //     onNoMatch = splitPart.join(':');
        //   }
        // }

        // TODO
        // final result =
        return null;
      case 'ignore':
        return escapeTag(rawArgs);
      case 'js':
        final parsed = await subParse(rawArgs.replaceAll('\x00', ''), tag, args);
        final code = 'globalThis.result = (() => {$parsed})();';
        final raw = await runPistonJS(code, {'message': ctx.rawMessage});
        final result = json.decode(raw)['result'];
        return result;
      case 'download':
        final url = Uri.parse(split.first);
        final response = await http.get(url);
        return response.body;
      default:
        return '{$key${rawArgs.isNotEmpty ? ':$rawArgs' : ''}}';
    }
    return null;
  }

  Future<Member?> memberFromString(String input) async {
    var member = await convertMember(StringView(input), ctx);
    if (member != null) {
      return member;
    }

    final snowflake = convertSnowflake(StringView(input), ctx);
    if (snowflake == null) {
      return null;
    }

    member = await snowflakeToMember(snowflake, ctx);
    return member;
  }

  Future<ParserResult> parse(String input, Tag tag, List<String> tagArgs) async {
    try {
      final result = await subParse(input, tag, tagArgs, initial: true);
      return ParserResult(isSuccess: true, result: result);
    } catch (e) {
      return ParserResult(isSuccess: false, result: e.toString());
    }
  }

  Future<String> subParse(String input, Tag tag, List<String> tagArgs, {bool initial = false}) async {
    _stackSize++;
    if (_stackSize > 1000) {
      throw Exception('Stack size exceeded at: `$input`');
    }

    if (initial) {
      input = await subParse(input, tag, tagArgs);

      int tagStart, tagEnd;

      for (int i = 0; i < input.length; i++) {
        if (input[i] == '}' && (input.at(i + 1) != r'\' && input.at(i - 1) != '\x00')) {
          tagEnd = i;

          for (int e = tagEnd; e >= 0; e--) {
            if (input[e] == '{' && (input[i - 1] != r'\' && input.at(e + 1) != '\x00')) {
              tagStart = e + 1;

              final toParse = input.substring(tagStart, tagEnd).trim();
              final [tagName, ...split] = toParse.split(':');
              final rawArgs = split.join(':').replaceAll(RegExp(r'\\\|'), '\x00|');
              final args = <String>[];

              String currentArg = '';
              for (int j = 0; j < rawArgs.length; j++) {
                if (rawArgs[j] == '|' && rawArgs[j - 1] != '\x00') {
                  args.add(currentArg);
                  currentArg = '';
                } else {
                  currentArg += rawArgs[j];
                }
              }

              if (currentArg.isNotEmpty) {
                args.add(currentArg);
              }

              final before = input.substring(0, tagStart - 1);
              final after = input.substring(tagEnd + 1, input.length);

              final tagResult = escapeTag((await getData(tagName, rawArgs, args, tagArgs, tag)).toString());
              input = before + tagResult + after;
              i = before.length + tagResult.length - 1;
              break;
            }
          }
        }
      }
    }

    if (initial) {
      input = await subParse(input, tag, tagArgs);
    }

    return input;
  }

  static String escapeTag(String tag) => tag.replaceAll('{', '{\x00').replaceAll('}', '\x00}').replaceAll(r'|', '\x00|');
}

class ParserResult {
  final bool isSuccess;
  // final bool isNsfw;
  // final List<Attachment> attachments;
  final String result;

  const ParserResult({
    required this.isSuccess,
    // required this.isNsfw,
    // required this.attachments,
    required this.result,
  });
}

extension on String {
  /// Like [operator.[]] but returns null if the index is out of bounds.
  /// Also allows negative indices.
  String? at(int index) {
    if (index < 0) {
      index = length + index;
    }

    if (index < 0 || index >= length) {
      return null;
    }

    return this[index];
  }
}
