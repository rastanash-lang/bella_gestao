import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/financeiro_controller.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/transacao_model.dart';

class NovoLancamentoView extends StatefulWidget {
  const NovoLancamentoView({super.key});

  @override
  State<NovoLancamentoView> createState() => _NovoLancamentoViewState();
}

class _NovoLancamentoViewState extends State<NovoLancamentoView> {
  final _formKey = GlobalKey<FormState>();
  final _descricaoCtrl = TextEditingController();
  final _valorCtrl = TextEditingController();

  String _tipo = 'entrada';
  String _ambito = 'PJ';
  String _formaPagamento = 'Pix';
  String _status = 'Pago';
  String _tipoCusto = 'Variável';
  String _tipoReceita = 'Serviço';
  String _categoria = 'Cabelo/Estética';

  final List<String> _categoriasEntrada = ['Cabelo/Estética', 'Manicure/Pedicure', 'Venda Produtos', 'Outros'];
  final List<String> _categoriasSaida = ['Produtos/Cosméticos', 'Aluguel/Contas', 'Equipamentos', 'Alimentação', 'Impostos/Taxas'];

  @override
  void initState() {
    super.initState();
    _ambito = context.read<FinanceiroController>().ambitoAtual;
  }

  @override
  void dispose() {
    _descricaoCtrl.dispose();
    _valorCtrl.dispose();
    super.dispose();
  }

  void _salvar() {
    if (_formKey.currentState!.validate()) {
      final valor = double.tryParse(_valorCtrl.text.replaceAll(',', '.')) ?? 0.0;

      final novaTransacao = Transacao(
        descricao: _descricaoCtrl.text.trim(),
        valor: valor,
        tipo: _tipo,
        ambito: _ambito,
        categoria: _categoria,
        formaPagamento: _formaPagamento,
        status: _status,
        tipoCusto: _tipo == 'saida' ? _tipoCusto : null,
        tipoReceita: _tipo == 'entrada' && _ambito == 'PJ' ? _tipoReceita : null,
        data: DateTime.now(),
      );

      context.read<FinanceiroController>().adicionarTransacao(novaTransacao);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Novo Lançamento (< 3s)')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'entrada', label: Text('Entrada (+)', style: TextStyle(fontWeight: FontWeight.bold))),
                ButtonSegment(value: 'saida', label: Text('Saída (-)', style: TextStyle(fontWeight: FontWeight.bold))),
              ],
              selected: {_tipo},
              onSelectionChanged: (set) {
                setState(() {
                  _tipo = set.first;
                  _categoria = _tipo == 'entrada' ? _categoriasEntrada.first : _categoriasSaida.first;
                });
              },
              style: SegmentedButton.styleFrom(
                selectedBackgroundColor: _tipo == 'entrada' ? AppTheme.verdeEntrada : AppTheme.carmimSaida,
                selectedForegroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _valorCtrl,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                prefixText: 'R\$ ',
                labelText: 'Valor',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              validator: (v) => (v == null || v.isEmpty) ? 'Informe o valor' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _descricaoCtrl,
              decoration: InputDecoration(
                labelText: 'Descrição (Ex: Corte + Escova)',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              validator: (v) => (v == null || v.isEmpty) ? 'Informe a descrição' : null,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Text('Conta:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(width: 12),
                ChoiceChip(
                  label: const Text('PJ (Salão)'),
                  selected: _ambito == 'PJ',
                  onSelected: (val) => setState(() => _ambito = 'PJ'),
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('PF (Pessoal)'),
                  selected: _ambito == 'PF',
                  onSelected: (val) => setState(() => _ambito = 'PF'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_tipo == 'entrada' && _ambito == 'PJ') ...[
              const Text('Tipo de Receita MEI:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'Serviço', label: Text('Serviço')),
                  ButtonSegment(value: 'Produto', label: Text('Venda Produto')),
                ],
                selected: {_tipoReceita},
                onSelectionChanged: (set) => setState(() => _tipoReceita = set.first),
              ),
              const SizedBox(height: 12),
            ],
            if (_tipo == 'saida') ...[
              const Text('Tipo de Custo:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'Fixo', label: Text('Fixo')),
                  ButtonSegment(value: 'Variável', label: Text('Variável')),
                  ButtonSegment(value: 'Emergência', label: Text('Emergência')),
                ],
                selected: {_tipoCusto},
                onSelectionChanged: (set) => setState(() => _tipoCusto = set.first),
              ),
              const SizedBox(height: 12),
            ],
            DropdownButtonFormField<String>(
              value: _formaPagamento,
              decoration: InputDecoration(
                labelText: 'Forma de Pagamento',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              items: ['Pix', 'Dinheiro', 'Débito', 'Crédito']
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (v) => setState(() => _formaPagamento = v!),
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              title: Text(_status == 'Pago' ? 'Concluído (Pago)' : 'Pendente (A receber/pagar)'),
              value: _status == 'Pago',
              onChanged: (val) => setState(() => _status = val ? 'Pago' : 'Pendente'),
              activeColor: AppTheme.verdeEntrada,
              tileColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _tipo == 'entrada' ? AppTheme.verdeEntrada : AppTheme.carmimSaida,
                foregroundColor: Colors.white,
              ),
              onPressed: _salvar,
              child: const Text('SALVAR LANÇAMENTO', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}
