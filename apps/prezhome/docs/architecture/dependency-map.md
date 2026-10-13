# Mapa de dependencias de módulos

Archivo generado por `dart run tool/architecture/dependency_map.dart`.

## Resumen de módulos

| Módulo | Ficheros Dart |
| --- | ---: |
| `models` | 13 |
| `onboarding` | 2 |
| `screens` | 29 |
| `services` | 29 |
| `tabs` | 3 |
| `theme` | 6 |
| `utils` | 16 |
| `widgets` | 20 |

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

- `screens` -> `models`: 49
- `screens` -> `services`: 47
- `screens` -> `widgets`: 47
- `screens` -> `utils`: 40
- `screens` -> `theme`: 29
- `widgets` -> `theme`: 25
- `tabs` -> `screens`: 15
- `services` -> `models`: 9
- `tabs` -> `widgets`: 8
- `tabs` -> `models`: 7
- `services` -> `utils`: 6
- `services` -> `widgets`: 5
- `onboarding` -> `theme`: 4
- `screens` -> `tabs`: 3
- `tabs` -> `services`: 3
- `tabs` -> `theme`: 3
- `utils` -> `models`: 3
- `widgets` -> `models`: 3
- `widgets` -> `utils`: 3
- `models` -> `utils`: 2
- `onboarding` -> `models`: 2
- `utils` -> `widgets`: 2
- `widgets` -> `services`: 2
- `onboarding` -> `screens`: 1
- `onboarding` -> `services`: 1
- `screens` -> `onboarding`: 1
- `tabs` -> `utils`: 1
- `utils` -> `services`: 1

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
