# Kiwii

Kiwii is a simple and stupid discord bot made to make your life easier. 
This includes a lot of features like:
- Moderation
- ??? That's fucking it

She's still in early development, even if it's been 6 years I'm working on it (yes, fr).

There's also a website (showcased below) that's written with [Astro](https://astro.build) and tailwind that supports oauth2 and other stupid things.

The bot is written in [Dart](https://dart.dev) and with [nyxx](https://github.com/nyxx-discord/nyxx).

![Showcase of the website](https://uwu.rapougnac.moe/u/RmjpK4.png)
![Showcase of the guilds page](https://uwu.rapougnac.moe/u/pmtmvG.png)

Note that I absolutely suck at UI design, so it's kinda ugly :3.


## Running

### Locally:
- Download [Dart](https://dart.dev/get-dart), then clone this repo.
- Run `dart pub get && dart build_runner build --delete-conflicting-outputs && dart run slang build` to install the required dependencies and files.
- Run `dart bin/migrations.dart upgrade` to apply migrations.
- Run `dart bin/emojis.dart` to map emojis, and `mv` it to `lib/utils/emojis.dart`.
- Finally, run `dart run` to start the bot in JIT. Or `dart run nyxx_commands:compile bin/kiwii.dart` for AOT.
