import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'add_inventory_item_screen.dart';
import 'models/inventory_item.dart';
import 'services/food_facts_service.dart';
import 'services/inventory_prefill.dart';
import 'theme/app_theme.dart';

/// Pantalla de ESCANEO de código de barras para añadir un producto a la
/// despensa sin ticket: abre la cámara, detecta un EAN/UPC, lo busca en Open
/// Food Facts (vía la edge function food-facts) y abre el formulario de alta
/// precargado con lo que OFF devuelva. Si OFF no lo encuentra, abre el
/// formulario vacío con un aviso amable. El escaneo se detiene tras la primera
/// lectura; nunca es un error bloqueante.
class ScanBarcodeScreen extends StatefulWidget {
  const ScanBarcodeScreen({super.key});

  @override
  State<ScanBarcodeScreen> createState() => _ScanBarcodeScreenState();
}

class _ScanBarcodeScreenState extends State<ScanBarcodeScreen> {
  final MobileScannerController _controller = MobileScannerController(
    // Restringimos a los formatos de producto habituales para no reaccionar a
    // QR u otros códigos irrelevantes.
    formats: const [
      BarcodeFormat.ean13,
      BarcodeFormat.ean8,
      BarcodeFormat.upcA,
      BarcodeFormat.upcE,
    ],
  );

  // Guarda para que la detección actúe UNA sola vez (el stream puede emitir
  // varias lecturas del mismo código muy seguidas).
  bool _handled = false;

  // Mostramos un indicador mientras consultamos OFF tras la primera lectura.
  bool _loading = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_handled) return;
    String? code;
    for (final b in capture.barcodes) {
      final raw = b.rawValue;
      if (raw != null && raw.trim().isNotEmpty) {
        code = raw.trim();
        break;
      }
    }
    if (code == null) return;

    _handled = true;
    await _controller.stop();
    if (!mounted) return;
    setState(() => _loading = true);

    final facts = await FoodFactsService(
      Supabase.instance.client,
    ).lookupByBarcode(code);
    if (!mounted) return;

    final prefill = inventoryPrefillFromFoodFacts(facts);
    if (prefill != null) {
      // OFF encontró el producto: abrimos el formulario precargado. El item
      // construido burbujea hasta InventoryScreen vía pushReplacement (que
      // propaga el resultado de la pantalla de alta al push<InventoryItem> de
      // InventoryScreen).
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<InventoryItem>(
          builder: (_) => AddInventoryItemScreen(prefill: prefill),
        ),
      );
    } else {
      // No encontrado: alta manual con un aviso amable (nunca un error duro).
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const AddInventoryItemScreen()),
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No encontré ese código en Open Food Facts, puedes añadirlo a mano.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(title: const Text('Escanear código')),
      body: Stack(
        fit: StackFit.expand,
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
            errorBuilder: (context, error, child) =>
                _ScannerError(error: error),
          ),
          if (_loading)
            Container(
              color: AppColors.ink.withValues(alpha: 0.45),
              alignment: Alignment.center,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  CircularProgressIndicator(color: AppColors.cream),
                  SizedBox(height: AppSpacing.md),
                  Text(
                    'Buscando el producto…',
                    style: TextStyle(color: AppColors.cream),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Mensaje legible cuando la cámara no está disponible o el permiso ha sido
/// denegado: nada de crashes ni diálogos duros, solo una explicación en español
/// y un botón para volver atrás.
class _ScannerError extends StatelessWidget {
  const _ScannerError({required this.error});

  final MobileScannerException error;

  @override
  Widget build(BuildContext context) {
    final denied = error.errorCode == MobileScannerErrorCode.permissionDenied;
    final message = denied
        ? 'Necesito permiso para usar la cámara y poder escanear el código. '
              'Puedes concederlo en los ajustes del teléfono.'
        : 'No pude abrir la cámara para escanear. Puedes añadir el producto a '
              'mano desde el inventario.';
    return Container(
      color: AppColors.cream,
      padding: const EdgeInsets.all(AppSpacing.lg),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.no_photography_outlined,
            size: 56,
            color: AppColors.inkMuted,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.ink, fontSize: 15),
          ),
          const SizedBox(height: AppSpacing.lg),
          ElevatedButton(
            onPressed: () => Navigator.of(context).maybePop(),
            child: const Text('Volver'),
          ),
        ],
      ),
    );
  }
}
