import 'dart:io';

class Stderr implements StringSink {
  /// The file to output to.
  final File file;

  /// The string sink to output to.
  final StringSink sink;

  /// Create a new instance of the [Stderr] sink.
  Stderr(this.file, this.sink);

  @override
  void write(Object? obj) {
    sink.write(obj);
    file.writeAsStringSync(obj.toString(), mode: FileMode.append);
  }

  @override
  void writeAll(Iterable<dynamic> objects, [String separator = '']) {
    sink.writeAll(objects, separator);
    file.writeAsStringSync(objects.join(separator), mode: FileMode.append);
  }

  @override
  void writeCharCode(int charCode) {
    sink.writeCharCode(charCode);
    file.writeAsStringSync(String.fromCharCode(charCode), mode: FileMode.append);
  }

  @override
  void writeln([Object? obj = '']) {
    sink.writeln(obj);
    file.writeAsStringSync('$obj\n', mode: FileMode.append);
  }
}
