# Skills de terceros

Skills copiadas al repo para que estén disponibles también en las sesiones de
Claude Code en la nube (allí no se cargan los plugins instalados en local).

| Skill (`.claude/skills/…`) | Origen | Commit | Licencia |
|---|---|---|---|
| dart-flutter-patterns, flutter-dart-code-review, accessibility, design-system, postgres-patterns | [affaan-m/ECC](https://github.com/affaan-m/ECC) | b92f181 | MIT (`ECC-LICENSE`) |
| taste-skill, redesign-skill | [Leonxlnx/taste-skill](https://github.com/Leonxlnx/taste-skill) | d237dd3 | MIT (`taste-skill-LICENSE`) |

Son guías de referencia: si chocan con las reglas del proyecto (`AGENTS.md`,
p. ej. la arquitectura actual sin BLoC/Riverpod ni Dio), mandan las del
proyecto. Las skills de taste están pensadas para web; de ellas se aplican los
principios de diseño (evitar lo genérico, jerarquía, espaciado), no las
librerías web.
