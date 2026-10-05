# Implementation Plan — Fix quick-access row overflow (Inicio tab)

Single-file, single-concern layout/overflow fix in `lib/tabs/home_tab.dart`.
No changes to navigation (`_runQuickAction`), the `QuickAction` model, or
dashboard personalization logic.

## Root cause (confirmed by reading the code)

`_quickAccessRow()` (around line 681) wraps a horizontal
`ListView.separated` in a fixed `SizedBox(height: 92)`. In a horizontal
`ListView`, each item is laid out with a **bounded main-cross-axis height
of 92 px** and effectively unbounded width (each `_quickAccessButton`
pins its own `width: 84`). Inside each button, the `Column` natural height is:

- vertical padding: `AppSpacing.md` top + `AppSpacing.md` bottom = 12 + 12 = **24**
- icon box: **42**
- gap: `AppSpacing.xs` = **4**
- label: `Text(maxLines: 2)` at `fontSize: 10.5, height: 1.1` → ~11.55 px/line × 2 ≈ **23.1**

Total ≈ 24 + 42 + 4 + 23.1 ≈ **93.1 px**, which exceeds the 92 px box by
~1–2 px → the `RenderFlex` "BOTTOM OVERFLOWED BY 2 PIXELS" stripe, and the
2-line labels get clipped so long labels ("Añadir a la despensa", "Lista de
la compra") show truncated. The fixed 92 px simply does not fit the content.

Design decision: this is primarily a **vertical** overflow caused by an
under-sized fixed height. The minimal, robust fix is to raise the row height so
the full 2-line label fits with the existing paddings/spacing, and to make the
label itself overflow-safe (`overflow: TextOverflow.ellipsis`). I keep the
horizontal `ListView` (it already handles a variable number of `_prefs.quick`
entries by scrolling, satisfying "handle gracefully" without touching
navigation). I do **not** switch to `Expanded` children because the number of
entries is variable (3 by default, up to 6) and `Expanded` inside a horizontal
scroll view is invalid; the existing scroll approach is the correct, lower-risk
choice and preserves behavior for any count.

Rationale for the chosen height (112): 24 (padding) + 42 (icon) + 4 (gap) +
2-line label with a small safety margin. Using `AppSpacing` tokens:
`92` is replaced with a value that comfortably clears ~93 px of content at
typical phone widths (360–420 dp). `112` leaves ~19 px of headroom for the
2-line label (≈23 px needs the box to be ≥ ~93 px; 112 is safe without looking
loose). This keeps the button compact and visually consistent.

## Design-system tokens to reuse (already imported/used in the file)

- `AppSpacing.md` / `AppSpacing.sm` / `AppSpacing.xs` — paddings and gaps (unchanged).
- `AppTheme.surfaceDecoration(radius: AppRadius.md)` — button surface (unchanged).
- `AppRadius.smRadius` — icon box radius (unchanged).
- `AppTextStyles.label` with the existing `copyWith(fontSize: 10.5, height: 1.1)`
  — label style (unchanged except adding `overflow: TextOverflow.ellipsis`).
- `AppColors.*` via `_quickAccent(action)` — icon colors (unchanged).

Do NOT introduce new hardcoded colors, font sizes, or ad-hoc paddings.

## Plan

- [ ] 1. Raise the quick-access row height and keep the horizontal scroll.
      In `_quickAccessRow()` (around line 681) change the wrapping
      `SizedBox(height: 92)` to `SizedBox(height: 112)` so the icon box +
      spacing + 2-line label fit without overflow at phone widths (~360–420 dp),
      for any number of `_prefs.quick` entries. Leave the `ListView.separated`,
      its `scrollDirection: Axis.horizontal`, `itemCount`, separator
      (`SizedBox(width: AppSpacing.md)`), and `StaggeredEntrance` wrapping
      untouched (navigation and personalization unchanged).
      Files: lib/tabs/home_tab.dart
      Verify: part of the build/analyze/test run in step 3.

- [ ] 2. Make the button label overflow-safe without changing its look.
      In `_quickAccessButton(QuickAction action)` (around line 716), on the
      `Text(action.label, ...)` keep `maxLines: 2`, keep
      `textAlign: TextAlign.center`, keep the existing
      `style: AppTextStyles.label.copyWith(fontSize: 10.5, height: 1.1)`, and
      add `overflow: TextOverflow.ellipsis` so that if a label still can't fit
      two lines at a very narrow width it ellipsizes cleanly instead of
      painting a red stripe. Do not change the icon box (42×42), the
      `SizedBox(height: AppSpacing.xs)` gap, the `Container(width: 84, ...)`,
      or the `PressScale`/`_runQuickAction` wiring.
      Files: lib/tabs/home_tab.dart
      Verify: part of the build/analyze/test run in step 3.

- [ ] 3. Verify exactly like CI (Flutter 3.47.6 / Dart 3.13.5), from inside
      `/projects/sandbox/prezhome`. If Flutter is not installed in the sandbox,
      first install it (slow, ~5–10 min, expected):
      `git clone --depth 1 --branch 3.47.6 https://github.com/flutter/flutter.git ~/flutter_sdk`
      then `export PATH="$HOME/flutter_sdk/bin:$PATH"` and
      `export FLUTTER_SUPPRESS_ANALYTICS=true`, then `flutter pub get`.
      Then run the three CI gates and confirm each passes:
      - `dart format --output=none --set-exit-if-changed lib/` → exits 0 (no
        reformatting; the repo uses Dart tall style — use Dart 3.13.5, not an
        older Dart, or this will fail).
      - `flutter analyze` → prints "No issues found!".
      - `flutter test` → all existing tests pass; count stays at the baseline
        (~338). This is a layout-only change: no test files are added or
        modified, and no existing test asserts on the quick-access row height,
        so the count must not drop.
      Files: none (verification only)
      Verify: all three commands succeed as described above.

- [ ] 4. Keep the working tree to the single intended change before committing.
      `flutter pub get` rewrites autogenerated files; discard them so only the
      `home_tab.dart` edit remains:
      `git checkout -- pubspec.lock analysis_options.yaml` and any touched
      plugin registrants under `linux/`, `macos/`, `windows/` (restore with
      `git checkout --`). Confirm with `git status` that the only staged/modified
      source file is `lib/tabs/home_tab.dart`.
      Files: none (working-tree hygiene)
      Verify: `git status` shows `lib/tabs/home_tab.dart` as the only
      non-autogenerated change.

## Notes / assumptions

- There is no existing widget test for `home_tab.dart`; tests under `test/` are
  pure logic/model/widget tests (e.g. `dashboard_prefs_test.dart`,
  `main_shell_tabs_test.dart`). The task says no test changes are expected for
  a layout-only fix, so none are added; the bug is verified visually/by the
  overflow stripe disappearing, and regressions are guarded by the full
  `flutter test` suite staying green.
- `112` is chosen as the smallest safe height that clears the ~93 px of content
  with headroom for the 2-line label at phone widths, keeping the button
  compact and consistent with the Cozy design system. If a reviewer prefers an
  even tighter value, anything ≥ ~96 px removes the 2 px overflow; 112 is the
  conservative, visually balanced choice.
- `_prefs.quick` can hold a variable number of entries (default 3, up to 6).
  The horizontal `ListView` already scrolls when they don't all fit, so no
  entry is lost and navigation is unaffected regardless of count.
