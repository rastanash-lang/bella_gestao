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

  static const double limiteAnualMEI = 81000.00;

  // Getters
  String get ambitoAtual => _ambitoAtual;
  String get filtroStatus => _filtroStatus;
  String get termoBusca => _termoBusca;
  bool get carregando => _carregando;

  // Lista Filtrada com Busca e Status
  List<Transacao> get transacoesFiltradas {
    return _todasTransacoes.where((t) {
      final matchAmbito = t.ambito == _ambitoAtual;
      final matchStatus = _filtroStatus == 'Todos' || t.status == _filtroStatus;
      final matchBusca = _termoBusca.isEmpty ||
          t.descricao.toLowerCase().contains(_termoBusca.toLowerCase()) ||
          t.categoria.toLowerCase().contains(_termoBusca.toLowerCase());
      return matchAmbito && matchStatus && matchBusca;
    }).toList();
  }

  // Totais do Painel Atual
  double get totalEntradas => transacoesFiltradas
      .where((t) => t.tipo == 'entrada' && t.status == 'Pago')
      .fold(0.0, (acc, t) => acc + t.valor);

  double get totalSaidas => transacoesFiltradas
      .where((t) => t.tipo == 'saida' && t.status == 'Pago')
      .fold(0.0, (acc, t) => acc + t.valor);

  double get saldoAtual => totalEntradas - totalSaidas;

  // RF-03: Distribuição de Custos (Saídas Pagas)
  double get totalCustosFixos => transacoesFiltradas
      .where((t) => t.tipo == 'saida' && t.tipoCusto == 'Fixo' && t.status == 'Pago')
      .fold(0.0, (acc, t) => acc + t.valor);

  double get totalCustosVariaveis => transacoesFiltradas
      .where((t) => t.tipo == 'saida' && t.tipoCusto == 'Variável' && t.status == 'Pago')
      .fold(0.0, (acc, t) => acc + t.valor);

  double get totalCustosEmergencia => transacoesFiltradas
      .where((t) => t.tipo == 'saida' && t.tipoCusto == 'Emergência' && t.status == 'Pago')
      .fold(0.0, (acc, t) => acc + t.valor);

  // RF-05: Estimativa de Taxas de Cartão
  double get totalRecebidoDebito => transacoesFiltradas
      .where((t) => t.tipo == 'entrada' && t.formaPagamento == 'Débito' && t.status == 'Pago')
      .fold(0.0, (acc, t) => acc + t.valor);

  double get totalRecebidoCredito => transacoesFiltradas
      .where((t) => t.tipo == 'entrada' && t.formaPagamento == 'Crédito' && t.status == 'Pago')
      .fold(0.0, (acc, t) => acc + t.valor);

  double get estimativaTaxasCartao =>
      (totalRecebidoDebito * 0.0199) + (totalRecebidoCredito * 0.0399); // Exemplo: 1.99% débito, 3.99% crédito

  // RF-04: Módulo MEI (DASN-SIMEI)
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

  // Ações
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

  // RF-04: Exportar Planilha CSV
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

  // RF-06: Exportar Backup JSON
  Future<void> exportarBackupJSON() async {
    final listaMap = _todasTransacoes.map((e) => e.toMap()).toList();
    final jsonString = jsonEncode(listaMap);
    final directory = await getTemporaryDirectory();
    final file = File('${directory.path}/backup_completo_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}.json');
    await file.writeAsString(jsonString);
    await Share.shareXFiles([XFile(file.path)], text: 'Backup Completo Bella Gestão');
  }
}
