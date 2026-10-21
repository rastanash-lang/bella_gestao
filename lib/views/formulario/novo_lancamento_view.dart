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

  late bool _isHistorico;
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

  final List<String> _categoriasEntradaPF = [
    'Montante / Saldo Inicial Pessoal',
    'Salário / Pró-labore',
    'Renda Extra Pessoal',
    'Outras Entradas Pessoais'
  ];

  final List<String> _categoriasSaidaPF = [
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

    _isHistorico = t?.categoria == 'Saldo Histórico / Início de Uso';
    _tipo = t?.tipo ?? 'entrada';
    _ambito = t?.ambito ?? context.read<FinanceiroController>().ambitoAtual;
    _formaPagamento = t?.formaPagamento ?? 'Dinheiro';
    _status = t?.status ?? 'Pago';
    _tipoCusto = t?.tipoCusto ?? 'Fixo';
    _tipoReceita = t?.tipoReceita ?? 'Serviço';
    _totalParcelas = t?.totalParcelas ?? 1;
    _dataHora = t?.data ?? DateTime.now();

    _atualizarCategoriaPadrao();
  }

  void _atualizarCategoriaPadrao() {
    if (_isHistorico) {
      _categoria = 'Saldo Histórico / Início de Uso';
      if (_descricaoCtrl.text.isEmpty) {
        _descricaoCtrl.text = 'Saldo Histórico Anterior (${_tipo == 'entrada' ? 'Receita' : 'Despesa'} $_ambito)';
      }
    } else if (_ambito == 'PF') {
      _categoria = _tipo == 'entrada' ? _categoriasEntradaPF.first : _categoriasSaidaPF.first;
    } else {
      _categoria = _tipo == 'entrada' ? _categoriasEntradaPJ.first : _categoriasSaidaPJ.first;
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
    final agora = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dataHora.isAfter(agora) ? agora : _dataHora,
      firstDate: DateTime(agora.year - 2, 1, 1), // Permite selecionar até 24 meses atrás
      lastDate: agora,
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

  void _aplicarDataRapida(DateTime data) {
    setState(() {
      _dataHora = DateTime(data.year, data.month, data.day, 12, 0);
    });
  }

  void _salvar() {
    if (_formKey.currentState!.validate()) {
      final valorTotal = double.tryParse(_valorCtrl.text.replaceAll(',', '.')) ?? 0.0;
      final controller = context.read<FinanceiroController>();
      final currency = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
      final isPF = _ambito == 'PF';

      // Validação de caixa apenas para saídas normais de PF do dia a dia (histórico nunca bloqueia)
      if (isPF && _tipo == 'saida' && !_isHistorico) {
        final saldoDisponivel = controller.saldoDisponivelCaixaPJ;
        final valorAnterior = (widget.transacaoParaEditar != null &&
                widget.transacaoParaEditar!.ambito == 'PF' &&
                widget.transacaoParaEditar!.tipo == 'saida')
            ? widget.transacaoParaEditar!.valor
            : 0.0;
        final saldoMaximoPermitido = saldoDisponivel + valorAnterior;

        if (valorTotal > saldoMaximoPermitido) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ Saldo insuficiente no salão! Você só tem ${currency.format(saldoMaximoPermitido)} disponível para retirar.'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 4),
            ),
          );
          return;
        }
      }

      String descFinal = _descricaoCtrl.text.trim();
      if (descFinal.isEmpty) {
        if (_isHistorico) {
          descFinal = 'Saldo Histórico (${_tipo == 'entrada' ? 'Receita' : 'Despesa'} $_ambito)';
        } else if (isPF) {
          descFinal = _tipo == 'entrada' ? 'Entrada Pessoal' : 'Gasto Pessoal';
        } else {
          descFinal = _tipo == 'entrada' ? 'Receita do Salão' : 'Despesa do Salão';
        }
      }

      final transacao = Transacao(
        id: widget.transacaoParaEditar?.id,
        descricao: descFinal,
        cliente: (!_isHistorico && _ambito == 'PJ' && _clienteCtrl.text.trim().isNotEmpty) ? _clienteCtrl.text.trim() : null,
        valor: valorTotal,
        tipo: _tipo,
        ambito: _ambito,
        categoria: _isHistorico ? 'Saldo Histórico / Início de Uso' : _categoria,
        formaPagamento: _isHistorico ? 'Dinheiro' : _formaPagamento,
        status: _isHistorico ? 'Pago' : _status,
        tipoCusto: (_tipo == 'saida' && _ambito == 'PJ') ? _tipoCusto : null,
        tipoReceita: (_tipo == 'entrada' && _ambito == 'PJ') ? _tipoReceita : null,
        parcelaAtual: widget.transacaoParaEditar?.parcelaAtual ?? 1,
        totalParcelas: (!_isHistorico && _formaPagamento == 'Crédito') ? _totalParcelas : 1,
        data: _dataHora,
      );

      if (widget.transacaoParaEditar != null) {
        controller.atualizarTransacao(transacao);
      } else {
        controller.adicionarTransacaoParcelada(transacao, (!_isHistorico && _formaPagamento == 'Crédito') ? _totalParcelas : 1);
      }

      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isHistorico ? '✅ Saldo Histórico gravado com sucesso!' : '✅ Lançamento gravado com sucesso!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final editando = widget.transacaoParaEditar != null;
    final valorInformado = double.tryParse(_valorCtrl.text.replaceAll(',', '.')) ?? 0.0;
    final controller = context.watch<FinanceiroController>();
    final nomesSugeridos = controller.nomesClientesUnicos;
    final currency = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    final dateFormat = DateFormat('dd/MM/yyyy (EEEE)', 'pt_BR');
    final timeFormat = DateFormat('HH:mm');
    final isPF = _ambito == 'PF';
    final saldoDisponivel = controller.saldoDisponivelCaixaPJ;
    final agora = DateTime.now();

    List<String> listaCategorias;
    if (_isHistorico) {
      listaCategorias = ['Saldo Histórico / Início de Uso'];
    } else if (isPF) {
      listaCategorias = _tipo == 'entrada' ? _categoriasEntradaPF : _categoriasSaidaPF;
    } else {
      listaCategorias = _tipo == 'entrada' ? _categoriasEntradaPJ : _categoriasSaidaPJ;
    }

    if (!listaCategorias.contains(_categoria)) {
      _categoria = listaCategorias.first;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(editando
            ? 'Editar Lançamento'
            : (_isHistorico
                ? 'Lançamento de Saldo Histórico'
                : (isPF
                    ? (_tipo == 'entrada' ? 'Montante Pessoal (Entrada)' : 'Registrar Gasto Pessoal')
                    : 'Novo Lançamento'))),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // 🌟 CHAVE/SWITCH: LANÇAMENTO DE HISTÓRICO / SALDO ANTERIOR (BUG-01)
            Card(
              elevation: 0,
              color: _isHistorico ? Colors.amber.shade50 : Colors.grey.shade100,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: BorderSide(color: _isHistorico ? Colors.amber.shade400 : Colors.grey.shade300, width: 1.5),
              ),
              child: SwitchListTile(
                title: const Row(
                  children: [
                    Icon(Icons.history, color: Colors.amber, size: 22),
                    SizedBox(width: 8),
                    Text('Lançamento de Histórico / Saldo Anterior', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  ],
                ),
                subtitle: const Text(
                  'Ative para cadastrar receitas ou despesas passadas acumuladas (últimos 12 meses) sem cadastrar cliente a cliente.',
                  style: TextStyle(fontSize: 11, color: Colors.black54),
                ),
                value: _isHistorico,
                activeColor: Colors.amber.shade800,
                onChanged: (val) {
                  setState(() {
                    _isHistorico = val;
                    _atualizarCategoriaPadrao();
                  });
                },
              ),
            ),
            const SizedBox(height: 14),

            // SELETOR DA CONTA (PJ / PF)
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
                          _atualizarCategoriaPadrao();
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
                          _atualizarCategoriaPadrao();
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),

            // SELEÇÃO: ENTRADA (RECEITA) OU SAÍDA (DESPESA)
            SegmentedButton<String>(
              segments: [
                ButtonSegment(
                  value: 'entrada',
                  label: Text(
                    _isHistorico
                        ? 'Entrada (Receita Passada)'
                        : (isPF ? 'Entrada / Montante (+)' : 'Entrada (Receita)'),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                ButtonSegment(
                  value: 'saida',
                  label: Text(
                    _isHistorico
                        ? 'Saída (Despesa Passada)'
                        : (isPF ? 'Saída / Gasto (-)' : 'Saída (Despesa)'),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
              selected: {_tipo},
              onSelectionChanged: (set) {
                setState(() {
                  _tipo = set.first;
                  _atualizarCategoriaPadrao();
                });
              },
              style: SegmentedButton.styleFrom(
                selectedBackgroundColor: _tipo == 'entrada' ? AppTheme.verdeEntrada : AppTheme.carmimSaida,
                selectedForegroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 14),

            // SELETOR DE DATA RETROATIVA COM ATALHOS RÁPIDOS
            Card(
              elevation: 1,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.calendar_month, size: 18, color: Colors.blueGrey),
                        const SizedBox(width: 6),
                        Text(
                          _isHistorico ? 'Data do Lançamento Histórico:' : 'Data da Movimentação:',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
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
                    if (_isHistorico) ...[
                      const SizedBox(height: 10),
                      const Text('Atalhos rápidos para meses anteriores:', style: TextStyle(fontSize: 11, color: Colors.black54, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            ActionChip(
                              label: const Text('Início do Ano', style: TextStyle(fontSize: 11)),
                              onPressed: () => _aplicarDataRapida(DateTime(agora.year, 1, 1)),
                            ),
                            const SizedBox(width: 6),
                            ActionChip(
                              label: const Text('1 mês atrás', style: TextStyle(fontSize: 11)),
                              onPressed: () => _aplicarDataRapida(DateTime(agora.year, agora.month - 1, 15)),
                            ),
                            const SizedBox(width: 6),
                            ActionChip(
                              label: const Text('3 meses atrás', style: TextStyle(fontSize: 11)),
                              onPressed: () => _aplicarDataRapida(DateTime(agora.year, agora.month - 3, 15)),
                            ),
                            const SizedBox(width: 6),
                            ActionChip(
                              backgroundColor: Colors.amber.shade100,
                              label: const Text('5 meses atrás', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                              onPressed: () => _aplicarDataRapida(DateTime(agora.year, agora.month - 5, 15)),
                            ),
                            const SizedBox(width: 6),
                            ActionChip(
                              label: const Text('6 meses atrás', style: TextStyle(fontSize: 11)),
                              onPressed: () => _aplicarDataRapida(DateTime(agora.year, agora.month - 6, 15)),
                            ),
                            const SizedBox(width: 6),
                            ActionChip(
                              label: const Text('12 meses atrás', style: TextStyle(fontSize: 11)),
                              onPressed: () => _aplicarDataRapida(DateTime(agora.year - 1, agora.month, 15)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),

            // VALOR TOTAL ACUMULADO
            TextFormField(
              controller: _valorCtrl,
              autofocus: !editando,
              onChanged: (_) => setState(() {}),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                prefixText: 'R\$ ',
                labelText: _isHistorico ? 'Valor Total Acumulado' : (isPF ? 'Valor Pessoal' : 'Valor Total'),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Informe o valor';
                final val = double.tryParse(v.replaceAll(',', '.')) ?? 0.0;
                if (val <= 0) return 'Informe um valor maior que zero';

                if (!_isHistorico && isPF && _tipo == 'saida' && val > saldoDisponivel) {
                  return 'Valor excede o saldo em caixa (${currency.format(saldoDisponivel)})';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),

            // DESCRIÇÃO
            TextFormField(
              controller: _descricaoCtrl,
              decoration: InputDecoration(
                labelText: _isHistorico
                    ? 'Descrição do Histórico (Opcional)'
                    : (isPF ? 'Descrição (Ex: Mercado, Farmácia)' : 'Descrição do Lançamento'),
                prefixIcon: Icon(_isHistorico ? Icons.history : (isPF ? Icons.wallet : Icons.description_outlined)),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 12),

            // CLIENTE: OCULTO SE FOR HISTÓRICO OU PF
            if (!_isHistorico && !isPF && _tipo == 'entrada') ...[
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

            // CLASSIFICAÇÃO MEI (ESSENCIAL PARA RECEITAS PJ, ATUALIZA DASN-SIMEI)
            if (!isPF && _tipo == 'entrada') ...[
              Card(
                color: Colors.amber.shade50,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Classificação para o MEI (DASN-SIMEI):', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      const SizedBox(height: 4),
                      const Text('Indica se este montante histórico foi proveniente de serviços ou produtos.', style: TextStyle(fontSize: 11, color: Colors.black54)),
                      const SizedBox(height: 8),
                      SegmentedButton<String>(
                        segments: const [
                          ButtonSegment(value: 'Serviço', label: Text('Prestação de Serviços')),
                          ButtonSegment(value: 'Produto', label: Text('Venda de Produtos')),
                        ],
                        selected: {_tipoReceita},
                        onSelectionChanged: (set) => setState(() => _tipoReceita = set.first),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],

            // CATEGORIA
            if (_isHistorico) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(12)),
                child: const Row(
                  children: [
                    Icon(Icons.label_outline, color: Colors.blueGrey),
                    SizedBox(width: 8),
                    Text('Categoria: Saldo Histórico / Início de Uso', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ] else ...[
              DropdownButtonFormField<String>(
                value: _categoria,
                decoration: InputDecoration(
                  labelText: isPF ? 'Categoria Pessoal' : 'Categoria',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                items: listaCategorias
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (v) => setState(() => _categoria = v!),
              ),
              const SizedBox(height: 12),
            ],

            // FORMA DE PAGAMENTO E PARCELAMENTO (APENAS LANÇAMENTOS DO DIA A DIA)
            if (!_isHistorico) ...[
              DropdownButtonFormField<String>(
                value: _formaPagamento,
                decoration: InputDecoration(
                  labelText: 'Forma de Pagamento',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                items: ['Dinheiro', 'Pix', 'Débito', 'Crédito', 'Outros']
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
                title: Text(_status == 'Pago' ? 'Concluído (Pago)' : 'Pendente (A pagar/receber)'),
                value: _status == 'Pago',
                onChanged: (val) => setState(() => _status = val ? 'Pago' : 'Pendente'),
                activeColor: AppTheme.verdeEntrada,
                tileColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ],
            const SizedBox(height: 24),

            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _isHistorico
                    ? Colors.amber.shade800
                    : (isPF ? Colors.purple.shade700 : (_tipo == 'entrada' ? AppTheme.verdeEntrada : AppTheme.carmimSaida)),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: _salvar,
              child: Text(
                editando
                    ? 'SALVAR ALTERAÇÕES'
                    : (_isHistorico
                        ? 'GRAVAR SALDO HISTÓRICO'
                        : (isPF
                            ? (_tipo == 'entrada' ? 'CONFIRMAR MONTANTE PESSOAL' : 'CONFIRMAR GASTO PESSOAL')
                            : 'CONFIRMAR LANÇAMENTO')),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
