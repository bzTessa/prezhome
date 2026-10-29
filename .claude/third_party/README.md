# Skills de terceros

Skills copiadas al repo para que estén disponibles también en las sesiones de
Claude Code en la nube (allí no se cargan los plugins instalados en local).

| Skill (`.claude/skills/…`) | Origen | Commit | Licencia |
|---|---|---|---|
| dart-flutter-patterns, flutter-dart-code-review, accessibility, design-system, postgres-patterns, database-migrations, brand-voice | [affaan-m/ECC](https://github.com/affaan-m/ECC) | b92f181 | MIT (`ECC-LICENSE`) |
| security-audit | [cloudflare/security-audit-skill](https://github.com/cloudflare/security-audit-skill) | c1c8a8c | MIT (`cloudflare-security-audit-LICENSE`) |
| diagnosing-superpowers, dispatching-parallel-agents, executing-plans, finishing-a-development-branch, receiving-code-review, requesting-code-review, subagent-driven-development, systematic-debugging, test-driven-development, using-git-worktrees, verification-before-completion, writing-plans, writing-skills | [obra/superpowers](https://github.com/obra/superpowers) | bb92a77 | MIT (`superpowers-LICENSE`) |
| taste-skill | [Leonxlnx/taste-skill](https://github.com/Leonxlnx/taste-skill) | 12af471 (sin `evals/`) | MIT (`taste-skill-LICENSE`) |
| redesign-skill | [Leonxlnx/taste-skill](https://github.com/Leonxlnx/taste-skill) | d237dd3 (ya no está en el repo de origen) | MIT (`taste-skill-LICENSE`) |
| supabase, supabase-postgres-best-practices | [supabase/agent-skills](https://github.com/supabase/agent-skills) | c9be0e9 | MIT (`supabase-agent-skills-LICENSE`) |

Son guías de referencia: si chocan con las reglas del proyecto (`AGENTS.md`,
p. ej. la arquitectura actual sin BLoC/Riverpod ni Dio), mandan las del
proyecto. Las skills de taste están pensadas para web; de ellas se aplican los
principios de diseño (evitar lo genérico, jerarquía, espaciado), no las
librerías web. Los `scripts/*.mjs` de taste-skill necesitan Node y Chrome y no se han ejecutado al vendorizarla.
