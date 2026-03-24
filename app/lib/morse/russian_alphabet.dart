import 'package:feel_you/morse/level.dart';
import 'package:feel_you/morse/morse_alphabet_data.dart';
import 'package:feel_you/morse/morse_language.dart';
import 'package:feel_you/morse/morse_signal.dart';
import 'package:feel_you/morse/morse_word_builder.dart';

const _d = MorseSignal.dot;
const _s = MorseSignal.dash;

/// Standard Russian telegraphic Morse code patterns for 32 Cyrillic letters.
///
/// Ё is excluded because it shares the same Morse pattern as Е (dot).
/// It is handled as an alias in [_russianWithAliases] for word composition.
const Map<String, List<MorseSignal>> _russianCharacters = {
  'А': [_d, _s],
  'Б': [_s, _d, _d, _d],
  'В': [_d, _s, _s],
  'Г': [_s, _s, _d],
  'Д': [_s, _d, _d],
  'Е': [_d],
  'Ж': [_d, _d, _d, _s],
  'З': [_s, _s, _d, _d],
  'И': [_d, _d],
  'Й': [_d, _s, _s, _s],
  'К': [_s, _d, _s],
  'Л': [_d, _s, _d, _d],
  'М': [_s, _s],
  'Н': [_s, _d],
  'О': [_s, _s, _s],
  'П': [_d, _s, _s, _d],
  'Р': [_d, _s, _d],
  'С': [_d, _d, _d],
  'Т': [_s],
  'У': [_d, _d, _s],
  'Ф': [_d, _d, _s, _d],
  'Х': [_d, _d, _d, _d],
  'Ц': [_s, _d, _s, _d],
  'Ч': [_s, _s, _s, _d],
  'Ш': [_s, _s, _s, _s],
  'Щ': [_s, _s, _d, _s],
  'Ъ': [_s, _s, _d, _s, _s],
  'Ы': [_s, _d, _s, _s],
  'Ь': [_s, _d, _d, _s],
  'Э': [_d, _d, _s, _d, _d],
  'Ю': [_d, _d, _s, _s],
  'Я': [_d, _s, _d, _s],
};

/// All 32 Russian letters in standard alphabetical order (Ё excluded).
const List<String> _russianOrder = [
  'А',
  'Б',
  'В',
  'Г',
  'Д',
  'Е',
  'Ж',
  'З',
  'И',
  'Й',
  'К',
  'Л',
  'М',
  'Н',
  'О',
  'П',
  'Р',
  'С',
  'Т',
  'У',
  'Ф',
  'Х',
  'Ц',
  'Ч',
  'Ш',
  'Щ',
  'Ъ',
  'Ы',
  'Ь',
  'Э',
  'Ю',
  'Я',
];

/// Extended Russian alphabet with variant character forms.
///
/// Ё shares the same Morse pattern as Е (dot). This alias is needed for
/// word pattern composition but is kept separate from the main alphabet
/// to avoid polluting reverse-lookups.
final Map<String, List<MorseSignal>> _russianWithAliases = {
  ..._russianCharacters,
  'Ё': _russianCharacters['Е']!, // Ё → same pattern as Е
};

/// All 20 Russian words in learning order:
/// chosen for practical daily communication needs of deaf-blind users.
const List<String> _russianWordList = [
  // 2-letter
  'ДА', 'НЕ', 'ОН', 'НУ', 'УЖ',
  // 3-letter
  'НЕТ', 'ЕДА', 'СОН', 'ДОМ', 'ПИЛ',
  // 4-letter
  'БОЛЬ', 'СТОП', 'ВОДА', 'ХОЧУ', 'ЖАРА',
  // 5-letter
  'СПАТЬ', 'УСТАЛ', 'ЖАРКО', 'ХОЛОД', 'ПУСТЬ',
];

/// The Russian Morse alphabet.
final MorseAlphabet russianAlphabet = MorseAlphabet(
  language: MorseLanguage.russian,
  characters: _russianCharacters,
  characterOrder: _russianOrder,
  wordList: _russianWordList,
  wordPatterns: buildWordPatterns(_russianWordList, _russianWithAliases),
  levels: [
    const Level(
      name: 'russian-letters',
      characters: _russianOrder,
      patterns: _russianCharacters,
      language: MorseLanguage.russian,
    ),
    Level(
      name: 'russian-words',
      characters: _russianWordList,
      patterns: buildWordSignalPatterns(_russianWordList, _russianWithAliases),
      language: MorseLanguage.russian,
    ),
  ],
);
