import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class BasedatoHelper {
  static final BasedatoHelper _instance = BasedatoHelper._internal();
  static Database? _database;

  BasedatoHelper._internal();

  factory BasedatoHelper() => _instance;

  deleteDB() async {
    try {
      _database = null;
      deleteDatabase(
          "/data/user/0/com.example.app_finance/databases/app_finance.db");
    } catch (e) {
      print("============================error ${e.toString()}");
    }
  }

  getDbPath() async {
    String databasePath = await getDatabasesPath();
    print('========================databasePath: $databasePath');
    Directory? externalStoragePath = await getExternalStorageDirectory();
    print('========================externalStoragePath: $externalStoragePath');
  }

  backupDB() async {
    var status = await Permission.manageExternalStorage.status;
    if (!status.isGranted) {
      await Permission.manageExternalStorage.request();
    }
    var status1 = await Permission.storage.status;
    if (!status1.isGranted) {
      await Permission.storage.request();
    }
    try {
      File ourDBFile =
          File('/data/user/0/com.example.app_finance/databases/app_finance.db');
      Directory? folderPathForDBFile =
          Directory("/storage/emulated/0/financeDatabase");
      await folderPathForDBFile.create();
      await ourDBFile
          .copy('/storage/emulated/0/financeDatabase/app_finance.db');
    } catch (e) {
      print("============================error ${e.toString()}");
    }
  }

  restoreD() async {
    var status = await Permission.manageExternalStorage.status;
    if (!status.isGranted) {
      await Permission.manageExternalStorage.request();
    }
    var status1 = await Permission.storage.status;
    if (!status1.isGranted) {
      await Permission.storage.request();
    }
    try {
      File savedDBFile =
          File('/storage/emulated/0/financeDatabase/app_finance.db');
      await savedDBFile.copy(
          '/data/user/0/com.example.app_finance/databases/app_finance.db');
    } catch (e) {
      print("============================error ${e.toString()}");
    }
  }

  Future<String> exportDatabase() async {
    // Obtén la ubicación del directorio de la base de datos
    final directory = await getApplicationDocumentsDirectory();
    final databasePath = directory.path +
        '/app_finance.db'; // Aquí el nombre de tu base de datos
    final file = File(databasePath);

    // Genera el archivo de exportación
    final now = DateTime.now();
    final exportPath = '${directory.path}/backup_${now.toString()}.db';
    await file.copy(exportPath);

    return exportPath; // Retorna la ruta del archivo exportado
  }

  Future<void> importDatabase(String path) async {
    final directory = await getApplicationDocumentsDirectory();
    final databasePath = directory.path + '/app_finance.db';
    final backupFile = File(path);

    // Copia el archivo de respaldo al directorio de la base de datos
    await backupFile.copy(databasePath);
  }

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _openDataBase();
    return _database!;
  }

  Future<Database> _openDataBase() async {
    final databasePath = await getDatabasesPath();
    final path = join(databasePath, 'finance_app.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        // Habilitar claves foráneas
        await db.execute('PRAGMA foreign_keys = ON');

        // Crear tabla grupos
        await db.execute('''
          CREATE TABLE grupos (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            nombre TEXT NOT NULL,
            descripcion TEXT,
            tipo TEXT CHECK (tipo IN ('ingreso', 'egreso')) NOT NULL
          );
        ''');

        // Crear tabla categorias
        await db.execute('''
          CREATE TABLE categorias (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            grupo_id INTEGER NOT NULL,
            nombre TEXT NOT NULL,
            descripcion TEXT,
            tipo TEXT CHECK (tipo IN ('ingreso', 'egreso')) NOT NULL,
            FOREIGN KEY (grupo_id) REFERENCES grupos (id) ON DELETE CASCADE
          );
        ''');

        // Crear tabla transacciones
        await db.execute('''
          CREATE TABLE transacciones (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            categoria_id INTEGER NOT NULL,
            titulo TEXT NOT NULL,
            descripcion TEXT,
            tipo TEXT CHECK (tipo IN ('ingreso', 'egreso')) NOT NULL,
            monto REAL NOT NULL,
            fecha DATETIME DEFAULT CURRENT_TIMESTAMP,
            FOREIGN KEY (categoria_id) REFERENCES categorias (id) ON DELETE CASCADE
          );
        ''');

        // Crear tabla presupuestos
        await db.execute('''
          CREATE TABLE presupuestos (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            tipo TEXT NOT NULL,
            grupo_id INTEGER,
            categoria_id INTEGER,
            monto REAL NOT NULL,
            inicio TEXT NOT NULL,
            fin TEXT NOT NULL,
            FOREIGN KEY (grupo_id) REFERENCES grupos(id) ON DELETE CASCADE,
            FOREIGN KEY (categoria_id) REFERENCES categorias(id) ON DELETE CASCADE
          );
        ''');
      },
    );
  }

  Future<List<Map<String, dynamic>>> _cargarPresupuestosYGastos() async {
    final db = await database; // Asegúrate de tener esta función
    final presupuestos = await db.rawQuery('''
    SELECT 
      presupuestos.id AS presupuesto_id,
      categorias.nombre AS presupuesto,
      presupuestos.monto AS monto_presupuesto,
      (SELECT SUM(monto) FROM transacciones 
       WHERE transacciones.categoria_id = presupuestos.categoria_id 
       AND transacciones.fecha BETWEEN presupuestos.inicio AND presupuestos.fin) 
       AS total_gastos
    FROM presupuestos
    LEFT JOIN categorias ON presupuestos.categoria_id = categorias.id
  ''');

    return presupuestos;
  }

  Future<List<Map<String, dynamic>>> obtenerPresupuestosConGastos(
      DateTime inicioMes, DateTime finMes) async {
    final db = await database;
    return await db.rawQuery('''
 SELECT p.nombre AS presupuesto, 
        p.monto AS monto_presupuesto, 
        COALESCE(SUM(t.monto), 0) AS total_gastos
 FROM presupuestos p
 LEFT JOIN transacciones t ON t.tipo = 'egreso' 
   AND t.fecha BETWEEN ? AND ?
   AND p.id = t.presupuesto_id
 WHERE p.inicio BETWEEN ? AND ?
    OR p.fin BETWEEN ? AND ?
 GROUP BY p.id
''', [
      inicioMes.toIso8601String(),
      finMes.toIso8601String(),
      inicioMes.toIso8601String(),
      finMes.toIso8601String(),
      inicioMes.toIso8601String(),
      finMes.toIso8601String(),
    ]);
  }

  Future<List<Map<String, dynamic>>> obtenerTotalesPorGrupo(
      DateTime inicio, DateTime fin) async {
    final db = await database;
    return db.rawQuery('''
 SELECT g.nombre AS grupo, SUM(t.monto) AS total
 FROM transacciones t  // Cambié 'transaccion' por 'transacciones'
 JOIN categorias c ON t.categoria_id = c.id  // Cambié 'categoria' por 'categorias'
 JOIN grupos g ON c.grupo_id = g.id  // Cambié 'grupo' por 'grupos'
 WHERE t.tipo = 'egreso' AND t.fecha BETWEEN ? AND ?
 GROUP BY g.nombre
''', [inicio.toIso8601String(), fin.toIso8601String()]);
  }

  Future<Map<int, double>> obtenerMontoEgresosPorCategoria() async {
    final db = await database;

    // Consulta para obtener el monto total de los egresos por categoría
    final List<Map<String, dynamic>> result = await db.rawQuery('''
    SELECT categoriaId, SUM(monto) AS totalEgresos
    FROM Transaccion
    WHERE tipo = 'egreso'
    GROUP BY categoriaId
  ''');

    // Convertir los resultados a un mapa {categoriaId: montoEgresos}
    Map<int, double> egresos = {};
    for (var row in result) {
      egresos[row['categoriaId']] = row['totalEgresos'] ?? 0.0;
    }

    return egresos;
  }

  Future<Map<String, double>> obtenerTotalesPorMes(DateTime fecha) async {
    final db = await database;

    // Obtén el año y mes del `fecha` seleccionada
    String mesStr = '${fecha.year}-${fecha.month.toString().padLeft(2, '0')}';

    // Consulta para sumar los ingresos y egresos del mes
    final result = await db.rawQuery('''
    SELECT 
      tipo, 
      SUM(monto) AS total
    FROM 
      transacciones
    WHERE 
      strftime('%Y-%m', fecha) = ?
    GROUP BY 
      tipo
  ''', [mesStr]);

    // Procesar resultados para separar ingresos y egresos
    double totalIngresos = 0.0;
    double totalEgresos = 0.0;
    for (var row in result) {
      if (row['tipo'] == 'ingreso') {
        totalIngresos = (row['total'] as num?)?.toDouble() ?? 0.0;
      } else if (row['tipo'] == 'egreso') {
        totalEgresos = (row['total'] as num?)?.toDouble() ?? 0.0;
      }
    }

    return {'ingresos': totalIngresos, 'egresos': totalEgresos};
  }

  Future<Map<String, double>> obtenerTotalesPorDia(DateTime fecha) async {
    final db = await database;

    // Convierte la fecha al formato `YYYY-MM-DD`
    String fechaStr = fecha.toIso8601String().split('T').first;

    // Consulta para sumar los ingresos y egresos del día
    final result = await db.rawQuery('''
    SELECT 
      tipo, 
      SUM(monto) AS total
    FROM 
      transacciones
    WHERE 
      date(fecha) = ?
    GROUP BY 
      tipo
  ''', [fechaStr]);

    // Procesar resultados para separar ingresos y egresos
    double totalIngresos = 0.0;
    double totalEgresos = 0.0;
    for (var row in result) {
      if (row['tipo'] == 'ingreso') {
        totalIngresos = (row['total'] as num?)?.toDouble() ?? 0.0;
      } else if (row['tipo'] == 'egreso') {
        totalEgresos = (row['total'] as num?)?.toDouble() ?? 0.0;
      }
    }

    return {'ingresos': totalIngresos, 'egresos': totalEgresos};
  }

  Future<List<Map<String, dynamic>>> obtenerTransaccionesPorFecha(
      DateTime fecha) async {
    final db = await database;

    // Convierte la fecha al formato `YYYY-MM-DD`
    String fechaStr = fecha.toIso8601String().split('T').first;

    // Consulta con JOIN para obtener información adicional
    return await db.rawQuery('''
    SELECT 
      t.id AS transaccion_id, 
      t.titulo, 
      t.descripcion, 
      t.monto, 
      t.fecha, 
      t.tipo, 
      c.nombre AS categoria_nombre, 
      g.nombre AS grupo_nombre
    FROM 
      transacciones t
    JOIN 
      categorias c ON t.categoria_id = c.id
    JOIN 
      grupos g ON c.grupo_id = g.id
    WHERE 
      date(t.fecha) = ?
  ''', [fechaStr]);
  }

  Future<List<Map<String, dynamic>>> obtenerTransaccionesPorRango(
      DateTime inicio, DateTime fin) async {
    final db = await database; // Obtén la instancia de la base de datos
    return await db.query(
      'Transaccion',
      where: 'fecha BETWEEN ? AND ?',
      whereArgs: [inicio.toIso8601String(), fin.toIso8601String()],
    );
  }

  Future<List<Map<String, dynamic>>> obtenerGastosPorCategoria(
      DateTime inicio, DateTime fin) async {
    final db = await database; // Obtén la base de datos

    // Ejecutar la consulta SQL
    return await db.rawQuery('''
    SELECT 
        c.nombre AS categoria, 
        SUM(t.monto) AS total
    FROM 
        transacciones t
    JOIN 
        categorias c ON t.categoria_id = c.id
    WHERE 
        t.tipo = 'egreso'
        AND t.fecha BETWEEN ? AND ?
    GROUP BY 
        c.nombre
  ''', [inicio.toIso8601String(), fin.toIso8601String()]);
  }

  Future<List<Map<String, dynamic>>> obtenerIngresosPorCategoria(
      DateTime inicio, DateTime fin) async {
    final db = await database; // Obtén la base de datos

    // Ejecutar la consulta SQL
    return await db.rawQuery('''
    SELECT 
        c.nombre AS categoria, 
        SUM(t.monto) AS total
    FROM 
        transacciones t
    JOIN 
        categorias c ON t.categoria_id = c.id
    WHERE 
        t.tipo = 'ingreso'
        AND t.fecha BETWEEN ? AND ?
    GROUP BY 
        c.nombre
  ''', [inicio.toIso8601String(), fin.toIso8601String()]);
  }

  // Obtener transacciones de los últimos 7 días
  Future<List<Map<String, dynamic>>> obtenerTransaccionesUltimaSemana() async {
    final db = await database;

    // Obtén la fecha de hace 7 días
    DateTime fechaLimite = DateTime.now().subtract(const Duration(days: 7));
    String fechaLimiteStr = fechaLimite.toIso8601String();

    // Query que obtiene las transacciones de los últimos 7 días
    final List<Map<String, dynamic>> transacciones = await db.rawQuery('''
      SELECT fecha, tipo, SUM(monto) AS total
      FROM transacciones
      WHERE fecha >= ?
      GROUP BY strftime('%Y-%m-%d', fecha), tipo
      ORDER BY fecha DESC
    ''', [fechaLimiteStr]);

    return transacciones;
  }

  // Función pública que llama a la privada _cargarPresupuestosYGastos()
  Future<List<Map<String, dynamic>>> obtenerPresupuestosYGastos() async {
    return await _cargarPresupuestosYGastos(); // Llamada a la función privada
  }

  // Limpia todas las tablas de la base de datos
  Future<void> clearDatabase() async {
    final db = await database;

    // Deshabilitar claves foráneas temporalmente para evitar conflictos al eliminar datos
    await db.execute('PRAGMA foreign_keys = OFF');

    // Eliminar los registros de cada tabla
    await db.delete('transacciones');
    await db.delete('categorias');
    await db.delete('grupos');
    await db.delete('presupuestos');

    // Rehabilitar claves foráneas
    await db.execute('PRAGMA foreign_keys = ON');

    print('La base de datos ha sido limpiada completamente.');
  }

  // Muestra en consola todos los registros de todas las tablas
  Future<void> printAllRecords() async {
    final db = await database;

    print('--- Contenido de la base de datos ---');

    // Consultar y mostrar los registros de la tabla "grupos"
    final grupos = await db.query('grupos');
    print('Tabla "grupos":');
    for (var grupo in grupos) {
      print(grupo);
    }

    // Consultar y mostrar los registros de la tabla "categorias"
    final categorias = await db.query('categorias');
    print('Tabla "categorias":');
    for (var categoria in categorias) {
      print(categoria);
    }

    // Consultar y mostrar los registros de la tabla "transacciones"
    final transacciones = await db.query('transacciones');
    print('Tabla "transacciones":');
    for (var transaccion in transacciones) {
      print(transaccion);
    }

    // Consultar y mostrar los registros de la tabla "presupuestos"
    final presupuestos = await db.query('presupuestos');
    print('Tabla "presupuestos":');
    for (var presupuesto in presupuestos) {
      print(presupuesto);
    }

    print('-------------------------------------');
  }
}
