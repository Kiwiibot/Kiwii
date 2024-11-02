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

import 'dart:io';

import 'package:kiwii/kiwii.dart';
import 'package:nyxx/nyxx.dart';

void main(List<String> args) async {
  final client = await Nyxx.connectGateway('OTQzNTE0NDc5NTQ1NzA4NjA0.GJHe5P.CEd_MJ5U2vozstdiX8DxffghLQEFA3TQe_VwHk', GatewayIntents.all,
      options: GatewayClientOptions(plugins: [logging, ignoreExceptions]));

  client.onMessageCreate.listen((event) async {
    if (event.message.content == 'yop') {
      // final guild = (await event.guild!.get());
      // await guild.createBan(const Snowflake(1081004946872352958), deleteMessages: const Duration(days: 0));
      // await guild.deleteBan(const Snowflake(1081004946872352958));
      // await guild.members.addRole(const Snowflake(1081004946872352958), const Snowflake(1258344089477189633));

      final button = ButtonBuilder(style: ButtonStyle.primary, label: 'Yop', customId: 'yop');

      await event.message.channel.sendMessage(MessageBuilder(components: [
        ActionRowBuilder(components: [button])
      ]));
    }
  });

  client.onMessageComponentInteraction.listen((event) async {
    print(event.interaction.message?.interactionMetadata);
    if (event.interaction.data.customId == 'yop') {
      final modal = ModalBuilder(customId: 'modal', title: 'Yup', components: [
        ActionRowBuilder(components: [TextInputBuilder(customId: 'no', style: TextInputStyle.short, label: 'yo')])
      ]);

      // await event.interaction.acknowledge();
      await event.interaction.respondModal(modal);
    }
  });

  client.onModalSubmitInteraction.listen(print);

  // print([1,2,3].at(-2));
}
