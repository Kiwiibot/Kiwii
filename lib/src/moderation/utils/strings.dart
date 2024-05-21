import '../../../translations.g.dart';
import '../case/create_case.dart';

String formatCaseAction(CaseAction key, Translations t, [bool isCase = false]) => switch (key) {
  CaseAction.role => t['moderation.history.actionLabel.restriction${isCase ? 'Case' : ''}'],
  CaseAction.unrole => t['moderation.history.actionLabel.unrestriction${isCase ? 'Case' : ''}'],
  CaseAction.warn => t.moderation.history.actionLabel.warn,
  CaseAction.kick => t.moderation.history.actionLabel.kick,
  CaseAction.softBan => t.moderation.history.actionLabel.softban,
  CaseAction.ban => t.moderation.history.actionLabel.ban,
  CaseAction.timeout => t.moderation.history.actionLabel.timeout,
  CaseAction.timeoutEnd => t.moderation.history.actionLabel.timeoutEnd,
  CaseAction.unban => t.moderation.history.actionLabel.unban,
};
