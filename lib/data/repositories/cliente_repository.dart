import 'package:sqflite/sqflite.dart';
import '../../core/database/db_helper.dart';
import '../models/cliente_model.dart';

class ClienteRepository {
  final DatabaseHelper dbHelper = DatabaseHelper.instance;

  Future<int> inserir(Cliente cliente) async {
    final db = await dbHelper.database;
    return await db.insert('clientes', cliente.toMap());
  }

  Future<List<Cliente>> listarTodos() async {
    final db = await dbHelper.database;
    final result = await db.query('clientes', orderBy: 'nome ASC');
    return result.map((json) => Cliente.fromMap(json)).toList();
  }

  Future<int> atualizar(Cliente cliente) async {
    final db = await dbHelper.database;
    return await db.update(
      'clientes',
      cliente.toMap(),
      where: 'id = ?',
      whereArgs: [cliente.id],
    );
  }

  Future<int> deletar(int id) async {
    final db = await dbHelper.database;
    return await db.delete(
      'clientes',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
