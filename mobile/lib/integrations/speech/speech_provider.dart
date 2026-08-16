import 'package:speech_to_text/speech_to_text.dart';

/// Speech-to-text provider interface. Do not couple the product to one vendor.
abstract class SpeechToTextProvider {
  Future<bool> initialize();
  Future<void> start({
    List<String> languageHints = const ['ar-LB', 'en'],
    void Function(String words)? onPartial,
  });
  Future<String> stopAndTranscribe();
  Future<void> cancel();
}

/// Uses the phone's built-in recognizer (Android Speech Services / iOS).
class DeviceSpeechToTextProvider implements SpeechToTextProvider {
  DeviceSpeechToTextProvider({SpeechToText? engine}) : _engine = engine ?? SpeechToText();

  final SpeechToText _engine;
  String _buffer = '';
  bool _ready = false;

  @override
  Future<bool> initialize() async {
    _ready = await _engine.initialize();
    return _ready;
  }

  @override
  Future<void> start({
    List<String> languageHints = const ['ar-LB', 'en'],
    void Function(String words)? onPartial,
  }) async {
    if (!_ready) {
      _ready = await _engine.initialize();
    }
    if (!_ready) {
      throw StateError('unavailable');
    }
    _buffer = '';
    final locale = await _pickLocale(languageHints);
    await _engine.listen(
      onResult: (result) {
        _buffer = result.recognizedWords;
        onPartial?.call(_buffer);
      },
      listenOptions: SpeechListenOptions(
        localeId: locale,
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 4),
        partialResults: true,
        cancelOnError: true,
        listenMode: ListenMode.dictation,
      ),
    );
  }

  @override
  Future<String> stopAndTranscribe() async {
    await _engine.stop();
    return _buffer.trim();
  }

  @override
  Future<void> cancel() async {
    await _engine.cancel();
    _buffer = '';
  }

  Future<String?> _pickLocale(List<String> hints) async {
    final locales = await _engine.locales();
    if (locales.isEmpty) return null;
    final preferArabic = hints.any((hint) => hint.toLowerCase().startsWith('ar'));
    if (preferArabic) {
      for (final locale in locales) {
        if (locale.localeId.toLowerCase().startsWith('ar')) {
          return locale.localeId;
        }
      }
    }
    for (final locale in locales) {
      if (locale.localeId.toLowerCase().startsWith('en')) {
        return locale.localeId;
      }
    }
    return locales.first.localeId;
  }
}
