import 'package:nyxx/nyxx.dart';

abstract base class Notifier {
  final Guild guild;

  const Notifier({required this.guild});

  Stream<Map<String, dynamic>> get onNewItems;

  Future<void> start();

  Future<void> stop();
}
