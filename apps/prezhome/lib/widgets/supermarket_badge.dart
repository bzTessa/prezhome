import 'package:flutter/material.dart';

import '../models/supermarket.dart';

/// Insignia de un supermercado: su logo, o sus iniciales sobre su color de
/// marca si no tiene logo.
class SupermarketBadge extends StatelessWidget {
  const SupermarketBadge({
    super.key,
    required this.supermarket,
    this.size = 44,
  });

  final Supermarket supermarket;
  final double size;

  /// "Mercadona" → "M", "El Corte Inglés / Hipercor" → "EC".
  static String initials(String label) {
    final words = label
        .split(RegExp(r'[\s/]+'))
        .where((w) => w.isNotEmpty && w[0] == w[0].toUpperCase())
        .toList();
    if (words.length >= 2) return '${words[0][0]}${words[1][0]}';
    return label.isEmpty ? '?' : label[0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final logo = supermarket.logo;
    if (logo != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(size * 0.24),
        child: Image.asset(logo, width: size, height: size, fit: BoxFit.cover),
      );
    }
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Color(supermarket.brandColor),
        shape: BoxShape.circle,
      ),
      child: Text(
        initials(supermarket.label),
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
          fontSize: size * 0.38,
        ),
      ),
    );
  }
}
