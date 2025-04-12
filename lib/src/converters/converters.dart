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

import 'dart:math';

import 'package:nyxx/nyxx.dart';
import 'package:nyxx_commands/nyxx_commands.dart';

import '../../plugins/base.dart';
import '../../plugins/load_modules.dart';
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

List<String> convertListString(StringView view, ContextData ctx) {
  final args = <String>[];
  while (!view.eof) {
    final word = view.getWord();
    args.add(word);
  }
  return args;
}

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

const localeConverter = SimpleConverter.fixed(elements: [AppLocale.enGb, AppLocale.frFr], stringify: stringifyLocale, reviver: reviverLocale);
const basePluginConverter = Converter<BasePlugin>(getBasePlugin, autocompleteCallback: autocompleteModules);
const tagConverter = SimpleConverter(provider: getTags, stringify: stringifyTag);
const chatCommandConverter = Converter<ChatCommand>(convertChatCommand, autocompleteCallback: autocompleteChatCommands);
const listConverter = Converter<List<String>>(convertListString);
