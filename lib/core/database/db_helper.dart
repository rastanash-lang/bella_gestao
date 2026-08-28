import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('bella_finance_v5.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE transacoes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        descricao TEXT NOT NULL,
        cliente TEXT,
        valor REAL NOT NULL,
        tipo TEXT NOT NULL,
        ambito TEXT NOT NULL,
        categoria TEXT NOT NULL,
        formaPagamento TEXT NOT NULL,
        status TEXT NOT NULL,
        tipoCusto TEXT,
        tipoReceita TEXT,
        parcelaAtual INTEGER DEFAULT 1,
        totalParcelas INTEGER DEFAULT 1,
        data TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE cofrinhos (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        titulo TEXT NOT NULL,
        valorAlvo REAL NOT NULL,
        valorAtual REAL NOT NULL,
        dataCriacao TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE agendamentos (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        cliente TEXT NOT NULL,
        servico TEXT NOT NULL,
        valor REAL NOT NULL,
        dataHoraInicio TEXT NOT NULL,
        duracaoMinutos INTEGER NOT NULL,
        status TEXT NOT NULL,
        observacoes TEXT
      )
    ''');
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}
