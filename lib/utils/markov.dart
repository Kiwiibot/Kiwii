import 'dart:math';

import 'utils.dart';

class Markov {
  static final wordSeparator = RegExp(r'[, ]');
  static final parseBy = RegExp(r'[?\n]|\.\s+');

  final WordCache _wordCache = {};
  final MarkovNormalizer _normalizer;
  late MarkovEndFunction endFn;
  var _sentence = StringBuffer();

  Markov([MarkovNormalizer? normalizeFn]) : _normalizer = (normalizeFn ?? (word) => word.replaceAll(RegExp(r'\.$'), '')) {
    endFn = () => _countWords() > 7;
  }

  MarkovStartFunction startFn = (WordCache wordCache) => wordCache.keys.elementAt(Random().nextInt(wordCache.length));

  StringBuffer process() {
    String? currentWord = startFn(_wordCache);
    if (currentWord.isEmpty) {
      return StringBuffer('');
    }

    _sentence = StringBuffer(currentWord);
    Map<String, int>? word;

    while ((word = _wordCache[currentWord]) != null && !endFn()) {
      currentWord = pickByWeights(word!);
      _sentence.write(' $currentWord');
    }

    return _sentence;
  }

  void end(int i) {
    endFn = () => _countWords() > i;
  }

  int _countWords() => _sentence.toString().split(wordSeparator).length;

  Markov parse([String text = '', RegExp? parseBy]) {
    parseBy ??= Markov.parseBy;

    for (final line in text.split(parseBy)) {
      final words = _retrieveWords(line);

      for (int i = 0, max = words.length - 1; i < max; i++) {
        final current = _normalizer(words[i]);
        final next = _normalizer(words[i + 1]);

        var currentWordCache = _wordCache[current] ?? <String, int>{};
        _wordCache.putIfAbsent(current, () => currentWordCache);

        final currentCount = currentWordCache[next] ?? 0;
        currentWordCache[next] = currentCount + 1;
      }
    }

    return this;
  }

  static List<String> _retrieveWords(String line) => [
        for (final word in line.split(wordSeparator))
          if (word.trim().isNotEmpty) word.trim(),
      ];
}

typedef WordCache = Map<String, Map<String, int>>;
typedef MarkovNormalizer = String Function(String);
typedef MarkovEndFunction = bool Function();
typedef MarkovStartFunction = String Function(WordCache);
