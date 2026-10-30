# Mapa de dependencias de módulos

Archivo generado por `dart run tool/architecture/dependency_map.dart`.

## Resumen de módulos

| Módulo | Ficheros Dart |
| --- | ---: |
| `data` | 1 |
| `models` | 13 |
| `onboarding` | 2 |
| `screens` | 31 |
| `services` | 44 |
| `tabs` | 3 |
| `theme` | 7 |
| `utils` | 18 |
| `widgets` | 32 |

## Dependencias entre módulos

- `data` -> (sin dependencias internas)
- `models` -> `models`, `utils`
- `onboarding` -> `models`, `onboarding`, `screens`, `services`, `theme`, `widgets`
- `screens` -> `models`, `onboarding`, `screens`, `services`, `tabs`, `theme`, `utils`, `widgets`
- `services` -> `data`, `models`, `services`, `utils`, `widgets`
- `tabs` -> `models`, `screens`, `services`, `theme`, `utils`, `widgets`
- `theme` -> `services`, `theme`
- `utils` -> `models`, `services`, `theme`, `widgets`
- `widgets` -> `models`, `services`, `theme`, `utils`, `widgets`

## Importaciones cruzadas (conteo por módulo origen/destino)

- `screens` -> `widgets`: 94
- `screens` -> `services`: 78
- `screens` -> `models`: 53
- `screens` -> `utils`: 51
- `widgets` -> `theme`: 39
- `screens` -> `theme`: 37
- `services` -> `models`: 30
- `tabs` -> `screens`: 14
- `services` -> `utils`: 11
- `tabs` -> `widgets`: 10
- `widgets` -> `services`: 9
- `services` -> `widgets`: 6
- `tabs` -> `models`: 6
- `tabs` -> `services`: 6
- `widgets` -> `models`: 5
- `onboarding` -> `theme`: 4
- `utils` -> `widgets`: 4
- `widgets` -> `utils`: 4
- `screens` -> `tabs`: 3
- `tabs` -> `theme`: 3
- `models` -> `utils`: 2
- `onboarding` -> `models`: 2
- `onboarding` -> `widgets`: 2
- `screens` -> `onboarding`: 2
- `tabs` -> `utils`: 2
- `utils` -> `models`: 2
- `onboarding` -> `screens`: 1
- `onboarding` -> `services`: 1
- `services` -> `data`: 1
- `theme` -> `services`: 1
- `utils` -> `services`: 1
- `utils` -> `theme`: 1

## Ciclos detectados

- `models` -> `models`
- `models` -> `utils` -> `models`
- `models` -> `utils` -> `services` -> `models`
- `models` -> `utils` -> `services` -> `widgets` -> `models`
- `onboarding` -> `onboarding`
- `onboarding` -> `screens` -> `onboarding`
- `screens` -> `screens`
- `screens` -> `tabs` -> `screens`
- `services` -> `services`
- `services` -> `utils` -> `services`
- `services` -> `widgets` -> `services`
- `services` -> `widgets` -> `theme` -> `services`
- `services` -> `widgets` -> `utils` -> `services`
- `theme` -> `theme`
- `widgets` -> `widgets`
