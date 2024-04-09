const defaultSever = 'https://emkc.org';

abstract interface class Piston {
  /// The server to use for piston.
  final String server;

  const Piston({this.server = defaultSever});
}

