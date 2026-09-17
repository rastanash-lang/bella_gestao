import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../controllers/financeiro_controller.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/produto_model.dart';
import 'novo_produto_view.dart';

class EstoqueView extends StatefulWidget {
  const EstoqueView({super.key});

  @override
  State<EstoqueView> createState() => _EstoqueViewState();
}

class _EstoqueViewState extends State<EstoqueView> {
  String _filtroTexto = '';
  String _filtroCategoria = 'Todos';

  void _abrirModalMovimentar(BuildContext context, Produto p, bool isEntrada) {
    final qtdCtrl = TextEditingController(text: '1');
    bool lancarCaixa = true;
    String formaPgto = 'Pix';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => AlertDialog(
          title: Row(
            children: [
              Icon(isEntrada ? Icons.add_circle : Icons.remove_circle, color: isEntrada ? Colors.green : Colors.orange),
              const SizedBox(width: 8),
              Text(isEntrada ? 'Entrada / Compra' : 'Saída / Uso ou Venda'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(p.nome, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              Text('Estoque atual: ${p.quantidadeAtual} ${p.unidade}', style: const TextStyle(color: Colors.grey, fontSize: 13)),
              const Divider(height: 20),
              TextField(
                controller: qtdCtrl,
                keyboardType: TextInputType.number,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: isEntrada ? 'Quantidade Comprada' : 'Quantidade Usada / Vendida',
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(isEntrada ? 'Lançar despesa no Caixa?' : 'Lançar receita (Venda) no Caixa?'),
                value: lancarCaixa,
                onChanged: (v) => setModalState(() => lancarCaixa = v),
              ),
              if (lancarCaixa) ...[
                DropdownButtonFormField<String>(
                  value: formaPgto,
                  decoration: const InputDecoration(labelText: 'Forma de Pagamento', border: OutlineInputBorder()),
                  items: ['Pix', 'Dinheiro', 'Débito', 'Crédito'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                  onChanged: (v) => setModalState(() => formaPgto = v!),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: isEntrada ? AppTheme.verdeEntrada : Colors.orange, foregroundColor: Colors.white),
              onPressed: () {
                final qtd = int.tryParse(qtdCtrl.text) ?? 1;
                if (qtd > 0) {
                  context.read<FinanceiroController>().movimentarEstoque(
                    produto: p,
                    quantidadeDelta: qtd,
                    isEntrada: isEntrada,
                    lancarNoCaixa: lancarCaixa,
                    formaPagamento: formaPgto,
                  );
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Estoque atualizado! ${lancarCaixa ? "Lançado no Caixa." : ""}'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              },
              child: const Text('Confirmar'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmarExclusao(BuildContext context, Produto p) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir Item?'),
        content: Text('Deseja remover "${p.nome}" do catálogo de estoque?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          TextButton(
            onPressed: () {
              context.read<FinanceiroController>().excluirProduto(p.id!);
              Navigator.pop(ctx);
            },
            child: const Text('Excluir', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<FinanceiroController>();
    final currency = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    final produtos = controller.produtos;
    final emAlerta = controller.produtosEstoqueBaixo;

    final filtrados = produtos.where((p) {
      final matchTexto = p.nome.toLowerCase().contains(_filtroTexto.toLowerCase()) ||
          p.categoria.toLowerCase().contains(_filtroTexto.toLowerCase());
      final matchCat = _filtroCategoria == 'Todos' ||
          (_filtroCategoria == 'Estoque Baixo' && p.estoqueBaixo) ||
          p.categoria == _filtroCategoria;
      return matchTexto && matchCat;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Estoque de Cosméticos'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Cadastrar Item',
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NovoProdutoView())),
          )
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Banner de Alerta de Estoque Baixo
          if (emAlerta.isNotEmpty)
            Card(
              elevation: 0,
              color: Colors.amber.shade50,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.amber.shade400, width: 1.5),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: Colors.amber, size: 28),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Atenção: ${emAlerta.length} item(ns) acabando!', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87)),
                          const Text('Reponha os produtos antes que faltem nos procedimentos.', style: TextStyle(fontSize: 11, color: Colors.black54)),
                        ],
                      ),
                    ),
                    ActionChip(
                      label: const Text('Ver', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                      onPressed: () => setState(() => _filtroCategoria = 'Estoque Baixo'),
                    )
                  ],
                ),
              ),
            ),
          const SizedBox(height: 12),

          // Campo de busca
          TextField(
            onChanged: (v) => setState(() => _filtroTexto = v),
            decoration: InputDecoration(
              hintText: 'Buscar tinta, shampoo, esmalte...',
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 8),

          // Chips de Filtro
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: ['Todos', 'Estoque Baixo', 'Coloração', 'Tratamento/Shampoo', 'Unhas/Esmaltes', 'Revenda Clientes'].map((cat) {
                final sel = _filtroCategoria == cat;
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: FilterChip(
                    label: Text(cat),
                    selected: sel,
                    selectedColor: cat == 'Estoque Baixo' ? Colors.amber.shade200 : null,
                    onSelected: (_) => setState(() => _filtroCategoria = cat),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),

          if (filtrados.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 50),
              child: Center(
                child: Column(
                  children: [
                    const Icon(Icons.inventory_2_outlined, size: 48, color: Colors.grey),
                    const SizedBox(height: 10),
                    const Text('Nenhum produto cadastrado no estoque.', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.add),
                      label: const Text('Cadastrar Primeiro Item'),
                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NovoProdutoView())),
                    )
                  ],
                ),
              ),
            )
          else
            ...filtrados.map((p) {
              final isBaixo = p.estoqueBaixo;

              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: BorderSide(
                    color: isBaixo ? Colors.amber.shade400 : Colors.grey.shade200,
                    width: isBaixo ? 1.5 : 1,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              p.nome,
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: isBaixo ? Colors.amber.shade100 : Colors.green.shade50,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              isBaixo ? '⚠️ ${p.quantidadeAtual} ${p.unidade}' : '✓ ${p.quantidadeAtual} ${p.unidade}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: isBaixo ? Colors.amber.shade900 : Colors.green.shade800,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${p.categoria} • Custo: ${currency.format(p.precoCusto)}${p.precoVenda > 0 ? " • Venda: ${currency.format(p.precoVenda)}" : ""}',
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      const Divider(height: 18),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit, size: 20, color: Colors.blue),
                                tooltip: 'Editar',
                                onPressed: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => NovoProdutoView(produtoParaEditar: p)),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, size: 20, color: Colors.red),
                                tooltip: 'Excluir',
                                onPressed: () => _confirmarExclusao(context, p),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6)),
                                icon: const Icon(Icons.remove, size: 16, color: Colors.orange),
                                label: const Text('Usar/Vender', style: TextStyle(fontSize: 12, color: Colors.orange)),
                                onPressed: () => _abrirModalMovimentar(context, p, false),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.verdeEntrada,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                ),
                                icon: const Icon(Icons.add, size: 16),
                                label: const Text('Comprar', style: TextStyle(fontSize: 12)),
                                onPressed: () => _abrirModalMovimentar(context, p, true),
                              ),
                            ],
                          )
                        ],
                      )
                    ],
                  ),
                ),
              );
            }),
          const SizedBox(height: 40),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NovoProdutoView())),
      ),
    );
  }
}
