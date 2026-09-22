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

  final List<String> _categoriasEntradaPJ = [
    'Cabelo/Corte/Química',
    'Manicure/Pedicure',
    'Estética/Sobrancelhas',
    'Venda de Produtos',
    'Outros'
  ];

  final List<String> _categoriasSaidaPJ = [
    'Produtos/Cosméticos',
    'Aluguel/Contas do Salão',
    'Equipamentos',
    'Impostos/Taxas',
    'Outros'
  ];

  // CATEGORIAS EXCLUSIVAS PARA GASTOS PESSOAIS (PF)
  final List<String> _categoriasPF = [
    'Alimentação / Supermercado',
    'Contas de Casa / Moradia',
    'Farmácia / Saúde',
    'Roupas / Cuidados Pessoais',
    'Lazer / Passeios',
    'Transporte / Combustível',
    'Outros Gastos Pessoais'
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
    _totalParcelas = t?.totalParcelas ?? 1;
    _dataHora = t?.data ?? DateTime.now();

    if (_ambito == 'PF') {
      _categoria = t?.categoria ?? _categoriasPF.first;
    } else {
      _categoria = t?.categoria ?? (_tipo == 'entrada' ? _categoriasEntradaPJ.first : _categoriasSaidaPJ.first);
    }
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
        cliente: (_ambito == 'PJ' && _clienteCtrl.text.trim().isNotEmpty) ? _clienteCtrl.text.trim() : null,
        valor: valorTotal,
        tipo: _tipo,
        ambito: _ambito,
        categoria: _categoria,
        formaPagamento: _formaPagamento,
        status: _status,
        tipoCusto: (_tipo == 'saida' && _ambito == 'PJ') ? _tipoCusto : null,
        tipoReceita: (_tipo == 'entrada' && _ambito == 'PJ') ? _tipoReceita : null,
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
    final isPF = _ambito == 'PF';

    return Scaffold(
      appBar: AppBar(
        title: Text(editando ? 'Editar Lançamento' : (isPF ? 'Registrar Gasto Pessoal' : 'Novo Lançamento')),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ESCOLHA DA CONTA: SALÃO (PJ) OU PESSOAL (PF)
            Card(
              elevation: 0,
              color: isPF ? Colors.purple.shade50 : Colors.blue.shade50,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  children: [
                    const Text('Conta:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(width: 12),
                    ChoiceChip(
                      avatar: const Icon(Icons.business, size: 16),
                      label: const Text('🏢 Salão (PJ)'),
                      selected: _ambito == 'PJ',
                      onSelected: (val) {
                        setState(() {
                          _ambito = 'PJ';
                          _categoria = _tipo == 'entrada' ? _categoriasEntradaPJ.first : _categoriasSaidaPJ.first;
                        });
                      },
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      avatar: const Icon(Icons.home, size: 16),
                      label: const Text('🏠 Pessoal (PF)'),
                      selected: _ambito == 'PF',
                      onSelected: (val) {
                        setState(() {
                          _ambito = 'PF';
                          _tipo = 'saida'; // Gasto pessoal é saída por padrão
                          _categoria = _categoriasPF.first;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // SE FOR SALÃO (PJ), DEIXA ESCOLHER SE É ENTRADA OU SAÍDA
            if (!isPF) ...[
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'entrada', label: Text('Entrada (+)', style: TextStyle(fontWeight: FontWeight.bold))),
                  ButtonSegment(value: 'saida', label: Text('Saída (-)', style: TextStyle(fontWeight: FontWeight.bold))),
                ],
                selected: {_tipo},
                onSelectionChanged: (set) {
                  setState(() {
                    _tipo = set.first;
                    _categoria = _tipo == 'entrada' ? _categoriasEntradaPJ.first : _categoriasSaidaPJ.first;
                  });
                },
                style: SegmentedButton.styleFrom(
                  selectedBackgroundColor: _tipo == 'entrada' ? AppTheme.verdeEntrada : AppTheme.carmimSaida,
                  selectedForegroundColor: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
            ] else ...[
              // AVISO CLARO DE DEDUÇÃO DO SALÃO
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: Colors.purple.shade50, borderRadius: BorderRadius.circular(10)),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.purple, size: 18),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '💡 Este valor sairá da receita do salão para cobrir seus gastos pessoais.',
                        style: TextStyle(fontSize: 12, color: Colors.purple, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // DATA DO GASTO
            Card(
              elevation: 1,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.calendar_today, size: 16),
                        label: Text(dateFormat.format(_dataHora), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        onPressed: _selecionarData,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      flex: 1,
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.access_time, size: 16),
                        label: Text(timeFormat.format(_dataHora), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        onPressed: _selecionarHora,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // VALOR
            TextFormField(
              controller: _valorCtrl,
              autofocus: !editando,
              onChanged: (_) => setState(() {}),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                prefixText: 'R\$ ',
                labelText: isPF ? 'Valor do Gasto Pessoal' : 'Valor Total',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              validator: (v) => (v == null || v.isEmpty) ? 'Informe o valor' : null,
            ),
            const SizedBox(height: 12),

            // O QUE COMPROU (DESCRIÇÃO)
            TextFormField(
              controller: _descricaoCtrl,
              decoration: InputDecoration(
                labelText: isPF ? 'O que você comprou pra si? (Ex: Almoço, Remédio, Blusa)' : 'Descrição do Lançamento',
                prefixIcon: Icon(isPF ? Icons.shopping_bag_outlined : Icons.description_outlined),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              validator: (v) => (v == null || v.isEmpty) ? 'Informe o que comprou' : null,
            ),
            const SizedBox(height: 12),

            // CLIENTE: SÓ APARECE SE FOR ENTRADA DO SALÃO (PJ)! NUNCA NO PESSOAL (PF)
            if (!isPF && _tipo == 'entrada') ...[
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

            // CATEGORIA (DIFERENTE PARA PJ E PF)
            DropdownButtonFormField<String>(
              value: _categoria,
              decoration: InputDecoration(
                labelText: isPF ? 'Tipo de Gasto Pessoal' : 'Categoria',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              items: (isPF ? _categoriasPF : (_tipo == 'entrada' ? _categoriasEntradaPJ : _categoriasSaidaPJ))
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (v) => setState(() => _categoria = v!),
            ),
            const SizedBox(height: 12),

            // CLASSIFICAÇÃO MEI (SÓ SE FOR ENTRADA DO SALÃO PJ)
            if (!isPF && _tipo == 'entrada') ...[
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

            // TIPO DE CUSTO (SÓ SE FOR SAÍDA DO SALÃO PJ)
            if (!isPF && _tipo == 'saida') ...[
              const Text('Tipo de Custo do Salão:', style: TextStyle(fontWeight: FontWeight.bold)),
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

            // FORMA DE PAGAMENTO
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

            // PARCELAMENTO NO CRÉDITO
            if (_formaPagamento == 'Crédito' && !editando) ...[
              Card(
                color: Colors.blue.shade50,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Parcelamento:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
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
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],

            SwitchListTile(
              title: Text(_status == 'Pago' ? 'Concluído (Pago)' : 'Pendente (A pagar)'),
              value: _status == 'Pago',
              onChanged: (val) => setState(() => _status = val ? 'Pago' : 'Pendente'),
              activeColor: AppTheme.verdeEntrada,
              tileColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            const SizedBox(height: 24),

            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: isPF ? Colors.purple.shade700 : (_tipo == 'entrada' ? AppTheme.verdeEntrada : AppTheme.carmimSaida),
                foregroundColor: Colors.white,
              ),
              onPressed: _salvar,
              child: Text(editando ? 'SALVAR ALTERAÇÕES' : (isPF ? 'CONFIRMAR GASTO PESSOAL' : 'CONFIRMAR LANÇAMENTO'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}
