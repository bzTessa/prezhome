/// Lógica PURA de las órdenes de voz del modo cocina (manos libres).
library;

enum CookCommand { next, previous, repeat, startTimer, stopTimer, ingredients }

const _next = {'siguiente', 'sigue', 'continua', 'adelante', 'listo', 'hecho'};
const _previous = {'anterior', 'atras', 'vuelve'};
const _repeat = {'repite', 'repetir', 'repiteme'};
const _timer = {'temporizador', 'cronometro', 'alarma'};
const _stop = {'para', 'parar', 'paralo', 'deten', 'quita', 'cancela'};

/// Traduce lo que ha oído el micrófono a una orden, o null si no hay ninguna.
/// Mira palabras sueltas (sin tildes), no trozos: "listón" no es "listo".
CookCommand? parseCookCommand(String heard) {
  const from = 'áéíóúü';
  const to = 'aeiouu';
  var s = heard.toLowerCase();
  for (var i = 0; i < from.length; i++) {
    s = s.replaceAll(from[i], to[i]);
  }
  final words = s.split(RegExp(r'[^a-zñ]+')).toSet();
  if (words.any(_timer.contains)) {
    return words.any(_stop.contains)
        ? CookCommand.stopTimer
        : CookCommand.startTimer;
  }
  if (words.contains('ingredientes') || words.contains('ingrediente')) {
    return CookCommand.ingredients;
  }
  if (words.any(_repeat.contains) || s.contains('otra vez')) {
    return CookCommand.repeat;
  }
  if (words.any(_previous.contains)) return CookCommand.previous;
  if (words.any(_next.contains)) return CookCommand.next;
  return null;
}
