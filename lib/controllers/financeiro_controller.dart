import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';

// Models
import '../data/models/transacao_model.dart';
import '../data/models/cofrinho_model.dart';
import '../data/models/agendamento_model.dart';
import '../data/models/produto_model.dart';

// Repositories
import '../data/repositories/transacao_repository.dart';
import '../data/repositories/cofrinho_repository.dart';
import '../data/repositories/agendamento_repository.dart';
import '../data/repositories/produto_repository.dart';

// Services
import '../core/services/pdf_service.dart';
import '../core/services/notification_service.dart';

class SlotHorario {
  final DateTime inicio;
  final DateTime fim;
  final bool ocupado;
  final bool passado;
  final Agendamento? agendamento;

  SlotHorario({
    required this.inicio,
    required this.fim,
    required this.ocupado,
    this.passado = false,
    this.agendamento,
  });
}

class MesComparativo {
  final String label;
  final String nomeMes;
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

class ClienteResumo {
  final String nome;
  final double totalGasto;
  final double totalPendente;
  final int totalAtendimentos;
  final DateTime ultimoAtendimento;
  final List<Transacao> historico;

  ClienteResumo({
    required this.nome,
    required this.totalGasto,
    required this.totalPendente,
    required this.totalAtendimentos,
    required this.ultimoAtendimento,
    required this.historico,
  });
}

class FinanceiroController extends ChangeNotifier {
  final TransacaoRepository _repository = TransacaoRepository();
  final CofrinhoRepository _cofrinhoRepo = CofrinhoRepository();
  final AgendamentoRepository _agendamentoRepo = AgendamentoRepository();
  final ProdutoRepository _produtoRepo = ProdutoRepository();

  List<Transacao> _todasTransacoes = [];
  List<MetaCofrinho> _cofrinhos = [];
  List<Agendamento> _agendamentos = [];
  List<Produto> _produtos = [];

  String _ambitoAtual = 'PJ';
  String _filtroTipo = 'Todos';
  String _termoBusca = '';
  bool _carregando = false;
  bool _ocultarSaldo = true;

  DateTime _mesSelecionado = DateTime(DateTime.now().year, DateTime.now().month);
  DateTime _diaSelecionadoAgenda = DateTime.now();
  bool _filtrarPorMes = true;

  double _taxaDebito = 1.99;
  double _taxaCredito = 3.99;

  static const double limiteAnualMEI = 81000.00;

  // ==================== GETTERS ====================
  String get ambitoAtual => _ambitoAtual;
  String get filtroTipo => _filtroTipo;
  String get termoBusca => _termoBusca;
  bool get carregando => _carregando;
  bool get ocultarSaldo => _ocultarSaldo;
  DateTime get mesSelecionado => _mesSelecionado;
  DateTime get diaSelecionadoAgenda => _diaSelecionadoAgenda;
  bool get filtrarPorMes => _filtrarPorMes;
  double get taxaDebito => _taxaDebito;
  double get taxaCredito => _taxaCredito;
  List<MetaCofrinho> get cofrinhos => _cofrinhos;
  List<Agendamento> get agendamentos => _agendamentos;
  List<Produto> get produtos => _produtos;
  List<Produto> get produtosEstoqueBaixo => _produtos.where((p) => p.estoqueBaixo).toList();

  double get totalGuardadoCofrinhos =>
      _cofrinhos.fold(0.0, (acc, c) => acc + c.valorAtual);

  void toggleOcultarSaldo() {
    _ocultarSaldo = !_ocultarSaldo;
    notifyListeners();
  }

  // ==================== CONTROLE DA AGENDA ====================
  void selecionarDiaAgenda(DateTime dia) {
    _diaSelecionadoAgenda = dia;
    notifyListeners();
  }

  List<Agendamento> get agendamentosDoDia {
    return _agendamentos.where((a) =>
        a.dataHoraInicio.year == _diaSelecionadoAgenda.year &&
        a.dataHoraInicio.month == _diaSelecionadoAgenda.month &&
        a.dataHoraInicio.day == _diaSelecionadoAgenda.day).toList();
  }

  List<SlotHorario> obterGradeVagasDoDia(DateTime dia) {
    final List<SlotHorario> slots = [];
    final inicioDia = DateTime(dia.year, dia.month, dia.day, 8, 0);
    final fimDia = DateTime(dia.year, dia.month, dia.day, 20, 0);
    final agora = DateTime.now();

    final isHoje = dia.year == agora.year && dia.month == agora.month && dia.day == agora.day;
    final isDiaPassado = dia.isBefore(DateTime(agora.year, agora.month, agora.day));

    DateTime atual = inicioDia;
    while (atual.isBefore(fimDia)) {
      final slotFim = atual.add(const Duration(minutes: 30));
      final bool slotJaPassou = isDiaPassado || (isHoje && slotFim.isBefore(agora));

      Agendamento? agendamentoOcupando;
      for (final a in _agendamentos) {
        if (a.status == 'Cancelado') continue;
        if (a.dataHoraInicio.year == dia.year &&
            a.dataHoraInicio.month == dia.month &&
            a.dataHoraInicio.day == dia.day) {
          if (atual.isBefore(a.dataHoraFim) && slotFim.isAfter(a.dataHoraInicio)) {
            agendamentoOcupando = a;
            break;
          }
        }
      }

      slots.add(SlotHorario(
        inicio: atual,
        fim: slotFim,
        ocupado: agendamentoOcupando != null,
        passado: slotJaPassou,
        agendamento: agendamentoOcupando,
      ));

      atual = slotFim;
    }
    return slots;
  }

  Agendamento? verificarConflitoHorario(DateTime inicioProposto, int duracaoMinutos, {int? ignorarId}) {
    final fimProposto = inicioProposto.add(Duration(minutes: duracaoMinutos));

    for (final a in _agendamentos) {
      if (a.status == 'Cancelado') continue;
      if (ignorarId != null && a.id == ignorarId) continue;

      if (a.dataHoraInicio.year == inicioProposto.year &&
          a.dataHoraInicio.month == inicioProposto.month &&
          a.dataHoraInicio.day == inicioProposto.day) {
        final sobrepoe = inicioProposto.isBefore(a.dataHoraFim) && fimProposto.isAfter(a.dataHoraInicio);
        if (sobrepoe) {
          return a;
        }
      }
    }
    return null;
  }

  DateTime calcularProximoHorarioVago(DateTime dataBase, int duracaoMinutos) {
    final agora = DateTime.now();
    DateTime horarioTeste = DateTime(dataBase.year, dataBase.month, dataBase.day, dataBase.hour, dataBase.minute);

    if (horarioTeste.isBefore(agora)) {
      final minutoArredondado = ((agora.minute / 15).ceil() * 15);
      horarioTeste = DateTime(agora.year, agora.month, agora.day, agora.hour, 0).add(Duration(minutes: minutoArredondado));
    }

    for (int i = 0; i < 48; i++) {
      final conflito = verificarConflitoHorario(horarioTeste, duracaoMinutos);
      if (conflito == null) {
        return horarioTeste;
      }
      horarioTeste = conflito.dataHoraFim;
    }
    return horarioTeste;
  }

  // ==================== CLIENTES CRM ====================
  List<String> get nomesClientesUnicos {
    return _todasTransacoes
        .where((t) => t.cliente != null && t.cliente!.trim().isNotEmpty)
        .map((t) => t.cliente!.trim())
        .toSet()
        .toList();
  }

  List<ClienteResumo> get listaClientes {
    final Map<String, List<Transacao>> porCliente = {};

    for (final t in _todasTransacoes) {
      if (t.tipo == 'entrada' && t.cliente != null && t.cliente!.trim().isNotEmpty) {
        final nomeFormatado = t.cliente!.trim();
        porCliente.putIfAbsent(nomeFormatado, () => []).add(t);
      }
    }

    final List<ClienteResumo> lista = [];

    porCliente.forEach((nome, transacoes) {
      transacoes.sort((a, b) => b.data.compareTo(a.data));
      final totalGasto = transacoes.where((t) => t.status == 'Pago').fold(0.0, (acc, t) => acc + t.valor);
      final totalPendente = transacoes.where((t) => t.status == 'Pendente').fold(0.0, (acc, t) => acc + t.valor);

      lista.add(ClienteResumo(
        nome: nome,
        totalGasto: totalGasto,
        totalPendente: totalPendente,
        totalAtendimentos: transacoes.length,
        ultimoAtendimento: transacoes.first.data,
        historico: transacoes,
      ));
    });

    lista.sort((a, b) => b.totalGasto.compareTo(a.totalGasto));
    return lista;
  }

  // ==================== FILTROS E EXTRATO ====================
  List<Transacao> get transacoesFiltradas {
    return _todasTransacoes.where((t) {
      if (t.categoria.contains('Cofrinho') || t.descricao.contains('Cofrinho')) return false;

      final matchAmbito = t.ambito == _ambitoAtual;
      final matchTipo = _filtroTipo == 'Todos' ||
          (_filtroTipo == 'Entradas' && t.tipo == 'entrada') ||
          (_filtroTipo == 'Saídas' && t.tipo == 'saida');
      final matchBusca = _termoBusca.isEmpty ||
          t.descricao.toLowerCase().contains(_termoBusca.toLowerCase()) ||
          (t.cliente != null && t.cliente!.toLowerCase().contains(_termoBusca.toLowerCase())) ||
          t.categoria.toLowerCase().contains(_termoBusca.toLowerCase());
      final matchMes = !_filtrarPorMes ||
          (t.data.year == _mesSelecionado.year && t.data.month == _mesSelecionado.month);

      return matchAmbito && matchTipo && matchBusca && matchMes;
    }).toList();
  }

  Map<String, List<Transacao>> get transacoesAgrupadasPorDia {
    final Map<String, List<Transacao>> grupos = {};
    const mesesAbrev = ['JAN', 'FEV', 'MAR', 'ABR', 'MAI', 'JUN', 'JUL', 'AGO', 'SET', 'OUT', 'NOV', 'DEZ'];

    for (final t in transacoesFiltradas) {
      final chave = '${t.data.day.toString().padLeft(2, '0')} ${mesesAbrev[t.data.month - 1]}';
      grupos.putIfAbsent(chave, () => []).add(t);
    }
    return grupos;
  }

  // ==================== CONTABILIDADE REAL (CORREÇÃO BUG-02) ====================

  // Saldo Disponível em Caixa (Padronizado conforme BUG-02):
  // Saldo Disponível em Caixa = (Total Entradas PJ - Total Saídas PJ - Total Gastos PF) - Total Guardado em Cofrinhos
  double get saldoAtual {
    final totalEntradasPJ = _todasTransacoes
        .where((t) =>
            t.ambito == 'PJ' &&
            t.tipo == 'entrada' &&
            t.status == 'Pago' &&
            !t.categoria.contains('Cofrinho') &&
            !t.descricao.contains('Cofrinho'))
        .fold(0.0, (acc, t) => acc + t.valor);

    final totalSaidasPJ = _todasTransacoes
        .where((t) =>
            t.ambito == 'PJ' &&
            t.tipo == 'saida' &&
            t.status == 'Pago' &&
            !t.categoria.contains('Cofrinho') &&
            !t.descricao.contains('Cofrinho'))
        .fold(0.0, (acc, t) => acc + t.valor);

    final totalGastosPF = _todasTransacoes
        .where((t) =>
            t.ambito == 'PF' &&
            t.tipo == 'saida' &&
            t.status == 'Pago' &&
            !t.categoria.contains('Cofrinho') &&
            !t.descricao.contains('Cofrinho'))
        .fold(0.0, (acc, t) => acc + t.valor);

    return (totalEntradasPJ - totalSaidasPJ - totalGastosPF) - totalGuardadoCofrinhos;
  }

  double get saldoDisponivelCaixaPJ => saldoAtual;

  // Saldo exibido no topo do Cartão Principal
  double get saldoGeralAcumulado {
    if (_ambitoAtual == 'PJ') {
      return saldoAtual;
    } else {
      final entPF = _todasTransacoes
          .where((t) =>
              t.ambito == 'PF' &&
              t.tipo == 'entrada' &&
              t.status == 'Pago' &&
              !t.categoria.contains('Cofrinho'))
          .fold(0.0, (acc, t) => acc + t.valor);

      final saiPF = _todasTransacoes
          .where((t) =>
              t.ambito == 'PF' &&
              t.tipo == 'saida' &&
              t.status == 'Pago' &&
              !t.categoria.contains('Cofrinho'))
          .fold(0.0, (acc, t) => acc + t.valor);

      return entPF - saiPF;
    }
  }

  double get totalGastosPessoaisMes {
    return _todasTransacoes
        .where((t) =>
            t.ambito == 'PF' &&
            t.tipo == 'saida' &&
            t.status == 'Pago' &&
            !t.categoria.contains('Cofrinho') &&
            !t.descricao.contains('Cofrinho') &&
            (!_filtrarPorMes || (t.data.year == _mesSelecionado.year && t.data.month == _mesSelecionado.month)))
        .fold(0.0, (acc, t) => acc + t.valor);
  }

  double get totalEntradasMes => transacoesFiltradas
      .where((t) => t.tipo == 'entrada' && t.status == 'Pago')
      .fold(0.0, (acc, t) => acc + t.valor);

  double get totalSaidasMes => transacoesFiltradas
      .where((t) => t.tipo == 'saida' && t.status == 'Pago')
      .fold(0.0, (acc, t) => acc + t.valor);

  double get saldoSaladoAposGastosPessoaisMes {
    if (_ambitoAtual == 'PJ') {
      return totalEntradasMes - totalSaidasMes - totalGastosPessoaisMes;
    }
    return totalEntradasMes - totalSaidasMes;
  }

  double get saldoMes => saldoSaladoAposGastosPessoaisMes;

  // ==================== CUSTOS & TAXAS ====================
  double get totalCustosFixos => transacoesFiltradas
      .where((t) => t.tipo == 'saida' && t.tipoCusto == 'Fixo' && t.status == 'Pago')
      .fold(0.0, (acc, t) => acc + t.valor);

  double get totalCustosVariaveis => transacoesFiltradas
      .where((t) => t.tipo == 'saida' && t.tipoCusto == 'Variável' && t.status == 'Pago')
      .fold(0.0, (acc, t) => acc + t.valor);

  double get totalCustosEmergencia => transacoesFiltradas
      .where((t) => t.tipo == 'saida' && t.tipoCusto == 'Emergência' && t.status == 'Pago')
      .fold(0.0, (acc, t) => acc + t.valor);

  double get totalRecebidoDebito => transacoesFiltradas
      .where((t) => t.tipo == 'entrada' && t.formaPagamento == 'Débito' && t.status == 'Pago')
      .fold(0.0, (acc, t) => acc + t.valor);

  double get totalRecebidoCredito => transacoesFiltradas
      .where((t) => t.tipo == 'entrada' && t.formaPagamento == 'Crédito' && t.status == 'Pago')
      .fold(0.0, (acc, t) => acc + t.valor);

  double get estimativaTaxasCartao =>
      (totalRecebidoDebito * (_taxaDebito / 100)) + (totalRecebidoCredito * (_taxaCredito / 100));

  // ==================== MÓDULO MEI (DASN-SIMEI) ====================
  // Sem receitas fantasmas decorrentes de resgates de cofrinho
  double get faturamentoAnualMEI {
    final anoAtual = DateTime.now().year;
    return _todasTransacoes
        .where((t) =>
            t.ambito == 'PJ' &&
            t.tipo == 'entrada' &&
            t.status == 'Pago' &&
            !t.categoria.contains('Cofrinho') &&
            !t.descricao.contains('Cofrinho') &&
            t.data.year == anoAtual)
        .fold(0.0, (acc, t) => acc + t.valor);
  }

  double get faturamentoServicosMEI {
    final anoAtual = DateTime.now().year;
    return _todasTransacoes
        .where((t) =>
            t.ambito == 'PJ' &&
            t.tipo == 'entrada' &&
            (t.tipoReceita == 'Serviço' || t.tipoReceita == null || t.tipoReceita == '') &&
            !t.categoria.contains('Cofrinho') &&
            !t.descricao.contains('Cofrinho') &&
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
            !t.categoria.contains('Cofrinho') &&
            !t.descricao.contains('Cofrinho') &&
            t.status == 'Pago' &&
            t.data.year == anoAtual)
        .fold(0.0, (acc, t) => acc + t.valor);
  }

  double get percentualMEI => (faturamentoAnualMEI / limiteAnualMEI).clamp(0.0, 1.0);

  // ==================== COMPARATIVO FINANÇAS ====================
  List<MesComparativo> get comparativoMeses {
    const mesesAbrev = ['JAN', 'FEV', 'MAR', 'ABR', 'MAI', 'JUN', 'JUL', 'AGO', 'SET', 'OUT', 'NOV', 'DEZ'];
    const mesesCompletos = ['Janeiro', 'Fevereiro', 'Março', 'Abril', 'Maio', 'Junho', 'Julho', 'Agosto', 'Setembro', 'Outubro', 'Novembro', 'Dezembro'];

    final Set<String> chavesMeses = {};
    final agora = DateTime.now();

    for (int i = 2; i >= 0; i--) {
      final mRef = DateTime(agora.year, agora.month - i, 1);
      chavesMeses.add('${mRef.year}-${mRef.month.toString().padLeft(2, '0')}');
    }

    for (final t in _todasTransacoes) {
      if (t.categoria.contains('Cofrinho') || t.descricao.contains('Cofrinho')) continue;
      chavesMeses.add('${t.data.year}-${t.data.month.toString().padLeft(2, '0')}');
    }

    final chavesOrdenadas = chavesMeses.toList()..sort();
    final List<MesComparativo> lista = [];

    for (final chave in chavesOrdenadas) {
      final partes = chave.split('-');
      final ano = int.parse(partes[0]);
      final mes = int.parse(partes[1]);

      final entPJ = _todasTransacoes
          .where((t) =>
              t.ambito == 'PJ' &&
              t.tipo == 'entrada' &&
              t.status == 'Pago' &&
              !t.categoria.contains('Cofrinho') &&
              !t.descricao.contains('Cofrinho') &&
              t.data.year == ano &&
              t.data.month == mes)
          .fold(0.0, (acc, t) => acc + t.valor);

      final saiPJ = _todasTransacoes
          .where((t) =>
              t.ambito == 'PJ' &&
              t.tipo == 'saida' &&
              t.status == 'Pago' &&
              !t.categoria.contains('Cofrinho') &&
              !t.descricao.contains('Cofrinho') &&
              t.data.year == ano &&
              t.data.month == mes)
          .fold(0.0, (acc, t) => acc + t.valor);

      final saiPF = _todasTransacoes
          .where((t) =>
              t.ambito == 'PF' &&
              t.tipo == 'saida' &&
              t.status == 'Pago' &&
              !t.categoria.contains('Cofrinho') &&
              !t.descricao.contains('Cofrinho') &&
              t.data.year == ano &&
              t.data.month == mes)
          .fold(0.0, (acc, t) => acc + t.valor);

      final saldoRealMes = entPJ - saiPJ - saiPF;

      lista.add(MesComparativo(
        label: '${mesesAbrev[mes - 1]}/${ano.toString().substring(2)}',
        nomeMes: '${mesesCompletos[mes - 1]} $ano',
        entradas: entPJ,
        saidas: saiPJ + saiPF,
        saldo: saldoRealMes,
        ano: ano,
        mes: mes,
      ));
    }

    return lista;
  }

  // ==================== NAVEGAÇÃO ====================
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

  // ==================== CARREGAMENTO GERAL ====================
  Future<void> carregarTransacoes() async {
    _carregando = true;
    notifyListeners();
    _todasTransacoes = await _repository.listarTodas();
    _cofrinhos = await _cofrinhoRepo.listarTodos();
    _agendamentos = await _agendamentoRepo.listarTodos();
    _produtos = await _produtoRepo.listarTodos();
    _carregando = false;
    notifyListeners();
  }

  // ==================== ESTOQUE ====================
  Future<void> criarProduto(Produto p) async {
    await _produtoRepo.inserir(p);
    await carregarTransacoes();
  }

  Future<void> atualizarProduto(Produto p) async {
    await _produtoRepo.atualizar(p);
    await carregarTransacoes();
  }

  Future<void> excluirProduto(int id) async {
    await _produtoRepo.deletar(id);
    await carregarTransacoes();
  }

  Future<void> movimentarEstoque({
    required Produto produto,
    required int quantidadeDelta,
    required bool isEntrada,
    bool lancarNoCaixa = false,
    String formaPagamento = 'Pix',
  }) async {
    final novaQtd = (produto.quantidadeAtual + (isEntrada ? quantidadeDelta : -quantidadeDelta)).clamp(0, 99999);
    await _produtoRepo.atualizarQuantidade(produto.id!, novaQtd);

    if (lancarNoCaixa) {
      if (isEntrada) {
        final totalCompra = produto.precoCusto * quantidadeDelta;
        await _repository.inserir(Transacao(
          descricao: 'Compra Estoque: ${produto.nome} ($quantidadeDelta ${produto.unidade})',
          valor: totalCompra,
          tipo: 'saida',
          ambito: 'PJ',
          categoria: 'Produtos/Cosméticos',
          formaPagamento: formaPagamento,
          status: 'Pago',
          tipoCusto: 'Variável',
          data: DateTime.now(),
        ));
      } else {
        final totalVenda = (produto.precoVenda > 0 ? produto.precoVenda : produto.precoCusto) * quantidadeDelta;
        await _repository.inserir(Transacao(
          descricao: 'Venda Produto: ${produto.nome} ($quantidadeDelta ${produto.unidade})',
          valor: totalVenda,
          tipo: 'entrada',
          ambito: 'PJ',
          categoria: 'Venda de Produtos',
          formaPagamento: formaPagamento,
          status: 'Pago',
          tipoReceita: 'Produto',
          data: DateTime.now(),
        ));
      }
    }

    await carregarTransacoes();
  }

  // ==================== COFRINHOS (MOVIMENTAÇÃO NEUTRA SEM DUPLA DEDUÇÃO) ====================
  Future<void> criarCofrinho(String titulo, double valorAlvo) async {
    final novaMeta = MetaCofrinho(
      titulo: titulo,
      valorAlvo: valorAlvo,
      valorAtual: 0.0,
      dataCriacao: DateTime.now(),
    );
    await _cofrinhoRepo.inserir(novaMeta);
    await carregarTransacoes();
  }

  // Movimenta o valor estritamente na tabela cofrinhos sem duplicar saídas na tabela transacoes
  Future<bool> movimentarCofrinho({
    required int id,
    required double valorAtual,
    required double valorMovimentado,
    required bool isAdicao,
  }) async {
    if (valorMovimentado <= 0) return false;

    // Se for depósito, valida se há saldo suficiente em caixa
    if (isAdicao) {
      if (valorMovimentado > saldoAtual) {
        return false;
      }
    } else {
      if (valorMovimentado > valorAtual) {
        return false;
      }
    }

    final novoTotal = isAdicao
        ? (valorAtual + valorMovimentado)
        : (valorAtual - valorMovimentado).clamp(0.0, double.infinity);

    await _cofrinhoRepo.atualizarValor(id, novoTotal.toDouble());
    await carregarTransacoes();
    return true;
  }

  Future<void> excluirCofrinho(int id) async {
    await _cofrinhoRepo.deletar(id);
    await carregarTransacoes();
  }

  // ==================== AGENDAMENTOS ====================
  Future<void> criarAgendamento(Agendamento agendamento) async {
    final id = await _agendamentoRepo.inserir(agendamento);
    final agendamentoComId = agendamento.copyWith(id: id);
    await NotificationService.agendarLembreteAgendamento(agendamentoComId);
    await carregarTransacoes();
  }

  Future<void> atualizarAgendamento(Agendamento agendamento) async {
    await _agendamentoRepo.atualizar(agendamento);

    if (agendamento.id != null) {
      await NotificationService.cancelarLembrete(agendamento.id!);
      if (agendamento.status == 'Agendado') {
        await NotificationService.agendarLembreteAgendamento(agendamento);
      }
    }

    await carregarTransacoes();
  }

  Future<void> ajustarHorarioAgendamento(Agendamento a, int minutosDeslocamento) async {
    final novoInicio = a.dataHoraInicio.add(Duration(minutes: minutosDeslocamento));
    final conflito = verificarConflitoHorario(novoInicio, a.duracaoMinutos, ignorarId: a.id);

    if (conflito == null) {
      final atualizado = a.copyWith(dataHoraInicio: novoInicio);
      await atualizarAgendamento(atualizado);
    }
  }

  Future<void> alternarCancelamentoAgendamento(Agendamento a) async {
    final novoStatus = a.status == 'Cancelado' ? 'Agendado' : 'Cancelado';
    await _agendamentoRepo.atualizarStatus(a.id!, novoStatus);

    if (novoStatus == 'Cancelado') {
      await NotificationService.cancelarLembrete(a.id!);
    } else {
      await NotificationService.agendarLembreteAgendamento(a.copyWith(status: 'Agendado'));
    }

    await carregarTransacoes();
  }

  Future<void> concluirAtendimentoELancarNoCaixa({
    required Agendamento agendamento,
    required String formaPagamento,
    required String categoria,
    required String tipoReceita,
  }) async {
    await _agendamentoRepo.atualizarStatus(agendamento.id!, 'Concluido');
    await NotificationService.cancelarLembrete(agendamento.id!);

    final novaTransacao = Transacao(
      descricao: '${agendamento.servico} (Atendimento)',
      cliente: agendamento.cliente,
      valor: agendamento.valor,
      tipo: 'entrada',
      ambito: 'PJ',
      categoria: categoria,
      formaPagamento: formaPagamento,
      status: 'Pago',
      tipoReceita: tipoReceita,
      data: agendamento.dataHoraInicio,
    );

    await _repository.inserir(novaTransacao);
    await carregarTransacoes();
  }

  Future<void> excluirAgendamento(int id) async {
    await NotificationService.cancelarLembrete(id);
    await _agendamentoRepo.deletar(id);
    await carregarTransacoes();
  }

  void compartilharLembreteAgendamentoWhatsApp(Agendamento a) {
    final currency = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    final dataFormat = DateFormat('dd/MM/yyyy (EEEE)', 'pt_BR');
    final horaInicio = DateFormat('HH:mm').format(a.dataHoraInicio);
    final horaFim = DateFormat('HH:mm').format(a.dataHoraFim);

    final duracaoTexto = a.duracaoMinutos >= 60
        ? '${a.duracaoMinutos ~/ 60}h${a.duracaoMinutos % 60 > 0 ? "${a.duracaoMinutos % 60}min" : ""}'
        : '${a.duracaoMinutos} min';

    final buffer = StringBuffer();
    buffer.writeln('🌸 *LEMBRETE DE AGENDAMENTO* 🌸');
    buffer.writeln('🏢 *Salão de Beleza*');
    buffer.writeln('────────────────────────');
    buffer.writeln('👤 *Cliente:* ${a.cliente}');
    buffer.writeln('💇‍♀️ *Procedimento:* ${a.servico}');
    buffer.writeln('📅 *Data:* ${dataFormat.format(a.dataHoraInicio)}');
    buffer.writeln('⏰ *Horário:* $horaInicio às $horaFim (Duração: $duracaoTexto)');
    buffer.writeln('💰 *Valor:* ${currency.format(a.valor)}');
    if (a.observacoes != null && a.observacoes!.isNotEmpty) {
      buffer.writeln('📝 *Obs:* ${a.observacoes}');
    }
    buffer.writeln('────────────────────────');
    buffer.writeln('_Por favor, confirme se poderá comparecer ou nos avise com antecedência. Esperamos por você!_ ✨');

    Share.share(buffer.toString());
  }

  // ==================== TRANSAÇÕES FINANCEIRAS ====================
  Future<void> adicionarTransacaoParcelada(Transacao base, int totalParcelas) async {
    if (totalParcelas <= 1) {
      await _repository.inserir(base);
    } else {
      final valorPorParcela = base.valor / totalParcelas;
      for (int i = 1; i <= totalParcelas; i++) {
        final dataParcela = DateTime(base.data.year, base.data.month + (i - 1), base.data.day);
        final desc = '${base.descricao} ($i/$totalParcelas)';
        final statusParcela = i == 1 ? base.status : 'Pendente';

        final parcela = Transacao(
          descricao: desc,
          cliente: base.cliente,
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

  void compartilharReciboWhatsApp(Transacao t) {
    final currency = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    final dateFormat = DateFormat('dd/MM/yyyy às HH:mm');

    final buffer = StringBuffer();
    buffer.writeln('✨ *COMPROVANTE DE ATENDIMENTO* ✨');
    buffer.writeln('🏢 *Salão de Beleza*');
    buffer.writeln('────────────────────────');
    if (t.cliente != null && t.cliente!.trim().isNotEmpty) {
      buffer.writeln('👤 *Cliente:* ${t.cliente}');
    }
    buffer.writeln('💇‍♀️ *Descrição:* ${t.descricao}');
    buffer.writeln('💰 *Valor:* ${currency.format(t.valor)}${t.totalParcelas > 1 ? " (${t.parcelaAtual}/${t.totalParcelas}x)" : ""}');
    buffer.writeln('💳 *Forma de Pagamento:* ${t.formaPagamento} (${t.status})');
    buffer.writeln('📅 *Data:* ${dateFormat.format(t.data)}');
    buffer.writeln('────────────────────────');
    buffer.writeln('_Agradecemos a preferência e confiança! Volte sempre!_ 🌸');

    Share.share(buffer.toString());
  }

  // ==================== EXPORTAÇÃO PDF, CSV & BACKUP ====================
  Future<void> exportarRelatorioPDF() async {
    await PdfService.gerarRelatorioCompletoPDF(
      transacoes: transacoesFiltradas,
      ambito: _ambitoAtual,
      totalEntradas: totalEntradasMes,
      totalSaidas: totalSaidasMes,
      saldo: saldoGeralAcumulado,
      faturamentoServicosMEI: faturamentoServicosMEI,
      faturamentoProdutosMEI: faturamentoProdutosMEI,
      totalCustosFixos: totalCustosFixos,
      totalCustosVariaveis: totalCustosVariaveis,
      totalCustosEmergencia: totalCustosEmergencia,
      estimativaTaxasCartao: estimativaTaxasCartao,
      totalCofrinhos: totalGuardadoCofrinhos,
    );
  }

  Future<void> exportarRelatorioCSV() async {
    final buffer = StringBuffer();
    buffer.writeln('ID,Data,Cliente,Descricao,Valor,Tipo,Ambito,Categoria,FormaPagamento,Status,Parcela');
    for (final t in _todasTransacoes) {
      if (t.categoria.contains('Cofrinho') || t.descricao.contains('Cofrinho')) continue;
      buffer.writeln('${t.id},"${t.data.toIso8601String()}","${t.cliente ?? ''}","${t.descricao}",${t.valor},${t.tipo},${t.ambito},"${t.categoria}",${t.formaPagamento},${t.status},"${t.parcelaAtual}/${t.totalParcelas}"');
    }
    final directory = await getTemporaryDirectory();
    final file = File('${directory.path}/relatorio_financeiro_${DateFormat('yyyyMMdd').format(DateTime.now())}.csv');
    await file.writeAsString(buffer.toString());
    await Share.shareXFiles([XFile(file.path)], text: 'Relatório Financeiro CSV');
  }

  Future<void> exportarBackupJSON() async {
    final backupCompleto = {
      'versao': 2,
      'dataBackup': DateTime.now().toIso8601String(),
      'transacoes': _todasTransacoes.map((e) => e.toMap()).toList(),
      'cofrinhos': _cofrinhos.map((e) => e.toMap()).toList(),
      'agendamentos': _agendamentos.map((e) => e.toMap()).toList(),
      'produtos': _produtos.map((e) => e.toMap()).toList(),
    };

    final jsonString = jsonEncode(backupCompleto);
    final directory = await getTemporaryDirectory();
    final file = File('${directory.path}/backup_bella_gestao_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}.json');
    await file.writeAsString(jsonString);
    await Share.shareXFiles([XFile(file.path)], text: 'Backup Completo Bella Gestão');
  }

  Future<bool> selecionarERestaurarBackupArquivo() async {
    try {
      final PlatformFile? arquivo = await FilePicker.pickFile();
      if (arquivo == null) return false;

      String conteudoJson = '';
      if (arquivo.path != null) {
        final f = File(arquivo.path!);
        conteudoJson = await f.readAsString();
      } else {
        final Uint8List bytes = await arquivo.readAsBytes();
        conteudoJson = utf8.decode(bytes);
      }

      if (conteudoJson.trim().isEmpty) return false;
      return await restaurarBackupJSON(conteudoJson);
    } catch (_) {
      return false;
    }
  }

  Future<bool> restaurarBackupJSON(String conteudoJson) async {
    try {
      final dynamic decoded = jsonDecode(conteudoJson);

      if (decoded is Map<String, dynamic>) {
        if (decoded.containsKey('transacoes')) {
          for (final item in decoded['transacoes']) {
            final map = Map<String, dynamic>.from(item)..remove('id');
            await _repository.inserir(Transacao.fromMap(map));
          }
        }
        if (decoded.containsKey('cofrinhos')) {
          for (final item in decoded['cofrinhos']) {
            final map = Map<String, dynamic>.from(item)..remove('id');
            await _cofrinhoRepo.inserir(MetaCofrinho.fromMap(map));
          }
        }
        if (decoded.containsKey('agendamentos')) {
          for (final item in decoded['agendamentos']) {
            final map = Map<String, dynamic>.from(item)..remove('id');
            await _agendamentoRepo.inserir(Agendamento.fromMap(map));
          }
        }
        if (decoded.containsKey('produtos')) {
          for (final item in decoded['produtos']) {
            final map = Map<String, dynamic>.from(item)..remove('id');
            await _produtoRepo.inserir(Produto.fromMap(map));
          }
        }
      } else if (decoded is List) {
        for (final item in decoded) {
          final map = Map<String, dynamic>.from(item)..remove('id');
          await _repository.inserir(Transacao.fromMap(map));
        }
      }

      await carregarTransacoes();
      return true;
    } catch (_) {
      return false;
    }
  }
}
