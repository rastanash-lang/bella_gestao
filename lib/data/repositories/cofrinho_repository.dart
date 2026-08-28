import 'package:sqflite/sqflite.dart';
import '../../core/database/db_helper.dart';
import '../models/cofrinho_model.dart';

class CofrinhoRepository {
  final DatabaseHelper dbHelper = DatabaseHelper.instance;

  Future<int> inserir(MetaCofrinho meta) async {
    final db = await dbHelper.database;
    return await db.insert('cofrinhos', meta.toMap());
  }

  Future<List<MetaCofrinho>> listarTodos() async {
    final db = await dbHelper.database;
    final result = await db.query('cofrinhos', orderBy: 'id DESC');
    return result.map((json) => MetaCofrinho.fromMap(json)).toList();
  }

  Future<int> atualizarValor(int id, double novoValor) async {
    final db = await dbHelper.database;
    return await db.update(
      'cofrinhos',
      {'valorAtual': novoValor},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deletar(int id) async {
    final db = await dbHelper.database;
    return await db.delete(
      'cofrinhos',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
