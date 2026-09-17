import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/financeiro_controller.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/produto_model.dart';

class NovoProdutoView extends StatefulWidget {
  final Produto? produtoParaEditar;

  const NovoProdutoView({super.key, this.produtoParaEditar});

  @override
  State<NovoProdutoView> createState() => _NovoProdutoViewState();
}

class _NovoProdutoViewState extends State<NovoProdutoView> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nomeCtrl;
  late TextEditingController _qtdAtualCtrl;
  late TextEditingController _qtdMinCtrl;
  late TextEditingController _custoCtrl;
  late TextEditingController _vendaCtrl;

  late String _categoria;
  late String _unidade;

  final List<String> _categorias = [
    'Coloração',
    'Tratamento/Shampoo',
    'Unhas/Esmaltes',
    'Estética/Pele',
    'Revenda Clientes',
    'Descartáveis/Luvas',
    'Outros'
  ];

  final List<String> _unidades = ['un', 'frasco', 'tubo', 'kit', 'ml', 'g'];

  @override
  void initState() {
    super.initState();
    final p = widget.produtoParaEditar;
    _nomeCtrl = TextEditingController(text: p?.nome ?? '');
    _qtdAtualCtrl = TextEditingController(text: p != null ? p.quantidadeAtual.toString() : '1');
    _qtdMinCtrl = TextEditingController(text: p != null ? p.quantidadeMinima.toString() : '2');
    _custoCtrl = TextEditingController(text: p != null ? p.precoCusto.toStringAsFixed(2) : '');
    _vendaCtrl = TextEditingController(text: p != null && p.precoVenda > 0 ? p.precoVenda.toStringAsFixed(2) : '');
    _categoria = p?.categoria ?? _categorias.first;
    _unidade = p?.unidade ?? _unidades.first;
  }

  @override
  void dispose() {
    _nomeCtrl.dispose();
    _qtdAtualCtrl.dispose();
    _qtdMinCtrl.dispose();
    _custoCtrl.dispose();
    _vendaCtrl.dispose();
    super.dispose();
  }

  void _salvar() {
    if (_formKey.currentState!.validate()) {
      final qtdAtual = int.tryParse(_qtdAtualCtrl.text) ?? 0;
      final qtdMin = int.tryParse(_qtdMinCtrl.text) ?? 2;
      final custo = double.tryParse(_custoCtrl.text.replaceAll(',', '.')) ?? 0.0;
      final venda = double.tryParse(_vendaCtrl.text.replaceAll(',', '.')) ?? 0.0;

      final produto = Produto(
        id: widget.produtoParaEditar?.id,
        nome: _nomeCtrl.text.trim(),
        categoria: _categoria,
        quantidadeAtual: qtdAtual,
        quantidadeMinima: qtdMin,
        precoCusto: custo,
        precoVenda: venda,
        unidade: _unidade,
      );

      final controller = context.read<FinanceiroController>();
      if (widget.produtoParaEditar != null) {
        controller.atualizarProduto(produto);
      } else {
        controller.criarProduto(produto);
      }

      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final editando = widget.produtoParaEditar != null;

    return Scaffold(
      appBar: AppBar(title: Text(editando ? 'Editar Produto' : 'Novo Produto')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nomeCtrl,
              decoration: InputDecoration(
                labelText: 'Nome do Produto (Ex: Tinta 7.1, Shampoo 1L)',
                prefixIcon: const Icon(Icons.inventory_2_outlined),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              validator: (v) => (v == null || v.isEmpty) ? 'Informe o nome do item' : null,
            ),
            const SizedBox(height: 12),

            DropdownButtonFormField<String>(
              value: _categoria,
              decoration: InputDecoration(
                labelText: 'Categoria',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              items: _categorias.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
              onChanged: (v) => setState(() => _categoria = v!),
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: _qtdAtualCtrl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Qtd Atual em Estoque',
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    validator: (v) => (v == null || v.isEmpty) ? 'Informe' : null,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 1,
                  child: DropdownButtonFormField<String>(
                    value: _unidade,
                    decoration: InputDecoration(
                      labelText: 'Unidade',
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    items: _unidades.map((u) => DropdownMenuItem(value: u, child: Text(u))).toList(),
                    onChanged: (v) => setState(() => _unidade = v!),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            TextFormField(
              controller: _qtdMinCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Avisar quando restar menos de:',
                helperText: 'Aviso visual de estoque acabando',
                prefixIcon: const Icon(Icons.warning_amber_rounded, color: Colors.orange),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _custoCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: 'Preço de Custo (R\$)',
                      prefixText: 'R\$ ',
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    validator: (v) => (v == null || v.isEmpty) ? 'Informe o custo' : null,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    controller: _vendaCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: 'Preço Venda (Opcional)',
                      prefixText: 'R\$ ',
                      helperText: 'Para revenda',
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary, foregroundColor: Colors.white),
              onPressed: _salvar,
              child: Text(editando ? 'SALVAR ALTERAÇÕES' : 'CADASTRAR NO ESTOQUE', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}
