# Mapa de dependencias de módulos

Archivo generado por `dart run tool/architecture/dependency_map.dart`.

## Resumen de módulos

| Módulo | Ficheros Dart |
| --- | ---: |
| `models` | 13 |
| `onboarding` | 2 |
| `screens` | 30 |
| `services` | 32 |
| `tabs` | 3 |
| `theme` | 7 |
| `utils` | 16 |
| `widgets` | 19 |

## Dependencias entre módulos

- `models` -> `models`, `utils`
- `onboarding` -> `models`, `onboarding`, `screens`, `services`, `theme`, `widgets`
- `screens` -> `models`, `onboarding`, `screens`, `services`, `tabs`, `theme`, `utils`, `widgets`
- `services` -> `models`, `services`, `utils`, `widgets`
- `tabs` -> `models`, `screens`, `services`, `theme`, `utils`, `widgets`
- `theme` -> `services`, `theme`
- `utils` -> `models`, `services`, `theme`, `widgets`
- `widgets` -> `models`, `services`, `theme`, `utils`, `widgets`

## Importaciones cruzadas (conteo por módulo origen/destino)

- `screens` -> `services`: 54
- `screens` -> `widgets`: 51
- `screens` -> `models`: 50
- `screens` -> `utils`: 43
- `screens` -> `theme`: 34
- `widgets` -> `theme`: 23
- `tabs` -> `screens`: 14
- `services` -> `models`: 11
- `tabs` -> `widgets`: 7
- `services` -> `utils`: 6
- `tabs` -> `models`: 6
- `services` -> `widgets`: 5
- `onboarding` -> `theme`: 4
- `screens` -> `tabs`: 3
- `tabs` -> `services`: 3
- `tabs` -> `theme`: 3
- `utils` -> `widgets`: 3
- `widgets` -> `services`: 3
- `models` -> `utils`: 2
- `onboarding` -> `models`: 2
- `utils` -> `models`: 2
- `widgets` -> `models`: 2
- `onboarding` -> `screens`: 1
- `onboarding` -> `services`: 1
- `onboarding` -> `widgets`: 1
- `screens` -> `onboarding`: 1
- `tabs` -> `utils`: 1
- `theme` -> `services`: 1
- `utils` -> `services`: 1
- `utils` -> `theme`: 1
- `widgets` -> `utils`: 1

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
