import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../data/models/transacao_model.dart';
import '../data/models/cofrinho_model.dart';
import '../data/models/agendamento_model.dart';
import '../data/repositories/transacao_repository.dart';
import '../data/repositories/cofrinho_repository.dart';
import '../data/repositories/agendamento_repository.dart';
import '../core/services/pdf_service.dart';

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

  List<Transacao> _todasTransacoes = [];
  List<MetaCofrinho> _cofrinhos = [];
  List<Agendamento> _agendamentos = [];

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

  // Getters
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

  double get totalGuardadoCofrinhos =>
      _cofrinhos.fold(0.0, (acc, c) => acc + c.valorAtual);

  void toggleOcultarSaldo() {
    _ocultarSaldo = !_ocultarSaldo;
    notifyListeners();
  }

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

  // Lista Filtrada para a lista do Extrato
  List<Transacao> get transacoesFiltradas {
    return _todasTransacoes.where((t) {
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

  // 💰 SALDO GERAL ACUMULADO REAL (Conta tudo desde o primeiro lançamento pago até hoje)
  double get saldoGeralAcumulado {
    final entradasTotais = _todasTransacoes
        .where((t) => t.ambito == _ambitoAtual && t.tipo == 'entrada' && t.status == 'Pago')
        .fold(0.0, (acc, t) => acc + t.valor);

    final saidasTotais = _todasTransacoes
        .where((t) => t.ambito == _ambitoAtual && t.tipo == 'saida' && t.status == 'Pago')
        .fold(0.0, (acc, t) => acc + t.valor);

    return entradasTotais - saidasTotais;
  }

  // Totais do Mês Selecionado (para os cards de Entradas e Saídas do Mês)
  double get totalEntradasMes => transacoesFiltradas
      .where((t) => t.tipo == 'entrada' && t.status == 'Pago')
      .fold(0.0, (acc, t) => acc + t.valor);

  double get totalSaidasMes => transacoesFiltradas
      .where((t) => t.tipo == 'saida' && t.status == 'Pago')
      .fold(0.0, (acc, t) => acc + t.valor);

  double get saldoMes => totalEntradasMes - totalSaidasMes;

  // Comparativo de todos os meses
  List<MesComparativo> get comparativoMeses {
    const mesesAbrev = ['JAN', 'FEV', 'MAR', 'ABR', 'MAI', 'JUN', 'JUL', 'AGO', 'SET', 'OUT', 'NOV', 'DEZ'];
    const mesesCompletos = ['Janeiro', 'Fevereiro', 'Março', 'Abril', 'Maio', 'Junho', 'Julho', 'Agosto', 'Setembro', 'Outubro', 'Novembro', 'Dezembro'];

    final transacoesAmbito = _todasTransacoes.where((t) => t.ambito == _ambitoAtual && t.status == 'Pago').toList();
    final Set<String> chavesMeses = {};
    final agora = DateTime.now();

    for (int i = 2; i >= 0; i--) {
      final mRef = DateTime(agora.year, agora.month - i, 1);
      chavesMeses.add('${mRef.year}-${mRef.month.toString().padLeft(2, '0')}');
    }

    for (final t in transacoesAmbito) {
      chavesMeses.add('${t.data.year}-${t.data.month.toString().padLeft(2, '0')}');
    }

    final chavesOrdenadas = chavesMeses.toList()..sort();
    final List<MesComparativo> lista = [];

    for (final chave in chavesOrdenadas) {
      final partes = chave.split('-');
      final ano = int.parse(partes[0]);
      final mes = int.parse(partes[1]);

      final transacoesMes = transacoesAmbito.where((t) => t.data.year == ano && t.data.month == mes);
      final ent = transacoesMes.where((t) => t.tipo == 'entrada').fold(0.0, (acc, t) => acc + t.valor);
      final sai = transacoesMes.where((t) => t.tipo == 'saida').fold(0.0, (acc, t) => acc + t.valor);

      lista.add(MesComparativo(
        label: '${mesesAbrev[mes - 1]}/${ano.toString().substring(2)}',
        nomeMes: '${mesesCompletos[mes - 1]} $ano',
        entradas: ent,
        saidas: sai,
        saldo: ent - sai,
        ano: ano,
        mes: mes,
      ));
    }

    return lista;
  }

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
    _cofrinhos = await _cofrinhoRepo.listarTodos();
    _agendamentos = await _agendamentoRepo.listarTodos();
    _carregando = false;
    notifyListeners();
  }

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

  Future<void> movimentarCofrinho(int id, double valorAtual, double valorMovimentado, bool isAdicao) async {
    final novoTotal = isAdicao ? (valorAtual + valorMovimentado) : (valorAtual - valorMovimentado).clamp(0.0, double.infinity);
    await _cofrinhoRepo.atualizarValor(id, novoTotal.toDouble());
    await carregarTransacoes();
  }

  Future<void> excluirCofrinho(int id) async {
    await _cofrinhoRepo.deletar(id);
    await carregarTransacoes();
  }

  Future<void> criarAgendamento(Agendamento agendamento) async {
    await _agendamentoRepo.inserir(agendamento);
    await carregarTransacoes();
  }

  Future<void> atualizarAgendamento(Agendamento agendamento) async {
    await _agendamentoRepo.atualizar(agendamento);
    await carregarTransacoes();
  }

  Future<void> ajustarHorarioAgendamento(Agendamento a, int minutosDeslocamento) async {
    final novoInicio = a.dataHoraInicio.add(Duration(minutes: minutosDeslocamento));
    final conflito = verificarConflitoHorario(novoInicio, a.duracaoMinutos, ignorarId: a.id);
    
    if (conflito == null) {
      final atualizado = a.copyWith(dataHoraInicio: novoInicio);
      await _agendamentoRepo.atualizar(atualizado);
      await carregarTransacoes();
    }
  }

  Future<void> alternarCancelamentoAgendamento(Agendamento a) async {
    final novoStatus = a.status == 'Cancelado' ? 'Agendado' : 'Cancelado';
    await _agendamentoRepo.atualizarStatus(a.id!, novoStatus);
    await carregarTransacoes();
  }

  Future<void> concluirAtendimentoELancarNoCaixa({
    required Agendamento agendamento,
    required String formaPagamento,
    required String categoria,
    required String tipoReceita,
  }) async {
    await _agendamentoRepo.atualizarStatus(agendamento.id!, 'Concluido');

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
      buffer.writeln('${t.id},"${t.data.toIso8601String()}","${t.cliente ?? ''}","${t.descricao}",${t.valor},${t.tipo},${t.ambito},"${t.categoria}",${t.formaPagamento},${t.status},"${t.parcelaAtual}/${t.totalParcelas}"');
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
