import 'package:nyxx/nyxx.dart';
import 'package:nyxx_commands/nyxx_commands.dart';

import '../../plugins/localization.dart';
import '../../utils/constants.dart';

final settingsCommand = ChatGroup(
  'settings',
  'Manage the settings of the bot for this guild',
  checks: [
    GuildCheck.all(),
  ],
  children: [
    ChatCommand(
      'locale',
      'Set the locale of the bot',
      id(
        'settings-locale',
        (ChatContext ctx, @Choices(choicesLocale) String locale) async {
          final appLocale = convertLocale(locale);

          if (appLocale == null) {
            return ctx.respond(MessageBuilder(content: 'Invalid locale'));
          }
          
          await localization.setLocale(appLocale, ctx.guild!.id);
          await ctx.respond(MessageBuilder(content: 'Locale set to `$locale`'));
        },
      ),
    ),
  ],
);
