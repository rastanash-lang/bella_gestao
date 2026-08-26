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
  String _ambitoAtual = 'PJ';
  bool _carregando = false;

  static const double limiteAnualMEI = 81000.00;

  List<Transacao> get transacoesFiltradas =>
      _todasTransacoes.where((t) => t.ambito == _ambitoAtual).toList();

  String get ambitoAtual => _ambitoAtual;
  bool get carregando => _carregando;

  double get totalEntradas => transacoesFiltradas
      .where((t) => t.tipo == 'entrada' && t.status == 'Pago')
      .fold(0.0, (acc, t) => acc + t.valor);

  double get totalSaidas => transacoesFiltradas
      .where((t) => t.tipo == 'saida' && t.status == 'Pago')
      .fold(0.0, (acc, t) => acc + t.valor);

  double get saldoAtual => totalEntradas - totalSaidas;

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

  Future<void> carregarTransacoes() async {
    _carregando = true;
    notifyListeners();
    _todasTransacoes = await _repository.listarTodas();
    _carregando = false;
    notifyListeners();
  }

  void alternarAmbito(String novoAmbito) {
    if (_ambitoAtual != novoAmbito) {
      _ambitoAtual = novoAmbito;
      notifyListeners();
    }
  }

  Future<void> adicionarTransacao(Transacao transacao) async {
    await _repository.inserir(transacao);
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

  Future<void> exportarBackupJSON() async {
    final listaMap = _todasTransacoes.map((e) => e.toMap()).toList();
    final jsonString = jsonEncode(listaMap);
    final directory = await getTemporaryDirectory();
    final file = File('${directory.path}/backup_bella_gestao_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}.json');
    await file.writeAsString(jsonString);
    await Share.shareXFiles([XFile(file.path)], text: 'Backup Bella Gestão');
  }
}
