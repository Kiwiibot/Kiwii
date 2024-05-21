import 'package:nyxx/nyxx.dart';
import 'package:nyxx_commands/nyxx_commands.dart';
import 'package:string_similarity/string_similarity.dart';

import '../../plugins/localization.dart';

Iterable<CommandOptionChoiceBuilder<String>> reasonAutoComplete(AutocompleteContext ctx) {
  final input = ctx.currentValue.trim();

  final reasons = input.bestMatch(ctx.guild.t.moderation.common.reasons);

  return input.isEmpty
      ? ctx.guild.t.moderation.common.reasons.map(
          (r) => CommandOptionChoiceBuilder(
            name: r,
            value: r,
          ),
        )
      : reasons.ratings.where((value) => (value.rating ?? 0) >= 0.1).map(
            (e) => CommandOptionChoiceBuilder<String>(
              name: e.target ?? '',
              value: e.target ?? '',
            ),
          );
}
