# Mapa de dependencias de módulos

Archivo generado por `dart run tool/architecture/dependency_map.dart`.

## Resumen de módulos

| Módulo | Ficheros Dart |
| --- | ---: |
| `models` | 13 |
| `onboarding` | 2 |
| `screens` | 28 |
| `services` | 24 |
| `tabs` | 3 |
| `theme` | 6 |
| `utils` | 15 |
| `widgets` | 17 |

## Dependencias entre módulos

- `models` -> `models`, `utils`
- `onboarding` -> `models`, `onboarding`, `screens`, `services`, `theme`
- `screens` -> `models`, `onboarding`, `screens`, `services`, `tabs`, `theme`, `utils`, `widgets`
- `services` -> `models`, `services`, `utils`, `widgets`
- `tabs` -> `models`, `screens`, `services`, `theme`, `utils`, `widgets`
- `theme` -> `theme`
- `utils` -> `models`, `services`, `widgets`
- `widgets` -> `models`, `services`, `theme`, `utils`, `widgets`

## Importaciones cruzadas (conteo por módulo origen/destino)

- `screens` -> `models`: 50
- `screens` -> `widgets`: 40
- `screens` -> `services`: 38
- `screens` -> `utils`: 37
- `screens` -> `theme`: 25
- `widgets` -> `theme`: 21
- `tabs` -> `screens`: 15
- `tabs` -> `widgets`: 8
- `tabs` -> `models`: 7
- `services` -> `models`: 5
- `onboarding` -> `theme`: 4
- `screens` -> `tabs`: 3
- `services` -> `utils`: 3
- `services` -> `widgets`: 3
- `tabs` -> `theme`: 3
- `utils` -> `models`: 3
- `widgets` -> `utils`: 3
- `models` -> `utils`: 2
- `onboarding` -> `models`: 2
- `tabs` -> `services`: 2
- `utils` -> `widgets`: 2
- `widgets` -> `models`: 2
- `onboarding` -> `screens`: 1
- `onboarding` -> `services`: 1
- `screens` -> `onboarding`: 1
- `tabs` -> `utils`: 1
- `utils` -> `services`: 1
- `widgets` -> `services`: 1

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
- `services` -> `widgets` -> `utils` -> `services`
- `theme` -> `theme`
- `widgets` -> `widgets`
