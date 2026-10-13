import 'package:flutter/material.dart';

import '../inventory_screen.dart';
import '../theme/app_theme.dart';

/// Pestaña "Despensa": lo que hay en casa (nevera, congelador, despensa…).
/// La lista de la compra tiene ahora su propia pestaña.
class DespensaTab extends StatelessWidget {
  const DespensaTab({super.key});

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.cream,
      child: SafeArea(bottom: false, child: InventoryScreen(embedded: true)),
    );
  }
}
