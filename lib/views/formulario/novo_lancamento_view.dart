import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../controllers/financeiro_controller.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/transacao_model.dart';

class NovoLancamentoView extends StatefulWidget {
  final Transacao? transacaoParaEditar;

  const NovoLancamentoView({super.key, this.transacaoParaEditar});

  @override
  State<NovoLancamentoView> createState() => _NovoLancamentoViewState();
}

class _NovoLancamentoViewState extends State<NovoLancamentoView> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _descricaoCtrl;
  late TextEditingController _clienteCtrl;
  late TextEditingController _valorCtrl;

  late String _tipo;
  late String _ambito;
  late String _formaPagamento;
  late String _status;
  late String _tipoCusto;
  late String _tipoReceita;
  late String _categoria;
  late DateTime _dataHora;
  int _totalParcelas = 1;

  final List<String> _categoriasEntrada = [
    'Cabelo/Corte/Química',
    'Manicure/Pedicure',
    'Estética/Sobrancelhas',
    'Venda de Produtos',
    'Outros'
  ];
  final List<String> _categoriasSaida = [
    'Produtos/Cosméticos',
    'Aluguel/Contas',
    'Equipamentos',
    'Alimentação',
    'Impostos/Taxas',
    'Outros'
  ];

  @override
  void initState() {
    super.initState();
    final t = widget.transacaoParaEditar;
    _descricaoCtrl = TextEditingController(text: t?.descricao ?? '');
    _clienteCtrl = TextEditingController(text: t?.cliente ?? '');
    _valorCtrl = TextEditingController(text: t != null ? t.valor.toStringAsFixed(2) : '');

    _tipo = t?.tipo ?? 'entrada';
    _ambito = t?.ambito ?? context.read<FinanceiroController>().ambitoAtual;
    _formaPagamento = t?.formaPagamento ?? 'Pix';
    _status = t?.status ?? 'Pago';
    _tipoCusto = t?.tipoCusto ?? 'Variável';
    _tipoReceita = t?.tipoReceita ?? 'Serviço';
    _categoria = t?.categoria ?? (_tipo == 'entrada' ? _categoriasEntrada.first : _categoriasSaida.first);
    _totalParcelas = t?.totalParcelas ?? 1;
    _dataHora = t?.data ?? DateTime.now();
  }

  @override
  void dispose() {
    _descricaoCtrl.dispose();
    _clienteCtrl.dispose();
    _valorCtrl.dispose();
    super.dispose();
  }

  Future<void> _selecionarData() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dataHora,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (picked != null) {
      setState(() {
        _dataHora = DateTime(picked.year, picked.month, picked.day, _dataHora.hour, _dataHora.minute);
      });
    }
  }

  Future<void> _selecionarHora() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_dataHora),
    );
    if (picked != null) {
      setState(() {
        _dataHora = DateTime(_dataHora.year, _dataHora.month, _dataHora.day, picked.hour, picked.minute);
      });
    }
  }

  void _salvar() {
    if (_formKey.currentState!.validate()) {
      final valorTotal = double.tryParse(_valorCtrl.text.replaceAll(',', '.')) ?? 0.0;
      final controller = context.read<FinanceiroController>();

      final transacao = Transacao(
        id: widget.transacaoParaEditar?.id,
        descricao: _descricaoCtrl.text.trim(),
        cliente: _clienteCtrl.text.trim().isNotEmpty ? _clienteCtrl.text.trim() : null,
        valor: valorTotal,
        tipo: _tipo,
        ambito: _ambito,
        categoria: _categoria,
        formaPagamento: _formaPagamento,
        status: _status,
        tipoCusto: _tipo == 'saida' ? _tipoCusto : null,
        tipoReceita: _tipo == 'entrada' && _ambito == 'PJ' ? _tipoReceita : null,
        parcelaAtual: widget.transacaoParaEditar?.parcelaAtual ?? 1,
        totalParcelas: _formaPagamento == 'Crédito' ? _totalParcelas : 1,
        data: _dataHora,
      );

      if (widget.transacaoParaEditar != null) {
        controller.atualizarTransacao(transacao);
      } else {
        controller.adicionarTransacaoParcelada(transacao, _formaPagamento == 'Crédito' ? _totalParcelas : 1);
      }

      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final editando = widget.transacaoParaEditar != null;
    final valorInformado = double.tryParse(_valorCtrl.text.replaceAll(',', '.')) ?? 0.0;
    final nomesSugeridos = context.read<FinanceiroController>().nomesClientesUnicos;
    final dateFormat = DateFormat('dd/MM/yyyy (EEEE)', 'pt_BR');
    final timeFormat = DateFormat('HH:mm');
    final hoje = DateTime.now();

    return Scaffold(
      appBar: AppBar(title: Text(editando ? 'Editar Lançamento' : 'Novo Lançamento')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Tipo: Entrada ou Saída
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

            // SELETOR DE DATA DO LANÇAMENTO (Para lançar coisas do papel/caderno de meses passados)
            Card(
              elevation: 1,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.event, size: 18, color: Colors.blueGrey),
                        SizedBox(width: 6),
                        Text('Data do Lançamento:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            icon: const Icon(Icons.calendar_today, size: 16),
                            label: Text(dateFormat.format(_dataHora), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                            onPressed: _selecionarData,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          flex: 1,
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            icon: const Icon(Icons.access_time, size: 16),
                            label: Text(timeFormat.format(_dataHora), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                            onPressed: _selecionarHora,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Atalhos rápidos
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          ActionChip(
                            label: const Text('Hoje', style: TextStyle(fontSize: 11)),
                            onPressed: () => setState(() => _dataHora = DateTime.now()),
                          ),
                          const SizedBox(width: 6),
                          ActionChip(
                            label: const Text('Ontem', style: TextStyle(fontSize: 11)),
                            onPressed: () => setState(() => _dataHora = hoje.subtract(const Duration(days: 1))),
                          ),
                          const SizedBox(width: 6),
                          ActionChip(
                            avatar: const Icon(Icons.calendar_month, size: 14),
                            label: const Text('Outro Mês (Jan, Fev...)', style: TextStyle(fontSize: 11)),
                            onPressed: _selecionarData,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Campo de Valor
            TextFormField(
              controller: _valorCtrl,
              autofocus: !editando,
              onChanged: (_) => setState(() {}),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                prefixText: 'R\$ ',
                labelText: 'Valor Total',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              validator: (v) => (v == null || v.isEmpty) ? 'Informe o valor' : null,
            ),
            const SizedBox(height: 12),

            // Autocomplete Cliente (Entradas)
            if (_tipo == 'entrada') ...[
              Autocomplete<String>(
                initialValue: TextEditingValue(text: _clienteCtrl.text),
                optionsBuilder: (TextEditingValue textVal) {
                  if (textVal.text.isEmpty) return const Iterable<String>.empty();
                  return nomesSugeridos.where((nome) => nome.toLowerCase().contains(textVal.text.toLowerCase()));
                },
                onSelected: (String selecao) => _clienteCtrl.text = selecao,
                fieldViewBuilder: (ctx, textEditingCtrl, focusNode, onFieldSubmitted) {
                  _clienteCtrl = textEditingCtrl;
                  return TextFormField(
                    controller: textEditingCtrl,
                    focusNode: focusNode,
                    decoration: InputDecoration(
                      labelText: 'Nome da Cliente (Opcional)',
                      prefixIcon: const Icon(Icons.person_outline),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
            ],

            TextFormField(
              controller: _descricaoCtrl,
              decoration: InputDecoration(
                labelText: 'Descrição (Ex: Mechas, Corte, Esmaltação)',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              validator: (v) => (v == null || v.isEmpty) ? 'Informe a descrição' : null,
            ),
            const SizedBox(height: 16),

            // Toggle PJ / PF
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
              const Text('Classificação MEI:', style: TextStyle(fontWeight: FontWeight.bold)),
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

            if (_formaPagamento == 'Crédito' && !editando) ...[
              Card(
                color: Colors.blue.shade50,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Opções de Parcelamento:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<int>(
                        value: _totalParcelas,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        items: List.generate(12, (index) => index + 1).map((n) {
                          final valorParcela = valorInformado > 0 ? (valorInformado / n).toStringAsFixed(2) : '0,00';
                          return DropdownMenuItem<int>(
                            value: n,
                            child: Text('$n x de R\$ $valorParcela ${n == 1 ? '(À vista)' : ''}'),
                          );
                        }).toList(),
                        onChanged: (v) => setState(() => _totalParcelas = v ?? 1),
                      ),
                      if (_totalParcelas > 1)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            '💡 Serão gerados $_totalParcelas lançamentos mensais automáticos no caixa.',
                            style: TextStyle(fontSize: 11, color: Colors.blue.shade900),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],

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
              child: Text(editando ? 'SALVAR ALTERAÇÕES' : 'CONFIRMAR LANÇAMENTO', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}
