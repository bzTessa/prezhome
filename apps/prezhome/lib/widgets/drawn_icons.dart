import 'product_icons.dart';

/// Iconos dibujados con IA (función `product-icon`, estilo Miau) para lo que
/// no tiene icono propio: se dibujan una vez por producto y los comparten
/// todos los hogares, así que la colección crece sola con el uso.
class DrawnIcons {
  DrawnIcons._();

  /// Pide la URL del icono de una palabra clave (lo dibuja si no existe).
  /// Lo fija `main.dart`; sin él (tests) no hay dibujos.
  static Future<String?> Function(String key, {bool again})? fetch;

  /// Una petición por producto y sesión; si falla (sin red, sin cupo) se
  /// queda el icono de categoría hasta la próxima vez que se abra la app.
  static final Map<String, Future<String?>> _urls = {};

  /// URL del dibujo de [name], o null si no se puede pedir. Con [retry]
  /// (la persona lo pide) se vuelve a intentar aunque antes fallara.
  static Future<String?>? urlFor(String name, {bool retry = false}) {
    final key = ProductIcons.photoKeyFor(name);
    final f = fetch;
    if (key == null || f == null) return null;
    if (retry) {
      return _urls[key] = f(key).then((url) {
        if (url == null) _urls.remove(key);
        return url;
      });
    }
    return _urls[key] ??= _orNull(f(key));
  }

  // Con async/try: catchError falla si el Future es de String (no String?).
  static Future<String?> _orNull(Future<String?> url) async {
    try {
      return await url;
    } catch (_) {
      return null;
    }
  }

  /// Dibuja otro icono para [name] (sustituye el compartido). Lanza si falla.
  static Future<String?> redraw(String name) async {
    final key = ProductIcons.photoKeyFor(name);
    final f = fetch;
    if (key == null || f == null) return null;
    final url = await f(key, again: true);
    _urls[key] = Future.value(url);
    return url;
  }

  /// Si [url] es un icono dibujado (se pinta como icono, no como foto).
  static bool isDrawn(String? url) =>
      url != null && url.contains('/recipe-images/icons/');
}
