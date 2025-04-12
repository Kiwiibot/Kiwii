import 'package:nyxx/nyxx.dart';

typedef Presence = ({UserStatus? status, List<Activity>? activities, ClientStatus? clientStatus});

final presences = <User, Presence>{};

class TrackPresences extends NyxxPlugin<NyxxGateway> {
  @override
  Future<void> afterConnect(client) async {
    client.onPresenceUpdate.listen((event) async {
      final user = await event.user?.get();

      if (user == null) {
        return;
      }

      presences[user] = (status: event.status, activities: event.activities, clientStatus: event.clientStatus);
    });
  }
}
