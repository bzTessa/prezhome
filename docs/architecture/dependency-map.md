# Mapa de dependencias de módulos

Archivo generado por `dart run tool/architecture/dependency_map.dart`.

## Resumen de módulos

| Módulo | Ficheros Dart |
| --- | ---: |
| `models` | 10 |
| `screens` | 27 |
| `services` | 19 |
| `tabs` | 3 |
| `theme` | 6 |
| `utils` | 9 |
| `widgets` | 13 |

## Dependencias entre módulos

- `models` -> `utils`
- `screens` -> `models`, `screens`, `services`, `tabs`, `theme`, `utils`, `widgets`
- `services` -> `models`, `services`, `utils`, `widgets`
- `tabs` -> `models`, `screens`, `services`, `theme`, `widgets`
- `theme` -> `theme`
- `utils` -> `models`, `services`, `widgets`
- `widgets` -> `models`, `theme`, `utils`, `widgets`

## Importaciones cruzadas (conteo por módulo origen/destino)

- `screens` -> `models`: 39
- `screens` -> `widgets`: 36
- `screens` -> `services`: 26
- `screens` -> `theme`: 24
- `tabs` -> `screens`: 14
- `widgets` -> `theme`: 14
- `screens` -> `utils`: 9
- `tabs` -> `widgets`: 7
- `tabs` -> `models`: 6
- `screens` -> `tabs`: 3
- `services` -> `widgets`: 3
- `tabs` -> `theme`: 3
- `models` -> `utils`: 2
- `services` -> `models`: 2
- `services` -> `utils`: 2
- `tabs` -> `services`: 2
- `widgets` -> `models`: 2
- `widgets` -> `utils`: 2
- `utils` -> `models`: 1
- `utils` -> `services`: 1
- `utils` -> `widgets`: 1

## Ciclos detectados

- `models` -> `utils` -> `models`
- `models` -> `utils` -> `services` -> `models`
- `models` -> `utils` -> `services` -> `widgets` -> `models`
- `screens` -> `screens`
- `screens` -> `tabs` -> `screens`
- `services` -> `services`
- `services` -> `utils` -> `services`
- `services` -> `widgets` -> `utils` -> `services`
- `theme` -> `theme`
- `widgets` -> `widgets`
