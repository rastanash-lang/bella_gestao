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

  // Agendamentos filtrados para o dia selecionado
  List<Agendamento> get agendamentosDoDia {
    return _agendamentos.where((a) =>
        a.dataHoraInicio.year == _diaSelecionadoAgenda.year &&
        a.dataHoraInicio.month == _diaSelecionadoAgenda.month &&
        a.dataHoraInicio.day == _diaSelecionadoAgenda.day).toList();
  }

  // ⚠️ VERIFICADOR DE CONFLITO DE HORÁRIO
  Agendamento? verificarConflitoHorario(DateTime inicioProposto, int duracaoMinutos, {int? ignorarId}) {
    final fimProposto = inicioProposto.add(Duration(minutes: duracaoMinutos));

    for (final a in _agendamentos) {
      if (a.status == 'Cancelado') continue;
      if (ignorarId != null && a.id == ignorarId) continue;

      // Verificar se é no mesmo dia
      if (a.dataHoraInicio.year == inicioProposto.year &&
          a.dataHoraInicio.month == inicioProposto.month &&
          a.dataHoraInicio.day == inicioProposto.day) {
        
        // Verifica sobreposição de horários
        final sobrepoe = inicioProposto.isBefore(a.dataHoraFim) && fimProposto.isAfter(a.dataHoraInicio);
        if (sobrepoe) {
          return a; // Retorna o agendamento conflitante
        }
      }
    }
    return null; // Sem conflito!
  }

  // 💡 CALCULAR PRÓXIMO HORÁRIO VAGO
  DateTime calcularProximoHorarioVago(DateTime dataBase, int duracaoMinutos) {
    DateTime horarioTeste = DateTime(dataBase.year, dataBase.month, dataBase.day, dataBase.hour, dataBase.minute);
    
    // Testa de 15 em 15 minutos até achar um slot livre
    for (int i = 0; i < 48; i++) {
      final conflito = verificarConflitoHorario(horarioTeste, duracaoMinutos);
      if (conflito == null) {
        return horarioTeste;
      }
      // Pula para o fim do atendimento que estava atrapalhando
      horarioTeste = conflito.dataHoraFim;
    }
    return horarioTeste;
  }

  // Ações da Agenda
  Future<void> criarAgendamento(Agendamento agendamento) async {
    await _agendamentoRepo.inserir(agendamento);
    await carregarTransacoes();
  }

  // Concluir Atendimento e Lançar Automaticamente no Caixa!
  Future<void> concluirAtendimentoELancarNoCaixa({
    required Agendamento agendamento,
    required String formaPagamento,
    required String categoria,
    required String tipoReceita,
  }) async {
    // 1. Atualizar status do agendamento para Concluído
    await _agendamentoRepo.atualizarStatus(agendamento.id!, 'Concluido');

    // 2. Criar a transação financeira correspondente no Caixa
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
      data: DateTime.now(),
    );

    await _repository.inserir(novaTransacao);
    await carregarTransacoes();
  }

  Future<void> cancelarAgendamento(int id) async {
    await _agendamentoRepo.atualizarStatus(id, 'Cancelado');
    await carregarTransacoes();
  }

  Future<void> excluirAgendamento(int id) async {
    await _agendamentoRepo.deletar(id);
    await carregarTransacoes();
  }

  // 📲 Compartilhar Lembrete de Agendamento no WhatsApp
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

  double get totalEntradas => transacoesFiltradas
      .where((t) => t.tipo == 'entrada' && t.status == 'Pago')
      .fold(0.0, (acc, t) => acc + t.valor);

  double get totalSaidas => transacoesFiltradas
      .where((t) => t.tipo == 'saida' && t.status == 'Pago')
      .fold(0.0, (acc, t) => acc + t.valor);

  double get saldoAtual => totalEntradas - totalSaidas;

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
      totalEntradas: totalEntradas,
      totalSaidas: totalSaidas,
      saldo: saldoAtual,
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
