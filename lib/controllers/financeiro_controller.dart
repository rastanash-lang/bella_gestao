import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../data/models/transacao_model.dart';
import '../data/repositories/transacao_repository.dart';

class FinanceiroController extends ChangeNotifier {
  final TransacaoRepository _repository = TransacaoRepository();

  List<Transacao> _todasTransacoes = [];
  String _ambitoAtual = 'PJ'; // 'PJ' ou 'PF'
  String _filtroStatus = 'Todos'; // 'Todos', 'Pago', 'Pendente'
  String _termoBusca = '';
  bool _carregando = false;

  // Filtro por Mês
  DateTime _mesSelecionado = DateTime(DateTime.now().year, DateTime.now().month);
  bool _filtrarPorMes = true;

  // Taxas de Cartão Customizáveis (em %)
  double _taxaDebito = 1.99;
  double _taxaCredito = 3.99;

  static const double limiteAnualMEI = 81000.00;

  // Getters
  String get ambitoAtual => _ambitoAtual;
  String get filtroStatus => _filtroStatus;
  String get termoBusca => _termoBusca;
  bool get carregando => _carregando;
  DateTime get mesSelecionado => _mesSelecionado;
  bool get filtrarPorMes => _filtrarPorMes;
  double get taxaDebito => _taxaDebito;
  double get taxaCredito => _taxaCredito;

  // Lista Filtrada por Âmbito, Mês, Status e Busca
  List<Transacao> get transacoesFiltradas {
    return _todasTransacoes.where((t) {
      final matchAmbito = t.ambito == _ambitoAtual;
      final matchStatus = _filtroStatus == 'Todos' || t.status == _filtroStatus;
      final matchBusca = _termoBusca.isEmpty ||
          t.descricao.toLowerCase().contains(_termoBusca.toLowerCase()) ||
          t.categoria.toLowerCase().contains(_termoBusca.toLowerCase());

      final matchMes = !_filtrarPorMes ||
          (t.data.year == _mesSelecionado.year && t.data.month == _mesSelecionado.month);

      return matchAmbito && matchStatus && matchBusca && matchMes;
    }).toList();
  }

  // Totais do Período
  double get totalEntradas => transacoesFiltradas
      .where((t) => t.tipo == 'entrada' && t.status == 'Pago')
      .fold(0.0, (acc, t) => acc + t.valor);

  double get totalSaidas => transacoesFiltradas
      .where((t) => t.tipo == 'saida' && t.status == 'Pago')
      .fold(0.0, (acc, t) => acc + t.valor);

  double get saldoAtual => totalEntradas - totalSaidas;

  // RF-03: Distribuição de Custos
  double get totalCustosFixos => transacoesFiltradas
      .where((t) => t.tipo == 'saida' && t.tipoCusto == 'Fixo' && t.status == 'Pago')
      .fold(0.0, (acc, t) => acc + t.valor);

  double get totalCustosVariaveis => transacoesFiltradas
      .where((t) => t.tipo == 'saida' && t.tipoCusto == 'Variável' && t.status == 'Pago')
      .fold(0.0, (acc, t) => acc + t.valor);

  double get totalCustosEmergencia => transacoesFiltradas
      .where((t) => t.tipo == 'saida' && t.tipoCusto == 'Emergência' && t.status == 'Pago')
      .fold(0.0, (acc, t) => acc + t.valor);

  // RF-05: Taxas com alíquotas personalizadas
  double get totalRecebidoDebito => transacoesFiltradas
      .where((t) => t.tipo == 'entrada' && t.formaPagamento == 'Débito' && t.status == 'Pago')
      .fold(0.0, (acc, t) => acc + t.valor);

  double get totalRecebidoCredito => transacoesFiltradas
      .where((t) => t.tipo == 'entrada' && t.formaPagamento == 'Crédito' && t.status == 'Pago')
      .fold(0.0, (acc, t) => acc + t.valor);

  double get estimativaTaxasCartao =>
      (totalRecebidoDebito * (_taxaDebito / 100)) + (totalRecebidoCredito * (_taxaCredito / 100));

  // RF-04: Módulo MEI (Ano Vigente Completo)
  double get faturamentoAnualMEI {
    final anoAtual = DateTime.now().year;
    return _todasTransacoes
        .where((t) =>
            t.ambito == 'PJ' &&
            t.tipo == 'entrada' &&
            t.status == 'Pago' &&
            t.data.year == anoAtual)
        .fold(0.0, (acc, t) => acc + t.valor);
  }

  double get faturamentoServicosMEI {
    final anoAtual = DateTime.now().year;
    return _todasTransacoes
        .where((t) =>
            t.ambito == 'PJ' &&
            t.tipo == 'entrada' &&
            t.tipoReceita == 'Serviço' &&
            t.status == 'Pago' &&
            t.data.year == anoAtual)
        .fold(0.0, (acc, t) => acc + t.valor);
  }

  double get faturamentoProdutosMEI {
    final anoAtual = DateTime.now().year;
    return _todasTransacoes
        .where((t) =>
            t.ambito == 'PJ' &&
            t.tipo == 'entrada' &&
            t.tipoReceita == 'Produto' &&
            t.status == 'Pago' &&
            t.data.year == anoAtual)
        .fold(0.0, (acc, t) => acc + t.valor);
  }

  double get percentualMEI => (faturamentoAnualMEI / limiteAnualMEI).clamp(0.0, 1.0);

  // Navegação de Mês
  void mesAnterior() {
    _mesSelecionado = DateTime(_mesSelecionado.year, _mesSelecionado.month - 1);
    notifyListeners();
  }

  void proximoMes() {
    _mesSelecionado = DateTime(_mesSelecionado.year, _mesSelecionado.month + 1);
    notifyListeners();
  }

  void toggleFiltroMes() {
    _filtrarPorMes = !_filtrarPorMes;
    notifyListeners();
  }

  void atualizarTaxas(double debito, double credito) {
    _taxaDebito = debito;
    _taxaCredito = credito;
    notifyListeners();
  }

  // Operações de Banco
  Future<void> carregarTransacoes() async {
    _carregando = true;
    notifyListeners();
    _todasTransacoes = await _repository.listarTodas();
    _carregando = false;
    notifyListeners();
  }

  void alternarAmbito(String novoAmbito) {
    _ambitoAtual = novoAmbito;
    notifyListeners();
  }

  void filtrarStatus(String status) {
    _filtroStatus = status;
    notifyListeners();
  }

  void buscar(String query) {
    _termoBusca = query;
    notifyListeners();
  }

  Future<void> adicionarTransacao(Transacao transacao) async {
    await _repository.inserir(transacao);
    await carregarTransacoes();
  }

  Future<void> atualizarTransacao(Transacao transacao) async {
    await _repository.atualizar(transacao);
    await carregarTransacoes();
  }

  Future<void> alternarStatus(Transacao t) async {
    final novoStatus = t.status == 'Pago' ? 'Pendente' : 'Pago';
    await _repository.alternarStatusPago(t.id!, novoStatus);
    await carregarTransacoes();
  }

  Future<void> removerTransacao(int id) async {
    await _repository.deletar(id);
    await carregarTransacoes();
  }

  // CSV
  Future<void> exportarRelatorioCSV() async {
    final buffer = StringBuffer();
    buffer.writeln('ID,Data,Descricao,Valor,Tipo,Ambito,Categoria,FormaPagamento,Status,TipoCusto,TipoReceita');
    for (final t in _todasTransacoes) {
      buffer.writeln('${t.id},"${t.data.toIso8601String()}","${t.descricao}",${t.valor},${t.tipo},${t.ambito},"${t.categoria}",${t.formaPagamento},${t.status},"${t.tipoCusto ?? ''}","${t.tipoReceita ?? ''}"');
    }

    final directory = await getTemporaryDirectory();
    final file = File('${directory.path}/relatorio_financeiro_${DateFormat('yyyyMMdd').format(DateTime.now())}.csv');
    await file.writeAsString(buffer.toString());
    await Share.shareXFiles([XFile(file.path)], text: 'Relatório Financeiro CSV');
  }

  // Exportar Backup JSON
  Future<void> exportarBackupJSON() async {
    final listaMap = _todasTransacoes.map((e) => e.toMap()).toList();
    final jsonString = jsonEncode(listaMap);
    final directory = await getTemporaryDirectory();
    final file = File('${directory.path}/backup_bella_gestao_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}.json');
    await file.writeAsString(jsonString);
    await Share.shareXFiles([XFile(file.path)], text: 'Backup Bella Gestão');
  }

  // Restaurar Backup a partir de JSON
  Future<bool> restaurarBackupJSON(String conteudoJson) async {
    try {
      final List<dynamic> decoded = jsonDecode(conteudoJson);
      for (final item in decoded) {
        final map = Map<String, dynamic>.from(item);
        map.remove('id'); // deixa o banco gerar novo id para evitar conflitos
        await _repository.inserir(Transacao.fromMap(map));
      }
      await carregarTransacoes();
      return true;
    } catch (_) {
      return false;
    }
  }
}
