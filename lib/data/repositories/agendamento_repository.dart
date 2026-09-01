import 'package:sqflite/sqflite.dart';
import '../../core/database/db_helper.dart';
import '../models/agendamento_model.dart';

class AgendamentoRepository {
  final DatabaseHelper dbHelper = DatabaseHelper.instance;

  Future<int> inserir(Agendamento agendamento) async {
    final db = await dbHelper.database;
    return await db.insert('agendamentos', agendamento.toMap());
  }

  Future<List<Agendamento>> listarTodos() async {
    final db = await dbHelper.database;
    final result = await db.query('agendamentos', orderBy: 'dataHoraInicio ASC');
    return result.map((json) => Agendamento.fromMap(json)).toList();
  }

  Future<int> atualizar(Agendamento agendamento) async {
    final db = await dbHelper.database;
    return await db.update(
      'agendamentos',
      agendamento.toMap(),
      where: 'id = ?',
      whereArgs: [agendamento.id],
    );
  }

  Future<int> atualizarStatus(int id, String novoStatus) async {
    final db = await dbHelper.database;
    return await db.update(
      'agendamentos',
      {'status': novoStatus},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deletar(int id) async {
    final db = await dbHelper.database;
    return await db.delete(
      'agendamentos',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
