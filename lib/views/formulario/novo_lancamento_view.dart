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

  // Variável para controle de Saldo Histórico
  bool _isHistorico = false;

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

    // Detecta se é histórico pela categoria
    _isHistorico = t?.categoria == 'Saldo Histórico / Início de Uso';

    if (_ambito == 'PF') {
      _categoria = t?.categoria ?? _categoriasPF.first;
      _tipo = 'saida';
    } else {
      _categoria = t?.categoria ?? (_tipo == 'entrada' ? _categoriasEntradaPJ.first : _categoriasSaidaPJ.first);
    }

    if (_isHistorico) {
      _categoria = 'Saldo Histórico / Início de Uso';
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
    // Permite selecionar até 12 meses atrás para histórico
    final picked = await showDatePicker(
      context: context,
      initialDate: _dataHora,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _dataHora = DateTime(picked.year, picked.month, picked.day, _dataHora.hour, _dataHora.minute);
      });
    }
  }

  void _salvar() {
    if (_formKey.currentState!.validate()) {
      final valorTotal = double.tryParse(_valorCtrl.text.replaceAll(',', '.')) ?? 0.0;
      final controller = context.read<FinanceiroController>();
      final isPF = _ambito == 'PF';

      // Validação de saldo para gastos pessoais
      if (isPF && !_isHistorico) {
        final saldoDisponivel = controller.saldoDisponivelCaixaPJ;
        final valorAnterior = (widget.transacaoParaEditar != null && widget.transacaoParaEditar!.ambito == 'PF')
            ? widget.transacaoParaEditar!.valor
            : 0.0;
        final saldoMaximoPermitido = saldoDisponivel + valorAnterior;

        if (valorTotal > saldoMaximoPermitido) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('❌ Saldo insuficiente no caixa do salão!'), backgroundColor: Colors.red),
          );
          return;
        }
      }

      final transacao = Transacao(
        id: widget.transacaoParaEditar?.id,
        descricao: _isHistorico ? "Saldo Histórico" : _descricaoCtrl.text.trim(),
        cliente: (!_isHistorico && _ambito == 'PJ' && _clienteCtrl.text.trim().isNotEmpty) ? _clienteCtrl.text.trim() : null,
        valor: valorTotal,
        tipo: _tipo,
        ambito: _ambito,
        categoria: _isHistorico ? 'Saldo Histórico / Início de Uso' : _categoria,
        formaPagamento: _isHistorico ? 'Dinheiro' : _formaPagamento,
        status: 'Pago',
        tipoCusto: (!_isHistorico && _tipo == 'saida' && _ambito == 'PJ') ? _tipoCusto : null,
        tipoReceita: (_tipo == 'entrada' && _ambito == 'PJ') ? _tipoReceita : null,
        data: _dataHora,
      );

      if (widget.transacaoParaEditar != null) {
        controller.atualizarTransacao(transacao);
      } else {
        controller.adicionarTransacaoParcelada(transacao, _totalParcelas);
      }

      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isPF = _ambito == 'PF';
    final dateFormat = DateFormat('dd/MM/yyyy (EEEE)', 'pt_BR');

    return Scaffold(
      appBar: AppBar(
        title: Text(_isHistorico ? 'Lançar Saldo Histórico' : 'Novo Lançamento'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // SWITCH PARA SALDO HISTÓRICO
            SwitchListTile(
              title: const Text('Ajuste / Saldo Histórico Anterior', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('Use para faturamentos/despesas de meses passados.'),
              value: _isHistorico,
              onChanged: (val) {
                setState(() {
                  _isHistorico = val;
                  if (val) {
                    _status = 'Pago';
                    _formaPagamento = 'Dinheiro';
                    _descricaoCtrl.text = "Saldo Histórico";
                  }
                });
              },
              secondary: const Icon(Icons.history, color: Colors.blue),
            ),
            const Divider(),

            // SELETOR PJ / PF
            Card(
              elevation: 0,
              color: isPF ? Colors.purple.shade50 : Colors.blue.shade50,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  children: [
                    const Text('Conta:', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(width: 12),
                    ChoiceChip(
                      label: const Text('🏢 Salão (PJ)'),
                      selected: _ambito == 'PJ',
                      onSelected: (val) => setState(() {
                        _ambito = 'PJ';
                        if (!_isHistorico) _categoria = _tipo == 'entrada' ? _categoriasEntradaPJ.first : _categoriasSaidaPJ.first;
                      }),
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: const Text('🏠 Pessoal (PF)'),
                      selected: _ambito == 'PF',
                      onSelected: (val) => setState(() {
                        _ambito = 'PF';
                        _tipo = 'saida';
                        if (!_isHistorico) _categoria = _categoriasPF.first;
                      }),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // TIPO: ENTRADA OU SAÍDA
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'entrada', label: Text('Entrada (+)')),
                ButtonSegment(value: 'saida', label: Text('Saída (-)')),
              ],
              selected: {_tipo},
              onSelectionChanged: (set) => setState(() {
                _tipo = set.first;
                if (!_isHistorico) _categoria = _tipo == 'entrada' ? _categoriasEntradaPJ.first : _categoriasSaidaPJ.first;
              }),
              style: SegmentedButton.styleFrom(
                selectedBackgroundColor: _tipo == 'entrada' ? AppTheme.verdeEntrada : AppTheme.carmimSaida,
                selectedForegroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 16),

            // VALOR
            TextFormField(
              controller: _valorCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              decoration: const InputDecoration(
                prefixText: 'R\$ ',
                labelText: 'Valor Acumulado',
                border: OutlineInputBorder(),
              ),
              validator: (v) => (v == null || v.isEmpty) ? 'Informe o valor' : null,
            ),
            const SizedBox(height: 16),

            // DATA (Retroativa)
            ListTile(
              title: const Text('Data do Lançamento'),
              subtitle: Text(dateFormat.format(_dataHora)),
              leading: const Icon(Icons.calendar_month),
              trailing: const Icon(Icons.edit),
              tileColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              onTap: _selecionarData,
            ),
            const SizedBox(height: 16),

            // CAMPOS QUE SOMENTE APARECEM SE NÃO FOR HISTÓRICO
            if (!_isHistorico) ...[
              TextFormField(
                controller: _descricaoCtrl,
                decoration: const InputDecoration(labelText: 'Descrição', border: OutlineInputBorder()),
                validator: (v) => (v == null || v.isEmpty) ? 'Informe a descrição' : null,
              ),
              const SizedBox(height: 12),
              if (!isPF && _tipo == 'entrada') ...[
                Autocomplete<String>(
                  initialValue: TextEditingValue(text: _clienteCtrl.text),
                  optionsBuilder: (val) => context.read<FinanceiroController>().nomesClientesUnicos.where((n) => n.toLowerCase().contains(val.text.toLowerCase())),
                  onSelected: (s) => _clienteCtrl.text = s,
                  fieldViewBuilder: (ctx, ctrl, node, onSubmit) {
                    _clienteCtrl = ctrl;
                    return TextFormField(
                      controller: ctrl,
                      focusNode: node,
                      decoration: const InputDecoration(labelText: 'Nome da Cliente (Opcional)', border: OutlineInputBorder()),
                    );
                  },
                ),
                const SizedBox(height: 12),
              ],
              DropdownButtonFormField<String>(
                value: _categoria,
                decoration: const InputDecoration(labelText: 'Categoria', border: OutlineInputBorder()),
                items: (isPF ? _categoriasPF : (_tipo == 'entrada' ? _categoriasEntradaPJ : _categoriasSaidaPJ))
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (v) => setState(() => _categoria = v!),
              ),
              const SizedBox(height: 12),
            ],

            // CLASSIFICAÇÃO MEI (Sempre importante, mesmo para histórico)
            if (!isPF && _tipo == 'entrada') ...[
              const Text('Classificação para o MEI:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'Serviço', label: Text('Serviço')),
                  ButtonSegment(value: 'Produto', label: Text('Venda Produto')),
                ],
                selected: {_tipoReceita},
                onSelectionChanged: (set) => setState(() => _tipoReceita = set.first),
              ),
              const SizedBox(height: 16),
            ],

            // FORMA DE PAGAMENTO (Só se não for histórico)
            if (!_isHistorico)
              DropdownButtonFormField<String>(
                value: _formaPagamento,
                decoration: const InputDecoration(labelText: 'Forma de Pagamento', border: OutlineInputBorder()),
                items: ['Pix', 'Dinheiro', 'Débito', 'Crédito'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                onChanged: (v) => setState(() => _formaPagamento = v!),
              ),

            const SizedBox(height: 32),

            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _isHistorico ? Colors.blueGrey : (_tipo == 'entrada' ? AppTheme.verdeEntrada : AppTheme.carmimSaida),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              onPressed: _salvar,
              child: Text(_isHistorico ? 'REGISTRAR SALDO HISTÓRICO' : 'CONFIRMAR LANÇAMENTO', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}
