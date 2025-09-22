// ignore_for_file: implementation_imports

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

import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:hourglass/hourglass.dart';
import 'package:hourglass/locale.dart';
import 'package:nyxx/nyxx.dart';
import 'package:nyxx_commands/nyxx_commands.dart';
import 'package:nyxx_commands/src/converters/built_in/user.dart' as nyxx_commands;
import 'package:nyxx_commands/src/converters/built_in/member.dart' as nyxx_commands;
import 'package:nyxx_commands/src/converters/built_in/string.dart' as nyxx_commands;
import 'package:nyxx_commands/src/converters/built_in/bool.dart' as nyxx_commands;
import 'package:nyxx_commands/src/converters/built_in/snowflake.dart' as nyxx_commands;

import 'package:nyxx_extensions/nyxx_extensions.dart';

import '../../plugins/base.dart';
import '../../plugins/load_modules.dart';
import '../../plugins/localization.dart';
import '../../translations.g.dart';
import '../../utils/utils.dart';
import '../models/tag.dart';

Future<Iterable<Tag>> getTags(ContextData ctx) => ctx.client.repositories.tags.findAll(ctx.guild!.id);
String stringifyTag(Tag tag) => tag.name;

BasePlugin? getBasePlugin(StringView view, ContextData ctx) {
  final guild = ctx.guild;

  if (guild == null) {
    return null;
  }

  if (view.getWord().isEmpty) {
    return null;
  }

  view.undo();

  final word = view.getQuotedWord();

  final mod = guild.modules[word] ?? modules[word];

  if (mod == null) {
    return null;
  }

  return mod;
}

ChatCommand? convertChatCommand(StringView view, ContextData ctx) => ctx.commands.getCommand(StringView(view.getQuotedWord()), ctx.guild?.id);

List<String>? convertListString(StringView view, ContextData ctx) => [for (; !view.eof;) view.getWord()];

String stringifyLocale(AppLocale locale) => switch (locale) {
  AppLocale.enGb => 'English (United Kingdom) - English (United Kingdom)',
  AppLocale.frFr => 'Français (France) - French (France)',
};

AppLocale? reviverLocale(StringView view, ContextData ctx) => {'en-GB': AppLocale.enGb, 'fr-FR': AppLocale.frFr}[view.getWord()];

Future<Iterable<CommandOptionChoiceBuilder<String>>> autocompleteModules(AutocompleteContext ctx) async {
  final isUnload = ctx.command.name == 'unload';

  final current = ctx.currentValue.toLowerCase();
  final guild = await ctx.client.repositories.guilds.getOrNull(ctx.guild!.id);
  final mods = isUnload ? ctx.guild!.modules : modules;
  final filtered = mods.values.where((module) => module.name.toLowerCase().contains(current) & (guild != null && !guild.enabledModules.contains(module.name)));

  return (filtered.isEmpty ? mods.values : filtered).map((e) => CommandOptionChoiceBuilder(name: e.name, value: e.name));
}

Iterable<CommandOptionChoiceBuilder<dynamic>> autocompleteChatCommands(AutocompleteContext ctx) {
  final current = ctx.currentValue;
  final filtered =
      ctx.commands.walkCommands(ctx.guild?.id).where((element) => (element is ChatCommand ? element.fullName : element.name).contains(current)).toList();
  final maxLen = min(filtered.length, 25);
  return filtered
      .sublist(0, maxLen)
      .map((e) => CommandOptionChoiceBuilder(name: e is ChatCommand ? e.fullName : e.name, value: e is ChatCommand ? e.fullName : e.name));
}

/// Parse a JSON code block into a map object.
Map<String, Object?>? convertMapObject(StringView view, ContextData ctx) {
  view.skipWhitespace();
  view.skipFirst(RegExp(r'```(?:json)?\n?'));

  final raw = view.getUntil('```');

  view.skipFirst('```');

  if (raw.isEmpty) return null;

  Map<String, Object?> ret;

  try {
    ret = json.decode(raw) as Map<String, Object?>;
  } catch (e) {
    return null;
  }

  return ret;
}

HttpRoute? convertHttpRoute(StringView view, ContextData ctx) {
  String getRoute() {
    view.skipWhitespace();
    view.skipPattern('\n');

    int start = view.index;

    while (!view.eof && view.current != '\n') {
      view.index++;
    }

    return view.escape(start, view.index);
  }

  final r = getRoute();

  final rawParts = r.split('/').where((e) => e.isNotEmpty).map((e) => HttpRouteWrapper(route: e)).toList();

  final parts =
      rawParts.indexed
          .map((e) {
            final p = e.$2;
            final i = e.$1;

            if (p.isDone) {
              return null;
            }

            if (p.route case 'guilds' || 'channels') {
              return HttpRoutePart(p.route, [
                if (rawParts.elementAtOrNull(i + 1) != null) HttpRouteParam((rawParts[i + 1]..isDone = true).route, isMajor: true),
              ]);
            } else {
              return HttpRoutePart(p.route, [if (rawParts.elementAtOrNull(i + 1) != null) HttpRouteParam((rawParts[i + 1]..isDone = true).route)]);
            }
          })
          .nonNulls
          .toList();

  final route = HttpRoute();

  parts.forEach(route.add);

  return route;
}

class HttpRouteWrapper {
  bool isDone;

  final String route;

  HttpRouteWrapper({required this.route, this.isDone = false});
}

Duration? convertDuration(StringView view, ContextData ctx) {
  final loc = switch (ctx.guild.t.$meta.locale) {
    AppLocale.enGb => EnglishDurationLocale(),
    AppLocale.frFr => FrenchDurationLocale(),
  };

  try {
    return parseDuration(view.getQuotedWord(), separator: ', ', language: loc);
  } catch (_) {
    return null;
  }
}

const List<int> powersOfTwo = [16, 32, 64, 128, 256, 512, 1024, 2048, 4096];

/// Converts a string representation of an image size to the closest power of two
/// within the range of 16 to 4096 (inclusive).
///
/// The function parses an integer from the `StringView`. If the parsing fails,
/// it defaults to returning 16, which is the lowest allowed power of two.
///
/// It then iterates through predefined powers of two (16, 32, 64, 128, 256, 512,
/// 1024, 2048, 4096) and determines which one is numerically closest to the
/// parsed integer. In case of a tie (where two powers of two are equally close),
/// the smaller power of two is preferred.
///
/// Returns the closest power of two (16, 32, ..., 4096) to the parsed integer.
int? convertImageSize(StringView view, ContextData ctx) {
  String rawValue = view.getWord();
  int? parsedInt = int.tryParse(rawValue);

  if (parsedInt == null) {
    return 16;
  }

  int closestPower = powersOfTwo.first;
  int minDifference = (parsedInt - closestPower).abs();

  for (int power in powersOfTwo) {
    int currentDifference = (parsedInt - power).abs();

    if (currentDifference < minDifference) {
      minDifference = currentDifference;
      closestPower = power;
    }
    // If the current power is equally close, we apply a tie-breaking rule:
    // prefer the smaller power of two. This ensures consistent results, e.g.,
    // if 48 is input, both 32 and 64 are 16 units away; this logic picks 32.
    else if (currentDifference == minDifference) {
      if (power < closestPower) {
        closestPower = power;
      }
    }
  }

  return closestPower;
}

class ChoicedConverter<T> extends Converter<T> {
  @override
  Iterable<CommandOptionChoiceBuilder<dynamic>>? get choices => choicesList.map((choice) => CommandOptionChoiceBuilder(name: stringify(choice), value: choice));

  final List<T> choicesList;

  final String Function(T) stringify;

  const ChoicedConverter(
    super.convert, {
    required this.choicesList,
    super.autocompleteCallback,
    super.processOptionCallback,
    super.toButton,
    super.toSelectMenuOption,
    super.type = CommandOptionType.string,
    this.stringify = _stringify,
  });
}

Future<List<T>> waitFor<T>(Iterable<FutureOr<T>> futures, {bool eagerError = false, void Function(T)? cleanup}) =>
    Future.wait<T>(futures.map((f) => f is Future<T> ? f : Future.value(f)), eagerError: eagerError, cleanUp: cleanup);

String _stringify(dynamic t) => t.toString();

Future<User?> convertUser(StringView view, ContextData ctx) async {
  String word = view.getQuotedWord();

  final m = userMentionRegex.firstMatch(word);

  if (m?[1] case final m?) {
    return ctx.client.users.get(Snowflake.parse(m));
  }

  final users = await waitFor(switch (ctx.guild) {
    final guild? => (await ctx.client.gateway.listGuildMembers(guild.id).toList()).map((member) => nyxx_commands.memberToUser(member, ctx) as FutureOr<User>),
    _ => switch (ctx.channel) {
      DmChannel(:final recipient) => [await ctx.client.user.fetch(), recipient],
      GroupDmChannel(:final recipients) => [await ctx.client.user.fetch(), ...recipients],
      _ => ctx.client.users.cache.values,
    },
  });

  if (word case '@me') {
    return ctx.user;
  }

  List<User> usernameExact = [];
  List<User> globalNameExact = [];

  List<User> usernameCaseInsensitive = [];
  List<User> globalNameCaseInsensitive = [];

  List<User> usernameStart = [];
  List<User> globalNameStart = [];

  List<User> usernameContain = [];
  List<User> globalNameContain = [];

  for (final user in users) {
    if (user.username == word) {
      usernameExact.add(user);
    }

    if (user.globalName == word) {
      globalNameExact.add(user);
    }

    if (user.username.toLowerCase() == word.toLowerCase()) {
      usernameCaseInsensitive.add(user);
    }

    if (user.globalName?.toLowerCase() == word.toLowerCase()) {
      globalNameCaseInsensitive.add(user);
    }

    if (user.username.toLowerCase().startsWith(word.toLowerCase())) {
      usernameStart.add(user);
    }

    if (user.globalName?.toLowerCase().startsWith(word.toLowerCase()) ?? false) {
      globalNameStart.add(user);
    }

    if (user.username.toLowerCase().contains(word.toLowerCase())) {
      usernameContain.add(user);
    }

    if (user.globalName?.toLowerCase().contains(word.toLowerCase()) ?? false) {
      globalNameContain.add(user);
    }

    for (final list in [
      usernameExact,
      globalNameExact,
      usernameCaseInsensitive,
      globalNameCaseInsensitive,
      usernameStart,
      globalNameStart,
      usernameContain,
      globalNameContain,
    ]) {
      if (list.length == 1) {
        return list.first;
      }
    }
  }

  return null;
}

Future<Message?> snowflakeToMessage(Snowflake snowflake, ContextData ctx) async {
  try {
    return await ctx.channel.messages.get(snowflake);
  } on HttpResponseError {
    // nothing
  }

  final channels = ctx.guild?.cachedChannels.whereType<GuildTextChannel>();

  if (channels == null) {
    return null;
  }

  for (final channel in channels) {
    try {
      return channel.messages.get(snowflake);
    } on HttpResponseError {
      continue;
    }
  }

  return null;
}

final messageLinkPattern = RegExp(
  r'(?:https?:\/\/(?:ptb\.|canary\.)?discord(?:app)?\.com\/channels\/(?<guildId>\d{17,20})\/(?<channelId>\d{17,20})\/(?<messageId>\d{17,20}))',
  caseSensitive: true,
);

Future<Message?> convertMessage(StringView view, ContextData ctx) async {
  final url = view.getQuotedWord();

  final match = messageLinkPattern.firstMatch(url);

  if (match == null) {
    return null;
  }

  final _ = Snowflake.parse(match.namedGroup('guildId')!),
      channelId = Snowflake.parse(match.namedGroup('channelId')!),
      messageId = Snowflake.parse(match.namedGroup('messageId')!);

  return ((await ctx.client.channels.get(channelId)) as GuildTextChannel).messages.get(messageId);
}

Future<Member?> convertMember(StringView view, ContextData ctx) async {
  String word = view.getQuotedWord();

  if (ctx.guild != null) {
    if (word case '@me') {
      return ctx.member;
    }

    Stream<Member> named = ctx.client.gateway.listGuildMembers(ctx.guild!.id, query: word, limit: 100);

    List<Member> usernameExact = [];
    List<Member> globalNameExact = [];
    List<Member> nickExact = [];

    List<Member> usernameCaseInsensitive = [];
    List<Member> globalNameCaseInsensitive = [];
    List<Member> nickCaseInsensitive = [];

    List<Member> usernameStart = [];
    List<Member> globalNameStart = [];
    List<Member> nickStart = [];

    List<Member> usernameContain = [];
    List<Member> globalNameContain = [];
    List<Member> nickContain = [];

    await for (final member in named) {
      User user = await ctx.client.users.get(member.id);

      if (user.username == word) {
        usernameExact.add(member);
      }
      if (user.username.toLowerCase() == word.toLowerCase()) {
        usernameCaseInsensitive.add(member);
      }
      if (user.username.toLowerCase().startsWith(word.toLowerCase())) {
        usernameStart.add(member);
      }

      if (user.username.toLowerCase().contains(word)) {
        usernameContain.add(member);
      }

      if (user.globalName != null) {
        if (user.globalName! == word) {
          globalNameExact.add(member);
        }

        if (user.globalName!.toLowerCase() == word.toLowerCase()) {
          globalNameCaseInsensitive.add(member);
        }

        if (user.globalName!.toLowerCase().startsWith(word)) {
          globalNameStart.add(member);
        }

        if (user.globalName!.toLowerCase().contains(word)) {
          globalNameContain.add(member);
        }
      }

      if (member.nick != null) {
        if (member.nick! == word) {
          nickExact.add(member);
        }
        if (member.nick!.toLowerCase() == word.toLowerCase()) {
          nickCaseInsensitive.add(member);
        }
        if (member.nick!.toLowerCase().startsWith(word.toLowerCase())) {
          nickStart.add(member);
        }

        if (member.nick!.toLowerCase().startsWith(word)) {
          nickContain.add(member);
        }
      }
    }

    for (final list in [
      usernameExact,
      globalNameExact,
      nickExact,
      usernameCaseInsensitive,
      globalNameCaseInsensitive,
      nickCaseInsensitive,
      usernameStart,
      globalNameStart,
      nickStart,
      usernameContain,
      globalNameContain,
      nickContain,
    ]) {
      if (list.length == 1) {
        return list.first;
      }
    }
  }
  return null;
}

Future<Object?> convertAnyToPrimitive(StringView view, ContextData ctx) async {
  final user = switch (await convertUser(view, ctx)) {
    final value? => value,
    _ =>
      await (() async {
        view.undo();
        return switch (await nyxx_commands.convertUser(view, ctx)) {
          final value? => value,
          _ =>
            (() {
              view.undo();

              return switch (nyxx_commands.convertSnowflake(view, ctx)) {
                final snowflake? => nyxx_commands.snowflakeToUser(snowflake, ctx),
                _ =>
                  (() {
                    view.undo();
                  })(),
              };
            })(),
        };
      })(),
  };

  if (user != null) {
    return user;
  }

  final b = nyxx_commands.convertBool(view, ctx);

  if (b != null) {
    return b;
  }

  view.undo();

  final string = nyxx_commands.convertString(view, ctx);

  if (string != null) {
    return string;
  }

  view.undo();

  return null;
}

Future<Emoji?> convertEmoji(StringView view, ContextData ctx) async {
  final word = view.getQuotedWord();

  final match = guildEmojiRegex.firstMatch(word);

  if (match?[3] case final m?) {
    final em =
        ctx.client.guilds.cache.values.where((g) => g.emojis.cache.containsKey(Snowflake.parse(m))).map((g) => g.emojis.cache[Snowflake.parse(m)]).firstOrNull;

    if (em != null) {
      return em;
    }

    return GuildEmoji(
      id: Snowflake.parse(m),
      manager: ctx.client.guilds[Snowflake.zero].emojis,
      name: match![2],
      roleIds: [],
      user: null,
      requiresColons: false,
      isManaged: false,
      isAnimated: match[1]?.isNotEmpty == true,
      isAvailable: false,
    );
  }

  if (word.isEmpty) {
    return null;
  }

  if (RegExp(r'\p{Extended_Pictographic}', unicode: true).hasMatch(word)) {
    return ctx.client.getTextEmoji(word);
  }

  return null;
}

const imageSizeConverter = ChoicedConverter<int>(convertImageSize, choicesList: powersOfTwo, type: CommandOptionType.integer);
const localeConverter = SimpleConverter.fixed(elements: [AppLocale.enGb, AppLocale.frFr], stringify: stringifyLocale, reviver: reviverLocale);
const basePluginConverter = Converter<BasePlugin>(getBasePlugin, autocompleteCallback: autocompleteModules);
const tagConverter = SimpleConverter(provider: getTags, stringify: stringifyTag);
const chatCommandConverter = Converter<ChatCommand>(convertChatCommand, autocompleteCallback: autocompleteChatCommands);
const listConverter = Converter<List<String>>(convertListString);
const mapObjectConverter = Converter<Map<String, Object?>>(convertMapObject);
const httpRouteConverter = Converter<HttpRoute>(convertHttpRoute);
const durationConverter = Converter<Duration>(convertDuration);
const _userConverter = Converter<User>(convertUser);
const userConverter = FallbackConverter(
  [nyxx_commands.userConverter, _userConverter],
  type: CommandOptionType.user,
  toButton: nyxx_commands.userToButton,
  toSelectMenuOption: nyxx_commands.userToSelectMenuOption,
);
const messageConverter = FallbackConverter<Message>([
  Converter<Message>(convertMessage),
  CombineConverter<Snowflake, Message>(snowflakeConverter, snowflakeToMessage),
]);
const memberConverter = FallbackConverter(
  [nyxx_commands.memberConverter, Converter<Member>(convertMember)],
  type: CommandOptionType.user,
  toButton: nyxx_commands.memberToButton,
  toSelectMenuOption: nyxx_commands.memberToSelectMenuOption,
);
const forumChannelConverter = GuildChannelConverter<ForumChannel>([ChannelType.guildForum]);
const primitiveConverter = Converter<Object>(convertAnyToPrimitive);
const emojiConverter = Converter<Emoji?>(convertEmoji);
