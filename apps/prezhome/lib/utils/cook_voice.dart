/// Lógica PURA de las órdenes de voz del modo cocina (manos libres).
library;

enum CookCommand { next, previous, repeat, startTimer, stopTimer, ingredients }

/// Palabras de cada orden por idioma (sin tildes): siguiente, anterior,
/// repetir, temporizador, parar e ingredientes.
const _words = <String, List<Set<String>>>{
  'es': [
    {'siguiente', 'sigue', 'continua', 'adelante', 'listo', 'hecho'},
    {'anterior', 'atras', 'vuelve'},
    {'repite', 'repetir', 'repiteme'},
    {'temporizador', 'cronometro', 'alarma'},
    {'para', 'parar', 'paralo', 'deten', 'quita', 'cancela'},
    {'ingredientes', 'ingrediente'},
  ],
  'en': [
    {'next', 'continue', 'done', 'ready', 'forward'},
    {'previous', 'back'},
    {'repeat', 'again'},
    {'timer', 'alarm'},
    {'stop', 'cancel'},
    {'ingredients', 'ingredient'},
  ],
  'de': [
    {'weiter', 'nachster', 'fertig'},
    {'zuruck', 'vorherige', 'vorheriger'},
    {'wiederhole', 'wiederholen', 'nochmal'},
    {'timer', 'wecker'},
    {'stopp', 'stop', 'stoppen', 'abbrechen'},
    {'zutaten', 'zutat'},
  ],
  'fr': [
    {'suivant', 'suivante', 'continue', 'fini'},
    {'precedent', 'precedente', 'retour'},
    {'repete', 'repeter', 'encore'},
    {'minuteur', 'chrono', 'alarme'},
    {'arrete', 'stop', 'annule'},
    {'ingredients', 'ingredient'},
  ],
  'it': [
    {'avanti', 'prossimo', 'successivo', 'fatto'},
    {'indietro', 'precedente'},
    {'ripeti', 'ancora'},
    {'timer', 'sveglia'},
    {'ferma', 'stop', 'annulla'},
    {'ingredienti', 'ingrediente'},
  ],
  'pt': [
    {'seguinte', 'proximo', 'continua', 'pronto', 'feito'},
    {'anterior', 'voltar', 'atras'},
    {'repete', 'repetir'},
    {'temporizador', 'cronometro', 'alarme'},
    {'para', 'parar', 'pare', 'cancela'},
    {'ingredientes', 'ingrediente'},
  ],
  'bs': [
    {'dalje', 'sljedeci', 'gotovo'},
    {'nazad', 'prethodni'},
    {'ponovi'},
    {'tajmer', 'alarm'},
    {'stani', 'zaustavi', 'stop', 'prekini'},
    {'sastojci', 'sastojak'},
  ],
};

const _from = 'áàâäãéèêëíìîïóòôöõúùûüçćčšžđß';
const _to = 'aaaaaeeeeiiiiooooouuuucccszds';

/// Traduce lo que ha oído el micrófono a una orden, o null si no hay ninguna.
/// [lang] es el idioma de la app ('es', 'en'...). Mira palabras sueltas (sin
/// tildes), no trozos: "listón" no es "listo".
CookCommand? parseCookCommand(String heard, [String lang = 'es']) {
  var s = heard.toLowerCase();
  for (var i = 0; i < _from.length; i++) {
    s = s.replaceAll(_from[i], _to[i]);
  }
  final [next, previous, repeat, timer, stop, ingredients] =
      _words[lang] ?? _words['es']!;
  final words = s.split(RegExp(r'[^a-zñ]+')).toSet();
  if (words.any(timer.contains)) {
    return words.any(stop.contains)
        ? CookCommand.stopTimer
        : CookCommand.startTimer;
  }
  if (words.any(ingredients.contains)) return CookCommand.ingredients;
  if (words.any(repeat.contains) || s.contains('otra vez')) {
    return CookCommand.repeat;
  }
  if (words.any(previous.contains)) return CookCommand.previous;
  if (words.any(next.contains)) return CookCommand.next;
  return null;
}
