/*
 * Kiwii, a stupid Discord bot.
 * Copyright (C) 2019-2024 Rapougnac
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

// import 'package:nyxx/nyxx.dart';
// import 'package:nyxx_lavalink/nyxx_lavalink.dart';

// class Lavalink {
//   final ICluster cluster;
//   final INyxxWebsocket client;

//   Lavalink(this.client, this.cluster);

//   static Future<Lavalink> connect(INyxxWebsocket client) async {
//     final cluster = ICluster.createCluster(client, client.appId);

//     await cluster.addNode(NodeOptions(
//       host: 'lavalink', // Lavalink is linked in as `lavalink` in docker-compose.yml
//       port: 2333,
//       password: 'youshallnotpass',
//       shards: client.shardManager.totalNumShards,
//       maxConnectAttempts: 10, // Bump up connection attempts to avoid timeouts in Docker
//     ));

//     return Lavalink(client, cluster);
//   }

//   // TODO: Add methods for interacting with Lavalink here
// }
