import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../../data/models/transacao_model.dart';
import '../../data/models/agendamento_model.dart';
import '../../data/models/cofrinho_model.dart';
import '../../data/models/produto_model.dart';

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
      version: 2,
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
      onOpen: (db) async {
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

  // 🛡️ RESTAURAÇÃO ATÔMICA COM TRANSAÇÃO DO SQLITE (BUG-05)
  // Se qualquer erro ocorrer, o SQLite realiza ROLLBACK automático e nada é apagado
  Future<void> restaurarBancoDados(Map<String, dynamic> dados) async {
    final db = await database;

    await db.transaction((txn) async {
      // 1. Limpa todas as tabelas dentro da transação atômica
      await txn.delete('transacoes');
      await txn.delete('agendamentos');
      await txn.delete('cofrinhos');
      await txn.delete('produtos');

      // 2. Valida e insere Transações
      if (dados.containsKey('transacoes') && dados['transacoes'] is List) {
        for (final item in dados['transacoes']) {
          final map = Map<String, dynamic>.from(item);
          final transacao = Transacao.fromMap(map);
          final mapToInsert = transacao.toMap();
          if (transacao.id == null) {
            mapToInsert.remove('id');
          }
          await txn.insert('transacoes', mapToInsert);
        }
      }

      // 3. Valida e insere Agendamentos
      if (dados.containsKey('agendamentos') && dados['agendamentos'] is List) {
        for (final item in dados['agendamentos']) {
          final map = Map<String, dynamic>.from(item);
          final agendamento = Agendamento.fromMap(map);
          final mapToInsert = agendamento.toMap();
          if (agendamento.id == null) {
            mapToInsert.remove('id');
          }
          await txn.insert('agendamentos', mapToInsert);
        }
      }

      // 4. Valida e insere Metas do Cofrinho
      if (dados.containsKey('cofrinhos') && dados['cofrinhos'] is List) {
        for (final item in dados['cofrinhos']) {
          final map = Map<String, dynamic>.from(item);
          final cofrinho = MetaCofrinho.fromMap(map);
          final mapToInsert = cofrinho.toMap();
          if (cofrinho.id == null) {
            mapToInsert.remove('id');
          }
          await txn.insert('cofrinhos', mapToInsert);
        }
      }

      // 5. Valida e insere Produtos do Estoque
      if (dados.containsKey('produtos') && dados['produtos'] is List) {
        for (final item in dados['produtos']) {
          final map = Map<String, dynamic>.from(item);
          final produto = Produto.fromMap(map);
          final mapToInsert = produto.toMap();
          if (produto.id == null) {
            mapToInsert.remove('id');
          }
          await txn.insert('produtos', mapToInsert);
        }
      }
    });
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}
