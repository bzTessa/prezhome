import 'package:flutter/material.dart';

import '../theme/app_motion.dart';
import '../theme/app_theme.dart';

/// Esqueletos de carga con la MISMA forma que la pantalla que va a salir:
/// mismas medidas, radios, márgenes y columnas. Las tarjetas son planas (sin
/// trazo ni sombra dura), para que no asomen bordes negros mientras carga.

/// Late suavemente lo que lleva dentro; con "reducir movimiento" queda quieto.
class Skeleton extends StatefulWidget {
  const Skeleton({super.key, required this.child});

  final Widget child;

  @override
  State<Skeleton> createState() => _SkeletonState();
}

class _SkeletonState extends State<Skeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (AppMotion.reduceMotionOf(context)) {
      _pulse.stop();
    } else if (!_pulse.isAnimating) {
      _pulse.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Cargando',
      child: ExcludeSemantics(
        child: FadeTransition(
          opacity: Tween(
            begin: 0.55,
            end: 1.0,
          ).animate(CurvedAnimation(parent: _pulse, curve: Curves.easeInOut)),
          child: widget.child,
        ),
      ),
    );
  }
}

/// Hueco de un texto, foto o icono.
class Bone extends StatelessWidget {
  const Bone({
    super.key,
    this.width,
    required this.height,
    this.radius = 6,
    this.color,
  });

  const Bone.circle(double size, {super.key, this.color})
    : width = size,
      height = size,
      radius = 999;

  final double? width;
  final double height;
  final double radius;
  final Color? color;

  @override
  Widget build(BuildContext context) => Container(
    width: width,
    height: height,
    decoration: BoxDecoration(
      color: color ?? AppColors.line,
      borderRadius: BorderRadius.circular(radius),
    ),
  );
}

/// Superficie plana de tarjeta, sin borde ni sombra.
class BoneCard extends StatelessWidget {
  const BoneCard({
    super.key,
    required this.child,
    this.radius = AppRadius.lg,
    this.padding = const EdgeInsets.all(AppSpacing.md),
    this.height,
  });

  final Widget child;
  final double radius;
  final EdgeInsetsGeometry padding;
  final double? height;

  @override
  Widget build(BuildContext context) => Container(
    height: height,
    padding: padding,
    clipBehavior: Clip.antiAlias,
    decoration: BoxDecoration(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(radius),
    ),
    child: child,
  );
}

/// Dos líneas de texto (título y detalle) alineadas a la izquierda.
Widget _lines(double title, double detail, {double gap = AppSpacing.sm}) =>
    Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Bone(width: title, height: 14),
        SizedBox(height: gap),
        Bone(width: detail, height: 10),
      ],
    );

/// Lista de esqueleto que no se desplaza: va a pantalla completa o dentro de
/// otra lista.
Widget _list(EdgeInsets padding, List<Widget> children) => Skeleton(
  child: ListView(
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    padding: padding,
    children: children,
  ),
);

/// Comidas > Plan (vista día): cabecera de semana, selector Día/Semana, tira
/// de 7 días, título del día y los huecos de comida (foto 64 + dos líneas).
class PlanSkeleton extends StatelessWidget {
  const PlanSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return _list(const EdgeInsets.fromLTRB(16, 8, 16, 96), [
      const SizedBox(
        height: 48,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Bone(width: 80, height: 10),
            SizedBox(height: 6),
            Bone(width: 150, height: 16),
          ],
        ),
      ),
      const SizedBox(height: 8),
      const Row(
        children: [
          Expanded(child: Bone(height: 46, radius: 999)),
          // Los dos botones de calendario y ajustes.
          SizedBox(width: 4 + 12),
          Bone.circle(24),
          SizedBox(width: 24),
          Bone.circle(24),
          SizedBox(width: 12),
        ],
      ),
      const SizedBox(height: 12),
      Row(
        children: [
          for (var i = 0; i < 7; i++)
            const Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 6),
                child: Column(
                  children: [
                    Bone(width: 26, height: 12),
                    SizedBox(height: 6),
                    Bone.circle(40),
                    SizedBox(height: 12),
                  ],
                ),
              ),
            ),
        ],
      ),
      const SizedBox(height: 16),
      const Align(
        alignment: Alignment.centerLeft,
        child: Bone(width: 110, height: 26, radius: 8),
      ),
      const SizedBox(height: 12),
      for (var i = 0; i < 4; i++)
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.md),
          child: BoneCard(
            child: Row(
              children: [
                const Bone(width: 64, height: 64, radius: 16),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: _lines(i.isEven ? 70 : 90, i.isEven ? 160 : 120),
                  ),
                ),
                const Bone.circle(24),
              ],
            ),
          ),
        ),
    ]);
  }
}

/// Rejilla de recetas, compartida con la pantalla real para que no se
/// desajusten.
const recipeGridDelegate = SliverGridDelegateWithMaxCrossAxisExtent(
  maxCrossAxisExtent: 240,
  crossAxisSpacing: 14,
  mainAxisSpacing: 14,
  childAspectRatio: 0.74,
);

/// Comidas > Recetas: buscador, filtros, aviso de despensa y la rejilla de
/// recetas (foto a sangre, chip arriba a la izquierda, corazón y título).
class RecipesSkeleton extends StatelessWidget {
  const RecipesSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Skeleton(
      child: CustomScrollView(
        physics: const NeverScrollableScrollPhysics(),
        slivers: [
          const SliverPadding(
            padding: EdgeInsets.fromLTRB(16, 12, 16, 4),
            sliver: SliverToBoxAdapter(
              child: BoneCard(height: 48, radius: 16, child: SizedBox()),
            ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 52,
              child: ListView(
                scrollDirection: Axis.horizontal,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                children: [
                  for (final w in const [72.0, 96.0, 84.0, 90.0, 80.0])
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Bone(width: w, height: 36, radius: 24),
                    ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
            sliver: SliverToBoxAdapter(
              child: BoneCard(
                radius: 24,
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Bone.circle(44),
                    const SizedBox(width: 12),
                    _lines(170, 120),
                  ],
                ),
              ),
            ),
          ),
          const SliverPadding(
            padding: EdgeInsets.fromLTRB(20, 4, 20, 8),
            sliver: SliverToBoxAdapter(
              child: Align(
                alignment: Alignment.centerLeft,
                child: Bone(width: 70, height: 12),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
            sliver: SliverGrid.builder(
              gridDelegate: recipeGridDelegate,
              itemCount: 6,
              itemBuilder: (_, i) => _RecipeCardBone(wide: i.isEven),
            ),
          ),
        ],
      ),
    );
  }
}

class _RecipeCardBone extends StatelessWidget {
  const _RecipeCardBone({required this.wide});

  final bool wide;

  @override
  Widget build(BuildContext context) {
    final on = AppColors.card;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.line,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Stack(
        children: [
          Positioned(
            left: 10,
            top: 10,
            child: Bone(width: 78, height: 24, radius: 999, color: on),
          ),
          Positioned(top: 6, right: 6, child: Bone.circle(32, color: on)),
          Positioned(
            left: 12,
            right: 12,
            bottom: 12,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Bone(height: 14, color: on),
                const SizedBox(height: 6),
                Bone(width: wide ? 90 : 60, height: 14, color: on),
                const SizedBox(height: 8),
                Bone(width: 84, height: 10, color: on),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Comidas > Diario: selector de día, tarjeta de calorías y comidas
/// agrupadas (icono 44 + nombre y kcal + papelera).
class DiarySkeleton extends StatelessWidget {
  const DiarySkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    Widget entry(int i) => Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: BoneCard(
        radius: 18,
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            const Bone(width: 44, height: 44, radius: 16),
            const SizedBox(width: 12),
            Expanded(
              child: Align(
                alignment: Alignment.centerLeft,
                child: _lines(i.isEven ? 150 : 110, 60, gap: 6),
              ),
            ),
            const Bone(width: 22, height: 22),
            const SizedBox(width: 13),
          ],
        ),
      ),
    );
    const header = Padding(
      padding: EdgeInsets.only(top: 4, bottom: 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Bone(width: 70, height: 10),
      ),
    );
    return _list(const EdgeInsets.fromLTRB(16, 16, 16, 96), [
      const BoneCard(
        height: 56,
        padding: EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Bone(width: 18, height: 18),
            Bone(width: 90, height: 14),
            Bone(width: 18, height: 18),
          ],
        ),
      ),
      const SizedBox(height: 12),
      const BoneCard(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Bone(width: 130, height: 14),
            SizedBox(height: 12),
            Bone(width: 150, height: 32, radius: 8),
            SizedBox(height: 10),
            Bone(width: 90, height: 12),
            SizedBox(height: 14),
            Bone(height: 10, radius: 8),
            SizedBox(height: 10),
            Bone(width: 140, height: 12),
          ],
        ),
      ),
      const SizedBox(height: 16),
      header,
      entry(0),
      const SizedBox(height: 8),
      header,
      entry(1),
      entry(2),
    ]);
  }
}

/// Compra: resumen de la lista, barra de añadir rápido y secciones por
/// pasillo con filas de producto (check, foto 42, nombre y cantidad).
class ShoppingSkeleton extends StatelessWidget {
  const ShoppingSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    Widget section(int rows, double title) => Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                const Bone.circle(28),
                const SizedBox(width: AppSpacing.sm),
                Bone(width: title, height: 14),
              ],
            ),
          ),
          for (var i = 0; i < rows; i++)
            Padding(
              padding: EdgeInsets.only(top: i == 0 ? 2 : 8),
              child: BoneCard(
                radius: 14,
                padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
                child: Row(
                  children: [
                    const Bone.circle(26),
                    const SizedBox(width: AppSpacing.md),
                    const Bone(width: 42, height: 42, radius: 10),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Bone(width: i.isEven ? 120 : 90, height: 14),
                      ),
                    ),
                    const Bone(width: 96, height: 40, radius: 999),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
    return _list(const EdgeInsets.fromLTRB(16, 16, 16, 32), [
      const BoneCard(
        padding: EdgeInsets.fromLTRB(12, 14, 12, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Bone(width: 160, height: 20),
            SizedBox(height: AppSpacing.sm),
            Bone(width: 120, height: 12),
            SizedBox(height: AppSpacing.md),
            Bone(height: 12, radius: 999),
          ],
        ),
      ),
      const SizedBox(height: AppSpacing.md),
      const BoneCard(height: 48, radius: AppRadius.md, child: SizedBox()),
      const SizedBox(height: AppSpacing.lg),
      section(3, 110),
      section(2, 80),
    ]);
  }
}

/// Despensa: título "Mi cocina", rejilla de zonas de tres en fila, botón de
/// ideas y la lista de la zona (foto 52 + nombre y cantidad) en un bloque.
class PantrySkeleton extends StatelessWidget {
  const PantrySkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return _list(
      const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        112,
      ),
      [
        const Row(
          children: [
            Bone(width: 130, height: 26, radius: 8),
            SizedBox(width: AppSpacing.sm),
            Bone(width: 80, height: 12),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        // Misma cuenta que KitchenZonesGrid: tres por fila.
        LayoutBuilder(
          builder: (context, c) {
            const gap = AppSpacing.sm;
            final w = (c.maxWidth - gap * 2) / 3;
            return Wrap(
              spacing: gap,
              runSpacing: gap,
              children: [
                for (var i = 0; i < 6; i++)
                  SizedBox(
                    width: w,
                    child: const BoneCard(
                      radius: AppRadius.md,
                      padding: EdgeInsets.fromLTRB(10, 8, 10, 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Bone(width: 30, height: 30, radius: 8),
                              Spacer(),
                              Bone(width: 16, height: 16),
                            ],
                          ),
                          SizedBox(height: 8),
                          Bone(width: 60, height: 12),
                          SizedBox(height: 5),
                          Bone(width: 44, height: 10),
                        ],
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
        const SizedBox(height: AppSpacing.md),
        const Bone(height: 44, radius: 999),
        const SizedBox(height: AppSpacing.lg),
        const Padding(
          padding: EdgeInsets.only(left: 4, bottom: AppSpacing.sm),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Bone(width: 90, height: 12),
          ),
        ),
        BoneCard(
          radius: AppRadius.md,
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              for (var i = 0; i < 5; i++) ...[
                if (i > 0)
                  Divider(height: 1, indent: 76, color: AppColors.line),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                  child: Row(
                    children: [
                      const Bone(width: 52, height: 52, radius: 14),
                      const SizedBox(width: 12),
                      _lines(i.isEven ? 130 : 100, 70),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// Inicio: la comida de hoy (foto 190 + título), las tres fichas de un
/// vistazo y la racha. Va dentro de la lista de Inicio, sin relleno propio.
class HomeSkeleton extends StatelessWidget {
  const HomeSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return _list(EdgeInsets.zero, [
      BoneCard(
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Bone(height: 190, radius: 0),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: _lines(180, 120),
            ),
          ],
        ),
      ),
      const SizedBox(height: AppSpacing.lg),
      Row(
        children: [
          for (var i = 0; i < 3; i++) ...[
            if (i > 0) const SizedBox(width: AppSpacing.sm),
            const Expanded(
              child: BoneCard(
                radius: AppRadius.md,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Bone(width: 22, height: 22),
                    SizedBox(height: AppSpacing.sm),
                    Bone(width: 30, height: 28, radius: 8),
                    SizedBox(height: 4),
                    Bone(width: 60, height: 10),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
      const SizedBox(height: AppSpacing.lg),
      BoneCard(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Bone.circle(48),
            const SizedBox(width: 12),
            _lines(140, 180),
          ],
        ),
      ),
    ]);
  }
}
