import 'package:nyxx/nyxx.dart';
import 'package:nyxx_commands/nyxx_commands.dart';

import '../../plugins/localization.dart';
import '../moderation/case/find_case.dart';
import '../moderation/utils/strings.dart';

Future<Iterable<CommandOptionChoiceBuilder<String>>> caseAutoCompleteNoHistory(AutocompleteContext ctx) => caseAutoComplete()(ctx);

Future<Iterable<CommandOptionChoiceBuilder<String>>> caseAutoCompleteWithHistory(AutocompleteContext ctx) => caseAutoComplete(showHistory: true)(ctx);

Future<Iterable<CommandOptionChoiceBuilder<String>>> Function(AutocompleteContext) caseAutoComplete({bool showHistory = false}) => (ctx) async {
      try {
        final cases = await listCases(ctx.currentValue.trim(), ctx.guild!.id);
        var choices = cases.map(
          (c) => CommandOptionChoiceBuilder(
            name: '#${c.caseId} ${formatCaseAction(c.action, ctx.guild.t)} ${c.targetTag}: ${c.reason ?? ctx.guild.t.moderation.common.noReason}',
            value: c.caseId.toString(),
          ),
        );

        final uniqueTargets = <Snowflake, Map<String, dynamic>>{};

        for (final case_ in cases) {
          if (uniqueTargets.containsKey(case_.targetId)) {
            continue;
          }

          uniqueTargets[case_.targetId] = {'id': case_.targetId, 'tag': case_.targetTag};
        }

        if (uniqueTargets.length == 1 && showHistory) {
          final target = uniqueTargets.values.first;

          choices = [
            CommandOptionChoiceBuilder(
              name: ctx.guild.t.moderation.history.cases.showHistory(user: target['tag']),
              value: 'history;${target['id']}',
            ),
            ...choices,
          ];
        }
        return choices.take(25);
      } catch (e) {
        return [];
      }
    };
