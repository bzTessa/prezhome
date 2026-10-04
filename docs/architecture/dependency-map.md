# Mapa de dependencias de módulos

Archivo generado por `dart run tool/architecture/dependency_map.dart`.

## Resumen de módulos

| Módulo | Ficheros Dart |
| --- | ---: |
| `models` | 10 |
| `screens` | 26 |
| `services` | 11 |
| `tabs` | 3 |
| `theme` | 6 |
| `utils` | 5 |
| `widgets` | 10 |

## Dependencias entre módulos

- `models` -> `utils`
- `screens` -> `models`, `screens`, `services`, `tabs`, `theme`, `utils`, `widgets`
- `services` -> `models`, `services`, `utils`, `widgets`
- `tabs` -> `models`, `screens`, `services`, `theme`, `widgets`
- `theme` -> `theme`
- `utils` -> `widgets`
- `widgets` -> `models`, `theme`, `widgets`

## Importaciones cruzadas (conteo por módulo origen/destino)

- `screens` -> `models`: 38
- `screens` -> `theme`: 22
- `screens` -> `widgets`: 22
- `screens` -> `services`: 18
- `tabs` -> `screens`: 13
- `widgets` -> `theme`: 8
- `tabs` -> `widgets`: 7
- `tabs` -> `models`: 6
- `screens` -> `utils`: 5
- `screens` -> `tabs`: 3
- `services` -> `widgets`: 3
- `tabs` -> `theme`: 3
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
- `theme` -> `theme`
- `widgets` -> `widgets`
