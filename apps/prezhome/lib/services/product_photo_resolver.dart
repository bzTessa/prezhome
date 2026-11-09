import 'package:supabase_flutter/supabase_flutter.dart';

import '../widgets/drawn_icons.dart';
import '../widgets/product_icons.dart';
import 'food_photo_service.dart';
import 'home_country.dart';
import 'product_search_service.dart';

/// Elige la URL de foto a usar en el alta por nombre, respetando la prioridad:
/// catálogo/OFF ([catalog]) manda, luego el banco de fotos recipe-photo
/// ([fallback]) y, en último término, la foto previa del item ([previous]).
/// Las cadenas vacías se tratan como null para no pintar un hueco. Devuelve
/// null solo si no hay ninguna foto por ninguna vía. Función PURA, sin efectos.
String? pickImageUrl({String? catalog, String? fallback, String? previous}) {
  String? clean(String? url) => (url == null || url.isEmpty) ? null : url;
  return clean(catalog) ?? clean(fallback) ?? clean(previous);
}

/// Fotos que no se han podido cargar en este móvil (la web del súper falla o
/// la bloquea): se buscan otras en su lugar. Lo rellena [FoodImage].
final Set<String> brokenPhotos = {};

/// Si [url] no se puede enseñar: falló en este móvil o es de Consum, cuyo
/// servidor de imágenes no las sirve a la app (en el buscador salen vacías).
bool isBrokenPhoto(String? url) =>
    url != null && (brokenPhotos.contains(url) || url.contains('cdn-consum.'));

/// Foto de banco de imágenes (Unsplash, Pexels): en la compra salen
/// demasiado al azar, así que no se usan para productos.
bool isStockPhoto(String? url) {
  if (url == null || url.isEmpty) return false;
  final host = Uri.tryParse(url)?.host ?? '';
  return host.contains('unsplash.com') || host.contains('pexels.com');
}

/// Solo las fotos de Open Food Facts se comparten entre hogares (misma regla
/// que el check de `product_photo_shared`); nunca una foto de la persona.
bool isSharablePhoto(String url) =>
    RegExp(r'^https://images\.openfoodfacts\.(org|net)/').hasMatch(url);

/// Clave en `product_photo_shared` de las fotos elegidas con la regla nueva;
/// las filas antiguas (sin prefijo) se ignoran.
String sharedPhotoKey(String key) => 'v2|$key';

/// Decide qué foto guardar al revisar una ya puesta: [current] es la actual y
/// [resolved] la que acaba de devolver la búsqueda. Devuelve la URL a escribir
/// o null si NO hay que tocar nada. Lógica PURA.
///
/// Regla clave (bug de la foto que desaparece): NUNCA se borra una foto buena
/// escribiendo null. Si la búsqueda no encuentra nada ([resolved] == null) se
/// deja la que había, aunque se sospeche que no es exactamente ese producto:
/// una foto real aunque sea aproximada es mejor que un hueco en blanco, y la
/// persona siempre puede cambiarla a mano. Solo se actualiza cuando hay una
/// foto nueva distinta de la actual.
String? photoUpdateOrNull(String? current, String? resolved) {
  if (resolved == null || resolved.isEmpty) return null;
  if (resolved == (current ?? '')) return null;
  return resolved;
}

/// Foto de producto para la compra: la del envase en Open Food Facts (del
/// súper principal si lo hay), solo si el producto es claramente lo buscado.
/// Las fotos ya guardadas se comprueban antes de reutilizarlas. Lo encontrado se guarda por hogar y se
/// reutiliza. Si no hay producto, null: se ve la ilustración del alimento.
class ProductPhotoResolver {
  ProductPhotoResolver(
    this._client, {
    ProductSearchService? search,
    FoodPhotoService? photos,
    Duration throttleWait = const Duration(seconds: 8),
  }) : _search = search ?? ProductSearchService(),
       _photos = photos ?? FoodPhotoService(_client),
       _throttleWait = throttleWait;

  final SupabaseClient _client;
  final ProductSearchService _search;
  final FoodPhotoService _photos;
  final Duration _throttleWait;

  /// Decide la foto del alta POR NOMBRE combinando las tres vías con su
  /// prioridad real (la misma que ejercía el `else if` de la pantalla): el
  /// catálogo/OFF de [resolveWithPrice] manda; si no da foto se cae al banco de
  /// fotos recipe-photo ([FoodPhotoService.resolvePhotoUrl], modo 'ingredient')
  /// y, en último recurso, se conserva la foto [previous] del item. Devuelve la
  /// URL elegida (o null) y el precio real de catálogo para recordarlo.
  ///
  /// El respaldo al banco SOLO se consulta cuando el catálogo/OFF no trae foto,
  /// así un producto con foto oficial nunca dispara la segunda búsqueda ni se
  /// la pisa el banco. Este método concentra el CABLEADO (antes inline en la
  /// pantalla) para poder probarlo sin montar Supabase: un test puede verificar
  /// que, sin foto de catálogo, acaba ganando la del banco.
  Future<({String? imageUrl, double? price})> resolveAddByNamePhoto({
    required String homeId,
    required String name,
    String? supermarketKey,
    String? previous,
  }) async {
    // La despensa resuelve con el `background` por defecto (true) de
    // [resolveWithPrice]: se deja como el comportamiento de fondo de siempre
    // para no alterar lo que ya funcionaba (PR #260). El catálogo de Mercadona
    // resuelve sin tocar el límite de OFF, así que la foto+precio igualmente
    // llegan; solo si cae a OFF respeta la cuota de fondo.
    final resolved = await resolveWithPrice(
      homeId: homeId,
      name: name,
      supermarketKey: supermarketKey,
    );
    // Si el catálogo/OFF no da foto, caemos al banco de fotos recipe-photo
    // (como antes del PR #259) antes de conservar la previa.
    final fallback = resolved.url == null
        ? await _photos.resolvePhotoUrl(
            homeId: homeId,
            name: name,
            mode: 'ingredient',
          )
        : null;
    return (
      imageUrl: pickImageUrl(
        catalog: resolved.url,
        fallback: fallback,
        previous: previous,
      ),
      price: resolved.price,
    );
  }

  static final Map<String, bool> _checked = {};

  /// Si la foto guardada [url] es de verdad de [name]: las de la galería
  /// siempre; las de OFF se comprueban leyendo el producto por su código de
  /// barras (no gasta búsquedas). Null si no se pudo comprobar (sin red).
  Future<bool?> photoMatches(String name, String url) async {
    // Los dibujos ya no se usan: se cambian por la foto del súper.
    if (DrawnIcons.isDrawn(url)) return false;
    // Lo genérico lleva la foto de frescos del súper: una de OFF sobra.
    if (ProductIcons.isGeneric(name) && isSharablePhoto(url)) return false;
    final code = offBarcodeFromUrl(url);
    if (code == null) return !isSharablePhoto(url) && !isStockPhoto(url);
    final memo = '$name|$code';
    final known = _checked[memo];
    if (known != null) return known;
    final product = await _search.productByCode(code);
    if (product == null) return null;
    return _checked[memo] = isProductFor(name, product);
  }

  /// Busca la foto de [name]. Si Open Food Facts pide esperar, espera y
  /// reintenta (pensado para ir en segundo plano). Nunca lanza. Es una búsqueda
  /// de FONDO (lo usan `fillMissingPhotos` de la lista y el recheck de la
  /// despensa): delega en [resolveWithPrice] con su `background` por defecto
  /// (true) para reservar la cuota de 4/min y no agotar los 8/min del buscador
  /// manual de la persona.
  Future<String?> photoFor({
    required String homeId,
    required String name,
    String? supermarketKey,
  }) async => (await resolveWithPrice(
    homeId: homeId,
    name: name,
    supermarketKey: supermarketKey,
  )).url;

  /// Igual que [photoFor] pero devuelve también el precio real del catálogo
  /// del producto más probable (el mismo que enseña el buscador manual como
  /// "… € aprox."). El precio solo sale de un producto de catálogo
  /// (store != null); para lo genérico y para Open Food Facts es null. Así el
  /// alta por nombre puede poner la foto oficial Y recordar el precio real.
  ///
  /// [background] reparte el límite de Open Food Facts: `true` (por defecto) es
  /// una búsqueda de FONDO, limitada a 4/min, que reserva su cuota para no
  /// agotar los 8/min que necesita el buscador manual de la persona. Lo usan
  /// las rutas que rellenan fotos sin que nadie lo pida ahora mismo
  /// (`fillMissingPhotos` de la lista, recheck de la despensa). Las ACCIONES
  /// DIRECTAS de la persona (añadir por nombre, "Te toca") pasan `false` para
  /// no caer en ese límite de fondo y que la foto+precio lleguen antes del
  /// timeout de 4 s. El límite general de OFF (8/min) se mantiene en ambos
  /// casos; el flag solo cambia el reparto cuando la búsqueda llega a OFF (los
  /// hits de catálogo, como leche/cerveza en Mercadona, no lo tocan).
  Future<({String? url, double? price})> resolveWithPrice({
    required String homeId,
    required String name,
    String? supermarketKey,
    bool background = true,
  }) async {
    final key = FoodPhotoService.cacheKey(name);
    if (key.isEmpty) return (url: null, price: null);
    try {
      final cached = await _client
          .from('food_photo_cache')
          .select('url,manual')
          .eq('home_id', homeId)
          .eq('name_normalized', key)
          .maybeSingle();
      final url = cached?['url']?.toString() ?? '';
      // La elegida a mano manda siempre, hasta que la persona la cambie.
      if (cached?['manual'] == true &&
          url.isNotEmpty &&
          !DrawnIcons.isDrawn(url)) {
        return (url: url, price: null);
      }
      if (url.isNotEmpty &&
          !isStockPhoto(url) &&
          !isBrokenPhoto(url) &&
          await photoMatches(name, url) != false) {
        return (url: url, price: null);
      }
    } catch (_) {}
    // Lo genérico (cebolla, leche...) lleva la foto de la sección de frescos
    // del súper; si no la hay, se busca en el catálogo como lo demás.
    final generic = ProductIcons.isGeneric(name);
    if (generic) {
      final store = catalogStores.contains(supermarketKey)
          ? supermarketKey!
          : catalogForCountry[HomeCountry.current.value.code];
      final url = store == null ? null : await _search.freshPhoto(name, store);
      if (url != null && !isBrokenPhoto(url)) {
        await FoodPhotoService(
          _client,
        ).rememberPhoto(homeId: homeId, name: name, url: url);
        // Lo genérico no lleva precio de producto concreto.
        return (url: url, price: null);
      }
    }

    // Otro hogar ya encontró este producto: se reutiliza sin buscar.
    try {
      final shared = await _client
          .from('product_photo_shared')
          .select('url')
          .eq('name_normalized', sharedPhotoKey(key))
          .maybeSingle();
      final url = shared?['url']?.toString();
      if (url != null &&
          url.isNotEmpty &&
          !isBrokenPhoto(url) &&
          await photoMatches(name, url) == true) {
        await FoodPhotoService(
          _client,
        ).rememberPhoto(homeId: homeId, name: name, url: url);
        // Foto compartida de OFF: sin precio de catálogo.
        return (url: url, price: null);
      }
    } catch (_) {}

    // El reparto del límite de OFF depende de [background] (ver doc): las
    // rutas de FONDO (fillMissingPhotos, recheck de la despensa) buscan con
    // background: true para reservar su cuota de 4/min; las ACCIONES DIRECTAS
    // de la persona (añadir por nombre, "Te toca") pasan false para no caer en
    // ese límite y que la foto+precio del catálogo lleguen antes del timeout de
    // 4 s de _addItem. El límite general de OFF (8/min) se mantiene.
    Future<ProductSearchResult> searchIn(String? store) async {
      ProductSearchResult result;
      var tries = 0;
      do {
        result = await _search.search(
          name,
          supermarketKey: store,
          background: background,
        );
        if (!result.throttled) break;
        await Future<void>.delayed(_throttleWait);
      } while (++tries < 10);
      return result;
    }

    final result = await searchIn(supermarketKey);
    final usable = [
      for (final p in result.products)
        if (!isBrokenPhoto(p.imageUrl)) p,
    ];
    // El súper del hogar manda: "Cerveza" de otra cadena casaba mejor por
    // nombre que "Cerveza Amstel" de Mercadona y salía la foto de otra tienda.
    final own = catalogKeyFor(supermarketKey);
    final ownProducts = [
      for (final p in usable)
        if (own != null && p.store == own) p,
    ];
    var found =
        confidentProductPhoto(name, ownProducts) ??
        confidentProductPhoto(name, usable);
    // Un envase de OFF no sirve para lo genérico (pondría una foto equivocada);
    // pero la foto del envase del catálogo del súper (image_url de
    // supermarket_products, no openfoodfacts) SÍ vale para un genérico como
    // leche/cerveza, igual que la enseña el buscador manual. isSharablePhoto
    // solo descarta las de OFF, así que la del catálogo sobrevive.
    if (generic && found != null && isSharablePhoto(found)) found = null;
    // Precio real del producto de catálogo más probable (store != null), el
    // mismo que enseña el buscador manual. También para lo genérico
    // (leche/cerveza): antes el guard `if (!generic)` dejaba price=null y el
    // "≈" caía al precio inventado por categoría. OFF no trae precio.
    final best =
        bestCatalogMatch(name, ownProducts) ??
        bestCatalogMatch(name, result.products);
    final double? price = (best != null && best.store != null)
        ? best.price
        : null;
    if (found != null) {
      await FoodPhotoService(
        _client,
      ).rememberPhoto(homeId: homeId, name: name, url: found);
      if (isSharablePhoto(found)) {
        try {
          await _client.from('product_photo_shared').upsert({
            'name_normalized': sharedPhotoKey(key),
            'url': found,
          }, ignoreDuplicates: true);
        } catch (_) {}
      }
    }
    return (url: found, price: price);
  }
}
