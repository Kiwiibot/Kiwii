import 'package:kiwii/utils/extensions.dart';
import 'package:nyxx/nyxx.dart';
import 'package:nyxx_commands/nyxx_commands.dart';

final sourceCommand = ChatCommand(
  'source',
  'Get the source of the specified command',
  id(
    'source',
    (ChatContext ctx, [@Autocomplete(autocompleteCallback) ChatCommand? command]) {
      final sourceUrl = 'https://github.com/Rapougnac/Kiwii',
      branch = 'mistress';
      if (command == null) {
        return ctx.send(sourceUrl);
      }

      final (start, end) = command.lines;
      final location = "lib/${command.filePath.split('package:kiwii').last}";

      final url = '<$sourceUrl/blob/$branch/$location#L$start-L$end>';

      return ctx.send(url);
    },
  ),
);

Iterable<CommandOptionChoiceBuilder<dynamic>> autocompleteCallback(AutocompleteContext ctx) {
  final current = ctx.currentValue;
  final filtered = ctx.commands.walkCommands().where((element) => element.name.contains(current)).toList();
  return filtered.map((e) => CommandOptionChoiceBuilder(name: e.name, value: e.name));
}