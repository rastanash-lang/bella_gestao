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
      version: 2, // Elevação de versão para disparar o onUpgrade
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
      onOpen: (db) async {
        // Garantias adicionais de compatibilidade
        try {
          await db.execute('ALTER TABLE transacoes ADD COLUMN agendamento_id INTEGER');
        } catch (_) {}

        try {
          await db.execute('ALTER TABLE agendamentos ADD COLUMN antecedenciaLembreteMinutos INTEGER DEFAULT 15');
        } catch (_) {}

        await db.execute('''
          CREATE TABLE IF NOT EXISTS produtos (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            nome TEXT NOT NULL,
            categoria TEXT NOT NULL,
            quantidadeAtual INTEGER NOT NULL,
            quantidadeMinima INTEGER NOT NULL,
            precoCusto REAL NOT NULL,
            precoVenda REAL NOT NULL,
            unidade TEXT NOT NULL
          )
        ''');
      },
    );
  }

  // Migration de schema entre versões
  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      try {
        await db.execute('ALTER TABLE transacoes ADD COLUMN agendamento_id INTEGER');
      } catch (_) {}
    }
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
        agendamento_id INTEGER,
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
        observacoes TEXT,
        antecedenciaLembreteMinutos INTEGER DEFAULT 15
      )
    ''');

    await db.execute('''
      CREATE TABLE produtos (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nome TEXT NOT NULL,
        categoria TEXT NOT NULL,
        quantidadeAtual INTEGER NOT NULL,
        quantidadeMinima INTEGER NOT NULL,
        precoCusto REAL NOT NULL,
        precoVenda REAL NOT NULL,
        unidade TEXT NOT NULL
      )
    ''');
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}
