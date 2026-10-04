# Mapa de dependencias de módulos

Archivo generado por `dart run tool/architecture/dependency_map.dart`.

## Resumen de módulos

| Módulo | Ficheros Dart |
| --- | ---: |
| `models` | 10 |
| `screens` | 26 |
| `services` | 11 |
| `tabs` | 3 |
| `theme` | 1 |
| `utils` | 5 |
| `widgets` | 6 |

## Dependencias entre módulos

- `models` -> `utils`
- `screens` -> `models`, `screens`, `services`, `tabs`, `theme`, `utils`, `widgets`
- `services` -> `models`, `services`, `utils`, `widgets`
- `tabs` -> `models`, `screens`, `services`, `theme`, `widgets`
- `theme` -> (sin dependencias internas)
- `utils` -> `widgets`
- `widgets` -> `models`, `theme`, `widgets`

## Importaciones cruzadas (conteo por módulo origen/destino)

- `screens` -> `models`: 34
- `screens` -> `theme`: 22
- `screens` -> `widgets`: 21
- `screens` -> `services`: 18
- `tabs` -> `screens`: 14
- `tabs` -> `models`: 6
- `screens` -> `utils`: 4
- `widgets` -> `theme`: 4
- `screens` -> `tabs`: 3
- `services` -> `widgets`: 3
- `tabs` -> `theme`: 3
- `tabs` -> `widgets`: 3
- `models` -> `utils`: 2
- `services` -> `models`: 2
- `services` -> `utils`: 2
- `tabs` -> `services`: 2
- `utils` -> `widgets`: 1
- `widgets` -> `models`: 1

## Ciclos detectados

- `models` -> `utils` -> `widgets` -> `models`
- `screens` -> `screens`
- `screens` -> `tabs` -> `screens`
- `services` -> `services`
- `widgets` -> `widgets`
