# Mapa de dependencias de módulos

Archivo generado por `dart run tool/architecture/dependency_map.dart`.

## Resumen de módulos

| Módulo | Ficheros Dart |
| --- | ---: |
| `models` | 12 |
| `screens` | 29 |
| `services` | 21 |
| `tabs` | 3 |
| `theme` | 6 |
| `utils` | 11 |
| `widgets` | 14 |

## Dependencias entre módulos

- `models` -> `utils`
- `screens` -> `models`, `screens`, `services`, `tabs`, `theme`, `utils`, `widgets`
- `services` -> `models`, `services`, `utils`, `widgets`
- `tabs` -> `models`, `screens`, `services`, `theme`, `widgets`
- `theme` -> `theme`
- `utils` -> `models`, `services`, `widgets`
- `widgets` -> `models`, `services`, `theme`, `utils`, `widgets`

## Importaciones cruzadas (conteo por módulo origen/destino)

- `screens` -> `models`: 46
- `screens` -> `widgets`: 37
- `screens` -> `services`: 32
- `screens` -> `theme`: 26
- `widgets` -> `theme`: 15
- `tabs` -> `screens`: 14
- `screens` -> `utils`: 12
- `tabs` -> `widgets`: 7
- `tabs` -> `models`: 6
- `screens` -> `tabs`: 3
- `services` -> `models`: 3
- `services` -> `widgets`: 3
- `tabs` -> `theme`: 3
- `models` -> `utils`: 2
- `services` -> `utils`: 2
- `tabs` -> `services`: 2
- `widgets` -> `models`: 2
- `widgets` -> `utils`: 2
- `utils` -> `models`: 1
- `utils` -> `services`: 1
- `utils` -> `widgets`: 1
- `widgets` -> `services`: 1

## Ciclos detectados

- `models` -> `utils` -> `models`
- `models` -> `utils` -> `services` -> `models`
- `models` -> `utils` -> `services` -> `widgets` -> `models`
- `screens` -> `screens`
- `screens` -> `tabs` -> `screens`
- `services` -> `services`
- `services` -> `utils` -> `services`
- `services` -> `widgets` -> `services`
- `services` -> `widgets` -> `utils` -> `services`
- `theme` -> `theme`
- `widgets` -> `widgets`
