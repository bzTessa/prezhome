/// Implementación en disco de [LocalStore] para la caché offline-first.
///
/// Guarda cada clave como un fichero JSON dentro del directorio de documentos
/// de la app (resuelto con `path_provider`). Es el ÚNICO archivo del Paso 7 que
/// toca `path_provider`/el binding nativo, para que el resto de la lógica
/// (SyncQueue, merge, OfflineRepository) siga siendo Dart PURO y testeable en
/// la VM con [InMemoryLocalStore].
///
/// DEGRADACIÓN ELEGANTE: si el directorio de documentos no está disponible (por
/// ejemplo en un entorno sin binding, o si el plugin falla), ninguna operación
/// lanza: [read] devuelve `null`, y [write]/[remove]/[clearAll] no hacen nada.
/// Así la app arranca igual (quedándose solo en memoria) en lugar de romperse.
///
/// Esta clase NO se testea en la VM (requiere binding nativo); su contrato de
/// lectura/escritura queda cubierto por los tests que usan [InMemoryLocalStore].
library;

import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import 'local_store.dart';

/// [LocalStore] respaldado por ficheros JSON en el directorio de documentos.
class FileLocalStore implements LocalStore {
  /// Subcarpeta dentro del directorio de documentos donde viven los ficheros de
  /// caché/cola, para no mezclarlos con otros datos de la app.
  final String folderName;

  FileLocalStore({this.folderName = 'offline_cache'});

  /// Directorio resuelto (perezoso). `null` si todavía no se ha resuelto.
  Directory? _dir;

  /// Resuelve (y crea si hace falta) el directorio de caché. Devuelve `null` si
  /// no se puede, en cuyo caso el store degrada a "sin persistencia".
  Future<Directory?> _resolveDir() async {
    if (_dir != null) return _dir;
    try {
      final docs = await getApplicationDocumentsDirectory();
      final dir = Directory('${docs.path}/$folderName');
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
      _dir = dir;
      return dir;
    } catch (_) {
      // Sin binding/plugin o sin permisos: degradamos sin romper.
      return null;
    }
  }

  /// Convierte una clave (que puede contener `:`) en un nombre de fichero
  /// seguro. Codificamos los caracteres problemáticos para el sistema de
  /// ficheros manteniendo la clave reconstruible de forma unívoca.
  String _fileNameFor(String key) {
    final safe = base64Url.encode(utf8.encode(key));
    return '$safe.json';
  }

  File? _fileFor(Directory dir, String key) {
    return File('${dir.path}/${_fileNameFor(key)}');
  }

  @override
  Future<String?> read(String key) async {
    try {
      final dir = await _resolveDir();
      if (dir == null) return null;
      final file = _fileFor(dir, key)!;
      if (!await file.exists()) return null;
      return await file.readAsString();
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> write(String key, String value) async {
    try {
      final dir = await _resolveDir();
      if (dir == null) return;
      final file = _fileFor(dir, key)!;
      await file.writeAsString(value, flush: true);
    } catch (_) {
      // Degradación elegante: si no se puede escribir, no rompemos la app.
    }
  }

  @override
  Future<void> remove(String key) async {
    try {
      final dir = await _resolveDir();
      if (dir == null) return;
      final file = _fileFor(dir, key)!;
      if (await file.exists()) {
        await file.delete();
      }
    } catch (_) {
      // Degradación elegante.
    }
  }

  @override
  Future<void> clearAll() async {
    try {
      final dir = await _resolveDir();
      if (dir == null) return;
      if (await dir.exists()) {
        await for (final entity in dir.list()) {
          if (entity is File && entity.path.endsWith('.json')) {
            await entity.delete();
          }
        }
      }
    } catch (_) {
      // Degradación elegante.
    }
  }
}
