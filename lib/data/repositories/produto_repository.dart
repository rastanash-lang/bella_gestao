import 'package:sqflite/sqflite.dart';
import '../../core/database/db_helper.dart';
import '../models/produto_model.dart';

class ProdutoRepository {
  final DatabaseHelper dbHelper = DatabaseHelper.instance;

  Future<int> inserir(Produto produto) async {
    final db = await dbHelper.database;
    return await db.insert('produtos', produto.toMap());
  }

  Future<List<Produto>> listarTodos() async {
    final db = await dbHelper.database;
    final result = await db.query('produtos', orderBy: 'nome ASC');
    return result.map((json) => Produto.fromMap(json)).toList();
  }

  Future<int> atualizar(Produto produto) async {
    final db = await dbHelper.database;
    return await db.update(
      'produtos',
      produto.toMap(),
      where: 'id = ?',
      whereArgs: [produto.id],
    );
  }

  Future<int> atualizarQuantidade(int id, int novaQuantidade) async {
    final db = await dbHelper.database;
    return await db.update(
      'produtos',
      {'quantidadeAtual': novaQuantidade},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deletar(int id) async {
    final db = await dbHelper.database;
    return await db.delete(
      'produtos',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
