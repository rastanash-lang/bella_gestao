import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../controllers/financeiro_controller.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/agendamento_model.dart';
import 'novo_agendamento_view.dart';
import 'mapa_vagas_view.dart';

class AgendaView extends StatelessWidget {
  const AgendaView({super.key});

  void _abrirModalConcluir(BuildContext context, Agendamento a) {
    String formaPgto = 'Pix';
    String categoria = 'Cabelo/Corte/Química';
    String tipoReceita = 'Serviço';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => AlertDialog(
          title: const Text('Concluir & Lançar no Caixa'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Cliente: ${a.cliente}', style: const TextStyle(fontWeight: FontWeight.bold)),
              Text('Serviço: ${a.servico}'),
              Text('Valor: R\$ ${a.valor.toStringAsFixed(2)}', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
              const Divider(height: 20),
              DropdownButtonFormField<String>(
                value: formaPgto,
                decoration: const InputDecoration(labelText: 'Forma de Pagamento', border: OutlineInputBorder()),
                items: ['Pix', 'Dinheiro', 'Débito', 'Crédito'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                onChanged: (v) => setModalState(() => formaPgto = v!),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: tipoReceita,
                decoration: const InputDecoration(labelText: 'Tipo de Receita MEI', border: OutlineInputBorder()),
                items: ['Serviço', 'Produto'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                onChanged: (v) => setModalState(() => tipoReceita = v!),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.verdeEntrada, foregroundColor: Colors.white),
              onPressed: () {
                context.read<FinanceiroController>().concluirAtendimentoELancarNoCaixa(
                  agendamento: a,
                  formaPagamento: formaPgto,
                  categoria: categoria,
                  tipoReceita: tipoReceita,
                );
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('✅ Atendimento concluído e lançado no Caixa!'), backgroundColor: Colors.green),
                );
              },
              child: const Text('Confirmar e Lançar'),
            ),
          ],
        ),
      ),
    );
  }

  // ⚠️ CONFIRMAÇÃO ANTES DE CANCELAR
  void _confirmarCancelamento(BuildContext context, Agendamento a) {
    final controller = context.read<FinanceiroController>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange),
            SizedBox(width: 8),
            Text('Cancelar Horário?'),
          ],
        ),
        content: Text('Deseja realmente cancelar o agendamento de "${a.cliente}" (${a.servico})?\n\nA vaga será liberada no mapa de horários.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Não, Voltar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () {
              controller.alternarCancelamentoAgendamento(a);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Agendamento cancelado. Vaga liberada!'), backgroundColor: Colors.orange),
              );
            },
            child: const Text('Sim, Cancelar'),
          ),
        ],
      ),
    );
  }

  // 🗑️ CONFIRMAÇÃO ANTES DE EXCLUIR DEFINITIVAMENTE
  void _confirmarExclusao(BuildContext context, Agendamento a) {
    final controller = context.read<FinanceiroController>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir Agendamento?'),
        content: Text('Deseja apagar permanentemente o registro de "${a.cliente}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          TextButton(
            onPressed: () {
              controller.excluirAgendamento(a.id!);
              Navigator.pop(ctx);
            },
            child: const Text('Excluir', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<FinanceiroController>();
    final currency = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    final dateFormat = DateFormat('EEEE, dd/MM/yyyy', 'pt_BR');
    final timeFormat = DateFormat('HH:mm');
    final diaAtual = controller.diaSelecionadoAgenda;
    final agendamentos = controller.agendamentosDoDia;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Agenda do Salão'),
        actions: [
          IconButton(
            icon: const Icon(Icons.grid_view),
            tooltip: 'Mapa de Vagas',
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MapaVagasView())),
          )
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Navegação de Dias
          Card(
            elevation: 1,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left),
                    onPressed: () => controller.selecionarDiaAgenda(diaAtual.subtract(const Duration(days: 1))),
                  ),
                  GestureDetector(
                    onTap: () async {
                      final p = await showDatePicker(context: context, initialDate: diaAtual, firstDate: DateTime(2020), lastDate: DateTime(2035));
                      if (p != null) controller.selecionarDiaAgenda(p);
                    },
                    child: Column(
                      children: [
                        Text(dateFormat.format(diaAtual).toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        const Text('Toque para mudar de dia 📅', style: TextStyle(fontSize: 10, color: Colors.grey)),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right),
                    onPressed: () => controller.selecionarDiaAgenda(diaAtual.add(const Duration(days: 1))),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Botão Mapa de Vagas
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade700,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            icon: const Icon(Icons.grid_view),
            label: const Text('VER MAPA DE VAGAS & HORÁRIOS LIVRES', style: TextStyle(fontWeight: FontWeight.bold)),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MapaVagasView())),
          ),
          const SizedBox(height: 16),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Atendimentos (${agendamentos.length})', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              if (agendamentos.isNotEmpty)
                Text(
                  'Próximo vago: ${timeFormat.format(controller.calcularProximoHorarioVago(DateTime(diaAtual.year, diaAtual.month, diaAtual.day, 8, 0), 60))}',
                  style: const TextStyle(fontSize: 11, color: Colors.blue, fontWeight: FontWeight.bold),
                ),
            ],
          ),
          const SizedBox(height: 10),

          if (agendamentos.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Center(
                child: Column(
                  children: [
                    const Icon(Icons.event_available, size: 54, color: Colors.green),
                    const SizedBox(height: 10),
                    const Text('Nenhum atendimento neste dia.', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.green)),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.add),
                      label: const Text('Agendar Primeiro Horário'),
                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => NovoAgendamentoView(dataInicial: diaAtual))),
                    )
                  ],
                ),
              ),
            )
          else
            ...agendamentos.map((a) {
              final isConcluido = a.status == 'Concluido';
              final isCancelado = a.status == 'Cancelado';
              final isAtivo = !isConcluido && !isCancelado;

              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: isConcluido ? Colors.green.shade400 : (isCancelado ? Colors.red.shade300 : Colors.blue.shade300),
                    width: 1.5,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: isConcluido ? Colors.green.shade50 : (isCancelado ? Colors.red.shade50 : Colors.blue.shade50),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '⏰ ${timeFormat.format(a.dataHoraInicio)} às ${timeFormat.format(a.dataHoraFim)} (${a.duracaoMinutos} min)',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                                color: isConcluido ? Colors.green.shade900 : (isCancelado ? Colors.red : Colors.blue.shade900),
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: isConcluido ? Colors.green.shade100 : (isCancelado ? Colors.red.shade100 : Colors.amber.shade100),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              isConcluido ? '✓ CONCLUÍDO' : a.status.toUpperCase(),
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: isConcluido ? Colors.green.shade900 : (isCancelado ? Colors.red.shade900 : Colors.amber.shade900),
                              ),
                            ),
                          )
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(a.cliente, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      Text('Procedimento: ${a.servico}', style: const TextStyle(color: Colors.black87, fontSize: 13)),
                      Text('Valor: ${currency.format(a.valor)}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.verdeEntrada, fontSize: 14)),
                      if (a.observacoes != null) Text('Obs: ${a.observacoes}', style: const TextStyle(fontSize: 11, color: Colors.grey)),

                      // Ajuste rápido de horário (+15m / -15m) -> SÓ APARECE SE NÃO ESTIVER CONCLUÍDO
                      if (isAtivo) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Text('Ajuste rápido:', style: TextStyle(fontSize: 11, color: Colors.grey)),
                            const SizedBox(width: 8),
                            ActionChip(
                              label: const Text('-15 min', style: TextStyle(fontSize: 11)),
                              onPressed: () => controller.ajustarHorarioAgendamento(a, -15),
                            ),
                            const SizedBox(width: 6),
                            ActionChip(
                              label: const Text('+15 min', style: TextStyle(fontSize: 11)),
                              onPressed: () => controller.ajustarHorarioAgendamento(a, 15),
                            ),
                          ],
                        ),
                      ],

                      const Divider(height: 18),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Lembrete WhatsApp
                          IconButton(
                            icon: const Icon(Icons.share, color: Color(0xFF25D366)),
                            tooltip: 'Lembrete no WhatsApp',
                            onPressed: () => controller.compartilharLembreteAgendamentoWhatsApp(a),
                          ),

                          // Editar (Só se não estiver concluído)
                          if (isAtivo)
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              tooltip: 'Editar Agendamento',
                              onPressed: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => NovoAgendamentoView(
                                    dataInicial: a.dataHoraInicio,
                                    agendamentoParaEditar: a,
                                  ),
                                ),
                              ),
                            ),

                          // Cancelar (Com Confirmação e NÃO APARECE se concluído)
                          if (isAtivo)
                            IconButton(
                              icon: const Icon(Icons.cancel_outlined, color: Colors.redAccent),
                              tooltip: 'Cancelar Horário',
                              onPressed: () => _confirmarCancelamento(context, a),
                            ),

                          // Reativar (Caso já esteja cancelado)
                          if (isCancelado)
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white),
                              icon: const Icon(Icons.restore, size: 16),
                              label: const Text('Reativar'),
                              onPressed: () => controller.alternarCancelamentoAgendamento(a),
                            ),

                          // Concluir e Lançar no Caixa (Só se estiver ativo)
                          if (isAtivo)
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.verdeEntrada, foregroundColor: Colors.white),
                              icon: const Icon(Icons.check, size: 16),
                              label: const Text('Concluir'),
                              onPressed: () => _abrirModalConcluir(context, a),
                            ),

                          // Excluir Definitivamente (Com Confirmação)
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.grey),
                            tooltip: 'Excluir Definitivamente',
                            onPressed: () => _confirmarExclusao(context, a),
                          ),
                        ],
                      )
                    ],
                  ),
                ),
              );
            }),
          const SizedBox(height: 80),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => NovoAgendamentoView(dataInicial: diaAtual))),
        child: const Icon(Icons.add, size: 28),
      ),
    );
  }
}
