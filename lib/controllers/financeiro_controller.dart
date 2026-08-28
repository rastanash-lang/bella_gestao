import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../data/models/transacao_model.dart';
import '../data/repositories/transacao_repository.dart';

class MesComparativo {
  final String label; // ex: AGO/26
  final String nomeMes; // ex: Agosto
  final double entradas;
  final double saidas;
  final double saldo;
  final int ano;
  final int mes;

  MesComparativo({
    required this.label,
    required this.nomeMes,
    required this.entradas,
    required this.saidas,
    required this.saldo,
    required this.ano,
    required this.mes,
  });
}

class FinanceiroController extends ChangeNotifier {
  final TransacaoRepository _repository = TransacaoRepository();

  List<Transacao> _todasTransacoes = [];
  String _ambitoAtual = 'PJ'; // 'PJ' ou 'PF'
  String _filtroTipo = 'Todos'; // 'Todos', 'Entradas', 'Saídas'
  String _termoBusca = '';
  bool _carregando = false;
  bool _ocultarSaldo = false;

  DateTime _mesSelecionado = DateTime(DateTime.now().year, DateTime.now().month);
  bool _filtrarPorMes = true;

  double _taxaDebito = 1.99;
  double _taxaCredito = 3.99;

  static const double limiteAnualMEI = 81000.00;

  // Getters
  String get ambitoAtual => _ambitoAtual;
  String get filtroTipo => _filtroTipo;
  String get termoBusca => _termoBusca;
  bool get carregando => _carregando;
  bool get ocultarSaldo => _ocultarSaldo;
  DateTime get mesSelecionado => _mesSelecionado;
  bool get filtrarPorMes => _filtrarPorMes;
  double get taxaDebito => _taxaDebito;
  double get taxaCredito => _taxaCredito;

  void toggleOcultarSaldo() {
    _ocultarSaldo = !_ocultarSaldo;
    notifyListeners();
  }

  // Lista Filtrada
  List<Transacao> get transacoesFiltradas {
    return _todasTransacoes.where((t) {
      final matchAmbito = t.ambito == _ambitoAtual;
      final matchTipo = _filtroTipo == 'Todos' ||
          (_filtroTipo == 'Entradas' && t.tipo == 'entrada') ||
          (_filtroTipo == 'Saídas' && t.tipo == 'saida');
      final matchBusca = _termoBusca.isEmpty ||
          t.descricao.toLowerCase().contains(_termoBusca.toLowerCase()) ||
          t.categoria.toLowerCase().contains(_termoBusca.toLowerCase());
      final matchMes = !_filtrarPorMes ||
          (t.data.year == _mesSelecionado.year && t.data.month == _mesSelecionado.month);

      return matchAmbito && matchTipo && matchBusca && matchMes;
    }).toList();
  }

  // Agrupamento por Dia (Imagem 2)
  Map<String, List<Transacao>> get transacoesAgrupadasPorDia {
    final Map<String, List<Transacao>> grupos = {};
    const mesesAbrev = ['JAN', 'FEV', 'MAR', 'ABR', 'MAI', 'JUN', 'JUL', 'AGO', 'SET', 'OUT', 'NOV', 'DEZ'];

    for (final t in transacoesFiltradas) {
      final chave = '${t.data.day.toString().padLeft(2, '0')} ${mesesAbrev[t.data.month - 1]}';
      grupos.putIfAbsent(chave, () => []).add(t);
    }
    return grupos;
  }

  // Totais
  double get totalEntradas => transacoesFiltradas
      .where((t) => t.tipo == 'entrada' && t.status == 'Pago')
      .fold(0.0, (acc, t) => acc + t.valor);

  double get totalSaidas => transacoesFiltradas
      .where((t) => t.tipo == 'saida' && t.status == 'Pago')
      .fold(0.0, (acc, t) => acc + t.valor);

  double get saldoAtual => totalEntradas - totalSaidas;

  // Imagem 1: Histórico Comparativo dos Últimos 3 Meses
  List<MesComparativo> get comparativoUltimosMeses {
    const mesesAbrev = ['JAN', 'FEV', 'MAR', 'ABR', 'MAI', 'JUN', 'JUL', 'AGO', 'SET', 'OUT', 'NOV', 'DEZ'];
    const mesesCompletos = ['Janeiro', 'Fevereiro', 'Março', 'Abril', 'Maio', 'Junho', 'Julho', 'Agosto', 'Setembro', 'Outubro', 'Novembro', 'Dezembro'];

    final List<MesComparativo> lista = [];
    final agora = DateTime.now();

    for (int i = 2; i >= 0; i--) {
      final mesRef = DateTime(agora.year, agora.month - i, 1);
      final transacoesMes = _todasTransacoes.where((t) =>
          t.ambito == _ambitoAtual &&
          t.status == 'Pago' &&
          t.data.year == mesRef.year &&
          t.data.month == mesRef.month);

      final ent = transacoesMes.where((t) => t.tipo == 'entrada').fold(0.0, (acc, t) => acc + t.valor);
      final sai = transacoesMes.where((t) => t.tipo == 'saida').fold(0.0, (acc, t) => acc + t.valor);

      lista.add(MesComparativo(
        label: '${mesesAbrev[mesRef.month - 1]}/${mesRef.year.toString().substring(2)}',
        nomeMes: mesesCompletos[mesRef.month - 1],
        entradas: ent,
        saidas: sai,
        saldo: ent - sai,
        ano: mesRef.year,
        mes: mesRef.month,
      ));
    }
    return lista;
  }

  // RF-03: Custos
  double get totalCustosFixos => transacoesFiltradas
      .where((t) => t.tipo == 'saida' && t.tipoCusto == 'Fixo' && t.status == 'Pago')
      .fold(0.0, (acc, t) => acc + t.valor);

  double get totalCustosVariaveis => transacoesFiltradas
      .where((t) => t.tipo == 'saida' && t.tipoCusto == 'Variável' && t.status == 'Pago')
      .fold(0.0, (acc, t) => acc + t.valor);

  double get totalCustosEmergencia => transacoesFiltradas
      .where((t) => t.tipo == 'saida' && t.tipoCusto == 'Emergência' && t.status == 'Pago')
      .fold(0.0, (acc, t) => acc + t.valor);

  // RF-05: Taxas
  double get totalRecebidoDebito => transacoesFiltradas
      .where((t) => t.tipo == 'entrada' && t.formaPagamento == 'Débito' && t.status == 'Pago')
      .fold(0.0, (acc, t) => acc + t.valor);

  double get totalRecebidoCredito => transacoesFiltradas
      .where((t) => t.tipo == 'entrada' && t.formaPagamento == 'Crédito' && t.status == 'Pago')
      .fold(0.0, (acc, t) => acc + t.valor);

  double get estimativaTaxasCartao =>
      (totalRecebidoDebito * (_taxaDebito / 100)) + (totalRecebidoCredito * (_taxaCredito / 100));

  // RF-04: MEI Anual
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

  void filtrarTipo(String tipo) {
    _filtroTipo = tipo;
    notifyListeners();
  }

  void buscar(String q) {
    _termoBusca = q;
    notifyListeners();
  }

  void alternarAmbito(String a) {
    _ambitoAtual = a;
    notifyListeners();
  }

  void atualizarTaxas(double deb, double cred) {
    _taxaDebito = deb;
    _taxaCredito = cred;
    notifyListeners();
  }

  Future<void> carregarTransacoes() async {
    _carregando = true;
    notifyListeners();
    _todasTransacoes = await _repository.listarTodas();
    _carregando = false;
    notifyListeners();
  }

  // Novo Lançamento com Suporte a Parcelamento Automático (1x a 12x)
  Future<void> adicionarTransacaoParcelada(Transacao base, int totalParcelas) async {
    if (totalParcelas <= 1) {
      await _repository.inserir(base);
    } else {
      final valorPorParcela = base.valor / totalParcelas;
      for (int i = 1; i <= totalParcelas; i++) {
        final dataParcela = DateTime(base.data.year, base.data.month + (i - 1), base.data.day);
        final desc = '${base.descricao} ($i/$totalParcelas)';
        final statusParcela = i == 1 ? base.status : 'Pendente'; // 1ª parcela paga, próximas a receber/pagar

        final parcela = Transacao(
          descricao: desc,
          valor: valorPorParcela,
          tipo: base.tipo,
          ambito: base.ambito,
          categoria: base.categoria,
          formaPagamento: base.formaPagamento,
          status: statusParcela,
          tipoCusto: base.tipoCusto,
          tipoReceita: base.tipoReceita,
          parcelaAtual: i,
          totalParcelas: totalParcelas,
          data: dataParcela,
        );
        await _repository.inserir(parcela);
      }
    }
    await carregarTransacoes();
  }

  Future<void> atualizarTransacao(Transacao t) async {
    await _repository.atualizar(t);
    await carregarTransacoes();
  }

  Future<void> alternarStatus(Transacao t) async {
    final novo = t.status == 'Pago' ? 'Pendente' : 'Pago';
    await _repository.alternarStatusPago(t.id!, novo);
    await carregarTransacoes();
  }

  Future<void> removerTransacao(int id) async {
    await _repository.deletar(id);
    await carregarTransacoes();
  }

  Future<void> exportarRelatorioCSV() async {
    final buffer = StringBuffer();
    buffer.writeln('ID,Data,Descricao,Valor,Tipo,Ambito,Categoria,FormaPagamento,Status,Parcela');
    for (final t in _todasTransacoes) {
      buffer.writeln('${t.id},"${t.data.toIso8601String()}","${t.descricao}",${t.valor},${t.tipo},${t.ambito},"${t.categoria}",${t.formaPagamento},${t.status},"${t.parcelaAtual}/${t.totalParcelas}"');
    }
    final directory = await getTemporaryDirectory();
    final file = File('${directory.path}/relatorio_financeiro_${DateFormat('yyyyMMdd').format(DateTime.now())}.csv');
    await file.writeAsString(buffer.toString());
    await Share.shareXFiles([XFile(file.path)], text: 'Relatório Financeiro CSV');
  }

  Future<void> exportarBackupJSON() async {
    final listaMap = _todasTransacoes.map((e) => e.toMap()).toList();
    final jsonString = jsonEncode(listaMap);
    final directory = await getTemporaryDirectory();
    final file = File('${directory.path}/backup_bella_gestao_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}.json');
    await file.writeAsString(jsonString);
    await Share.shareXFiles([XFile(file.path)], text: 'Backup Bella Gestão');
  }

  Future<bool> restaurarBackupJSON(String conteudoJson) async {
    try {
      final List<dynamic> decoded = jsonDecode(conteudoJson);
      for (final item in decoded) {
        final map = Map<String, dynamic>.from(item);
        map.remove('id');
        await _repository.inserir(Transacao.fromMap(map));
      }
      await carregarTransacoes();
      return true;
    } catch (_) {
      return false;
    }
  }
}
