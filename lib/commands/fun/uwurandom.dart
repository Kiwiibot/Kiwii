import 'package:nyxx/nyxx.dart';
import 'package:nyxx_commands/nyxx_commands.dart';
import 'package:uwurandom/uwurandom.dart';

final uwurandom = ChatCommand(
  'uwurandom',
  'cat /dev/uwurandom',
  id(
    'uwurandom',
    (
      ChatContext ctx, [
      @Choices({'Catgirlnonsense': 'catgirlnonsense', 'Keysmash': 'keysmash', 'Scrunkly': 'scrunkly', 'All': 'all'})
      @Description('The type of nonsense to generate')
      String? type = 'all',
      @UseConverter(IntConverter(min: 1, max: 512)) @Description('The length of the nonsense to generate') int length = 128,
    ]) async {
      final result = switch (type) {
        'catgirlnonsense' => catGirlNonSense.generate(length),
        'keysmash' => keySmash.generate(length),
        'scrunkly' => scrunkly.generate(length),
        'all' => nonSense.generate(length),
        _ => nonSense.generate(length),
      };

      await ctx.respond(
        MessageBuilder(
          content: result,
          allowedMentions: AllowedMentions(
            repliedUser: false,
          ),
        ),
      );
    },
  ),
);
