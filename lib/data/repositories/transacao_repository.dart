import 'package:sqflite/sqflite.dart';
import '../../core/database/db_helper.dart';
import '../models/transacao_model.dart';

class TransacaoRepository {
  final DatabaseHelper dbHelper = DatabaseHelper.instance;

  Future<int> inserir(Transacao transacao) async {
    final db = await dbHelper.database;
    return await db.insert('transacoes', transacao.toMap());
  }

  Future<List<Transacao>> listarTodas() async {
    final db = await dbHelper.database;
    final result = await db.query('transacoes', orderBy: 'data DESC');
    return result.map((json) => Transacao.fromMap(json)).toList();
  }

  Future<int> atualizar(Transacao transacao) async {
    final db = await dbHelper.database;
    return await db.update(
      'transacoes',
      transacao.toMap(),
      where: 'id = ?',
      whereArgs: [transacao.id],
    );
  }

  Future<int> alternarStatusPago(int id, String novoStatus) async {
    final db = await dbHelper.database;
    return await db.update(
      'transacoes',
      {'status': novoStatus},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deletar(int id) async {
    final db = await dbHelper.database;
    return await db.delete(
      'transacoes',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
