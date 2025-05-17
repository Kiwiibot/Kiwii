/// Represents a single ANSI escape code pair (open and close).
class AnsiCode {
  final String open;
  final String close;
  final RegExp rgx;

  AnsiCode(int openCode, int closeCode)
    : open = '\x1b[${openCode}m',
      close = '\x1b[${closeCode}m',
      // The regex matches the closing escape code globally.
      rgx = RegExp('\\x1b\\[${closeCode}m', multiLine: true);
}

/// Applies a list of ANSI codes to a given text string.
/// This function handles nested styles by replacing inner close codes.
String _run(List<AnsiCode> codes, String text) {
  String beg = '';
  String end = '';
  String processedText = text;

  for (var code in codes) {
    beg += code.open;
    end += code.close;
    // If the closing code is found within the text, replace it
    // to ensure proper nesting (e.g., red bold text inside red).
    if (processedText.contains(code.close)) {
      processedText = processedText.replaceAll(code.rgx, code.close + code.open);
    }
  }
  return beg + processedText + end;
}

/// The `Style` class allows chaining of multiple text modifiers and colors,
/// and is callable to apply the accumulated styles to a string.
class Style {
  // Keeps track of the integer open codes to avoid applying the same style twice.
  final List<int> openCodes;
  // Stores the AnsiCode objects for the currently accumulated styles.
  final List<AnsiCode> ansiCodes;

  Style({this.openCodes = const [], this.ansiCodes = const []});

  /// Private method to create a new `Style` instance with an additional ANSI code.
  Style _withStyle(int openCode, int closeCode) {
    final AnsiCode newCode = AnsiCode(openCode, closeCode);
    final List<int> newOpenCodes = List.of(openCodes);
    final List<AnsiCode> newAnsiCodes = List.of(ansiCodes);

    if (!newOpenCodes.contains(openCode)) {
      newOpenCodes.add(openCode);
      newAnsiCodes.add(newCode);
    }
    // Return a new Style instance to enable chaining.
    return Style(openCodes: newOpenCodes, ansiCodes: newAnsiCodes);
  }

  String call(String text) {
    return _run(ansiCodes, text);
  }

  Style get reset => _withStyle(0, 0);
  Style get bold => _withStyle(1, 22);
  Style get dim => _withStyle(2, 22);
  Style get italic => _withStyle(3, 23);
  Style get underline => _withStyle(4, 24);
  Style get inverse => _withStyle(7, 27);
  Style get hidden => _withStyle(8, 28);
  Style get strikethrough => _withStyle(9, 29);

  Style get black => _withStyle(30, 39);
  Style get red => _withStyle(31, 39);
  Style get green => _withStyle(32, 39);
  Style get yellow => _withStyle(33, 39);
  Style get blue => _withStyle(34, 39);
  Style get magenta => _withStyle(35, 39);
  Style get cyan => _withStyle(36, 39);
  Style get white => _withStyle(37, 39);
  Style get gray => _withStyle(90, 39);
  Style get grey => gray;

  Style get bgBlack => _withStyle(40, 49);
  Style get bgRed => _withStyle(41, 49);
  Style get bgGreen => _withStyle(42, 49);
  Style get bgYellow => _withStyle(43, 49);
  Style get bgBlue => _withStyle(44, 49);
  Style get bgMagenta => _withStyle(45, 49);
  Style get bgCyan => _withStyle(46, 49);
  Style get bgWhite => _withStyle(47, 49);
}

class Ansi {
  Style get reset => Style().reset;
  Style get bold => Style().bold;
  Style get dim => Style().dim;
  Style get italic  => Style().italic;
  Style get underline => Style().underline;
  Style get inverse => Style().inverse;
  Style get hidden => Style().hidden;
  Style get strikethrough => Style().strikethrough;

  Style get black => Style().black;
  Style get red => Style().red;
  Style get green => Style().green;
  Style get yellow => Style().yellow;
  Style get blue => Style().blue;
  Style get magenta => Style().magenta;
  Style get cyan => Style().cyan;
  Style get white => Style().white;
  Style get gray => Style().gray;
  Style get grey => Style().grey;

  Style get bgBlack => Style().bgBlack;
  Style get bgRed => Style().bgRed;
  Style get bgGreen => Style().bgGreen;
  Style get bgYellow => Style().bgYellow;
  Style get bgBlue => Style().bgBlue;
  Style get bgMagenta => Style().bgMagenta;
  Style get bgCyan => Style().bgCyan;
  Style get bgWhite => Style().bgWhite;
}

final ansi = Ansi();
