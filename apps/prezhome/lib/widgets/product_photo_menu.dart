import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/food_photo_service.dart';
import '../services/product_photo_resolver.dart';
import '../theme/app_theme.dart';
import '../utils/friendly_error.dart';
import '../utils/shopping_display.dart';
import 'drawn_icons.dart';
import 'product_icons.dart';
import 'product_search_sheet.dart';

/// Opciones para cambiar la foto de un producto (compra y despensa). Cada una
/// cierra la hoja devolviendo su acción, que se pasa a [pickProductPhoto].
List<Widget> productPhotoTiles(
  BuildContext ctx, {
  required String name,
  String? imageUrl,
}) {
  Widget tile(IconData icon, String title, String action) => ListTile(
    leading: Icon(icon, color: AppColors.woodDark),
    title: Text(title),
    onTap: () => Navigator.of(ctx).pop(action),
  );
  return [
    tile(Icons.photo_camera_outlined, 'Hacer una foto', 'camera'),
    tile(Icons.photo_library_outlined, 'Elegir de la galería', 'gallery'),
    tile(Icons.storefront_rounded, 'Elegir producto del súper', 'store'),
    if (ProductIcons.photoKeyFor(name) != null)
      tile(Icons.image_outlined, 'Generar foto', 'generate'),
    if (ProductIcons.assetFor(name) == null &&
        ProductIcons.photoKeyFor(name) != null)
      tile(
        Icons.brush_outlined,
        DrawnIcons.isDrawn(imageUrl) ? 'Otro dibujo' : 'Usar un dibujo',
        'drawing',
      ),
  ];
}

/// Acciones que devuelven las opciones de [productPhotoTiles].
const productPhotoActions = {
  'camera',
  'gallery',
  'store',
  'generate',
  'drawing',
};

/// Hace la acción de foto [action] y devuelve la URL nueva (ya recordada para
/// el hogar), o null si se cancela o falla (el fallo se avisa aquí).
Future<String?> pickProductPhoto(
  BuildContext context,
  String action, {
  required String homeId,
  required String name,
  String? imageUrl,
  String? supermarketKey,
}) async {
  final client = Supabase.instance.client;
  final messenger = ScaffoldMessenger.of(context);
  void wait(String text) => messenger.showSnackBar(
    SnackBar(content: Text(text), duration: const Duration(seconds: 30)),
  );
  try {
    final String? url;
    switch (action) {
      case 'camera' || 'gallery':
        final file = await ImagePicker().pickImage(
          source: action == 'camera' ? ImageSource.camera : ImageSource.gallery,
          maxWidth: 1000,
          imageQuality: 82,
        );
        if (file == null) return null;
        final bytes = await file.readAsBytes();
        final ext = file.name.toLowerCase().endsWith('.png') ? 'png' : 'jpg';
        final path =
            '$homeId/shop_${DateTime.now().millisecondsSinceEpoch}.$ext';
        // El bucket recipe-images se reutiliza (ya tiene políticas públicas).
        await client.storage
            .from('recipe-images')
            .uploadBinary(
              path,
              bytes,
              fileOptions: FileOptions(
                contentType: ext == 'png' ? 'image/png' : 'image/jpeg',
                upsert: false,
              ),
            );
        url = client.storage.from('recipe-images').getPublicUrl(path);
      case 'store':
        final product = await showProductSearchSheet(
          context,
          initialQuery: shoppingCleanName(name),
          supermarketKey: supermarketKey,
        );
        url = product?.imageUrl;
        if (url == null) return null;
      case 'generate':
        wait('Creando la foto…');
        url = await ProductPhotoResolver(
          client,
        ).genericPhoto(name, again: true);
        messenger.hideCurrentSnackBar();
        if (url == null) throw Exception('Sin foto');
      case 'drawing':
        wait('Dibujando…');
        url = DrawnIcons.isDrawn(imageUrl)
            ? await DrawnIcons.redraw(name)
            : await DrawnIcons.urlFor(name, retry: true);
        messenger.hideCurrentSnackBar();
        if (url == null) throw Exception('Sin dibujo');
      default:
        return null;
    }
    // Se recuerda para ese alimento: la próxima vez (en compra y despensa)
    // sale la misma.
    await FoodPhotoService(
      client,
    ).rememberPhoto(homeId: homeId, name: name, url: url);
    return url;
  } catch (e) {
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(friendlyError(e, 'No se pudo cambiar la foto')),
        backgroundColor: AppColors.expired,
      ),
    );
    return null;
  }
}
