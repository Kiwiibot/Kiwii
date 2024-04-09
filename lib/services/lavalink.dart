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
