// /*
//  * Kiwii, a stupid Discord bot.
//  * Copyright (C) 2019-2024 Lexedia
//  * 
//  * This program is free software: you can redistribute it and/or modify
//  * it under the terms of the GNU General Public License as published by
//  * the Free Software Foundation, either version 3 of the License, or
//  * (at your option) any later version.
//  * 
//  * This program is distributed in the hope that it will be useful,
//  * but WITHOUT ANY WARRANTY; without even the implied warranty of
//  * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  * GNU General Public License for more details.
//  * 
//  * You should have received a copy of the GNU General Public License
//  * along with this program.  If not, see <https://www.gnu.org/licenses/>.
//  */

// import 'dart:convert';
// import 'dart:typed_data';

// import 'package:nyxx/nyxx.dart';
// import 'package:nyxx_extensions/nyxx_extensions.dart';
// import 'package:path/path.dart' as path;
// import 'package:archive/archive_io.dart';
// import 'package:universal_html/parsing.dart';

// final template = path.join('lib', 'utils', 'transcript', 'static', 'template.html');

// const sanitizer = HtmlEscape();

// final sanitize = sanitizer.convert;

// Future<Uint8List> generateTranscript(Iterable<Message> messages, GuildTextChannel channel) async {
//   final archive = TarEncoder();

//   archive.add(
//     ArchiveFile('assets/guild/', 0, null)
//       ..mode = 493
//       ..isFile = false,
//   );

//   final dom = parseHtmlDocument(template.replaceAll('{{TITLE}}', channel.name));
//   final guild = await channel.guild.get();

//   final guildIcon = await guild.icon?.fetch();

//   if (guildIcon != null) {
//     archive.add(
//       ArchiveFile('assets/guild/icon.png', guildIcon.length, guildIcon)
//         ..mode = 420
//         ..isFile = true,
//     );
//   }

//   dom.querySelector('.preamble__guild-icon')!.setAttribute('src', 'assets/guild/icon.png');
//   final guildName = dom.querySelector('#guild_name');
//   final channelName = dom.querySelector('#ticketname');
//   final link = dom.querySelector('link');
//   if (link != null) {
//     link.setAttribute('href', 'assets/guild/icon.png');
//   }
// }
