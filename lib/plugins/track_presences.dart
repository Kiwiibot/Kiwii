import 'package:nyxx/nyxx.dart';

typedef Presence = ({UserStatus? status, List<Activity>? activities, ClientStatus? clientStatus});

late final Cache<Presence> presences;

class TrackPresences extends NyxxPlugin<NyxxGateway> {
  @override
  Future<void> afterConnect(client) async {
    presences = client.cache.getCache('presences', CacheConfig<Presence>(maxSize: 1000));

    client.onPresenceUpdate.listen((event) async {
      final user = await event.user?.get();

      if (user == null) {
        return;
      }

      presences[user.id] = (status: event.status, activities: event.activities, clientStatus: event.clientStatus);
    });
  }
}
