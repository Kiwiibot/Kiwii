
// final guildModuleConverter = Converter<GuildModule>(
//   (view, context) => switch (view.getQuotedWord()) {
//     'starboard' => GuildModule.starboard,
//     'moderation' => GuildModule.moderation,
//     'tags' => GuildModule.tags,
//     _ => null,
//   },
//   choices: GuildModule.values.map(
//     (m) => CommandOptionChoiceBuilder(
//       name: m.name.firstLetterUpperCase,
//       value: m.name,
//     ),
//   ),
// );
