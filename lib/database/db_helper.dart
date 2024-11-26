import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class BasedatoHelper {
  static final BasedatoHelper _instance = BasedatoHelper._internal();
  static Database? _database;

  BasedatoHelper._internal();

  factory BasedatoHelper() => _instance;

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