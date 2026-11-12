import 'package:flutter/material.dart';
import '../l10n/l10n.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/food_photo_service.dart';
import '../services/price_memory.dart';
import '../theme/app_theme.dart';
import '../utils/friendly_error.dart';
import '../utils/shopping_display.dart';
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
    tile(Icons.storefront_rounded, ctx.l.phStore, 'store'),
    tile(Icons.photo_camera_outlined, ctx.l.phCamera, 'camera'),
    tile(Icons.photo_library_outlined, ctx.l.phGallery, 'gallery'),
  ];
}

/// Acciones que devuelven las opciones de [productPhotoTiles].
const productPhotoActions = {'camera', 'gallery', 'store'};

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
  final errorText = context.l.phError;
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
        // El precio del producto elegido pasa a ser el "≈" de ese alimento.
        if (product?.price case final price?) {
          await PriceMemory(client).rememberCatalogPrice(homeId, name, price);
        }
      default:
        return null;
    }
    // Elegida a mano: sale siempre para ese alimento (compra y despensa)
    // hasta que se cambie otra vez.
    await FoodPhotoService(
      client,
    ).rememberPhoto(homeId: homeId, name: name, url: url, manual: true);
    return url;
  } catch (e) {
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(friendlyError(e, errorText)),
        backgroundColor: AppColors.expired,
      ),
    );
    return null;
  }
}
