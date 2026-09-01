import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../controllers/financeiro_controller.dart';
import 'novo_agendamento_view.dart';

class MapaVagasView extends StatefulWidget {
  const MapaVagasView({super.key});

  @override
  State<MapaVagasView> createState() => _MapaVagasViewState();
}

class _MapaVagasViewState extends State<MapaVagasView> {
  late DateTime _diaSelecionado;

  @override
  void initState() {
    super.initState();
    _diaSelecionado = context.read<FinanceiroController>().diaSelecionadoAgenda;
  }

  Future<void> _abrirCalendario() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _diaSelecionado,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (picked != null) {
      setState(() => _diaSelecionado = picked);
      context.read<FinanceiroController>().selecionarDiaAgenda(picked);
    }
  }

  void _mudarDia(int dias) {
    setState(() {
      _diaSelecionado = _diaSelecionado.add(Duration(days: dias));
    });
    context.read<FinanceiroController>().selecionarDiaAgenda(_diaSelecionado);
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<FinanceiroController>();
    final dateFormat = DateFormat('EEEE, dd/MM/yyyy', 'pt_BR');
    final timeFormat = DateFormat('HH:mm');

    final gradeSlots = controller.obterGradeVagasDoDia(_diaSelecionado);

    final totalVagasLivresFuturas = gradeSlots.where((s) => !s.ocupado && !s.passado).length;
    final totalVagasOcupadas = gradeSlots.where((s) => s.ocupado).length;

    final hoje = DateTime.now();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mapa de Vagas & Horários'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month),
            tooltip: 'Escolher Data / Mês',
            onPressed: _abrirCalendario,
          )
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Navegador de Dias
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.chevron_left),
                        tooltip: 'Dia Anterior',
                        onPressed: () => _mudarDia(-1),
                      ),
                      GestureDetector(
                        onTap: _abrirCalendario,
                        child: Column(
                          children: [
                            Text(
                              dateFormat.format(_diaSelecionado).toUpperCase(),
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                            const Text('Toque para escolher outro dia ou mês 📅', style: TextStyle(fontSize: 10, color: Colors.blue)),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.chevron_right),
                        tooltip: 'Próximo Dia',
                        onPressed: () => _mudarDia(1),
                      ),
                    ],
                  ),
                  const Divider(height: 12),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ActionChip(
                          label: const Text('Hoje'),
                          onPressed: () {
                            setState(() => _diaSelecionado = DateTime(hoje.year, hoje.month, hoje.day));
                            controller.selecionarDiaAgenda(_diaSelecionado);
                          },
                        ),
                        const SizedBox(width: 6),
                        ActionChip(
                          label: const Text('Amanhã'),
                          onPressed: () {
                            setState(() => _diaSelecionado = DateTime(hoje.year, hoje.month, hoje.day + 1));
                            controller.selecionarDiaAgenda(_diaSelecionado);
                          },
                        ),
                        const SizedBox(width: 6),
                        ActionChip(
                          label: const Text('+7 dias (Próx. Semana)'),
                          onPressed: () => _mudarDia(7),
                        ),
                        const SizedBox(width: 6),
                        ActionChip(
                          avatar: const Icon(Icons.date_range, size: 16),
                          label: const Text('Outro Mês...'),
                          onPressed: _abrirCalendario,
                        ),
                      ],
                    ),
                  )
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Resumo de Horas
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(12)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(children: [Icon(Icons.check_circle, color: Colors.green, size: 16), SizedBox(width: 4), Text('Vagas Disponíveis', style: TextStyle(color: Colors.green, fontSize: 11, fontWeight: FontWeight.bold))]),
                      const SizedBox(height: 4),
                      Text('${(totalVagasLivresFuturas * 0.5).toStringAsFixed(1)} horas livres', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.green)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(12)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(children: [Icon(Icons.lock, color: Colors.red, size: 16), SizedBox(width: 4), Text('Ocupado', style: TextStyle(color: Colors.red, fontSize: 11, fontWeight: FontWeight.bold))]),
                      const SizedBox(height: 4),
                      Text('${(totalVagasOcupadas * 0.5).toStringAsFixed(1)} horas ocupadas', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.red)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          const Text('Horários do dia:', style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),

          // Grade de Horários
          ...gradeSlots.map((slot) {
            final isOcupado = slot.ocupado;
            final isPassado = slot.passado && !isOcupado;

            Color corBorda = Colors.green.shade300;
            Color corFundo = Colors.green.shade50;
            Color corBadge = Colors.green;
            String textoTitulo = '🟩 HORÁRIO DISPONÍVEL';
            String textoSubtitulo = 'Toque para agendar cliente neste horário';
            IconData icone = Icons.add_circle;

            if (isOcupado) {
              corBorda = Colors.red.shade300;
              corFundo = Colors.red.shade50;
              corBadge = Colors.red;
              textoTitulo = '🔒 ${slot.agendamento!.cliente}';
              textoSubtitulo = 'Procedimento: ${slot.agendamento!.servico} (${slot.agendamento!.duracaoMinutos} min)';
              icone = Icons.lock;
            } else if (isPassado) {
              corBorda = Colors.grey.shade300;
              corFundo = Colors.grey.shade100;
              corBadge = Colors.grey.shade600;
              textoTitulo = '⏳ HORÁRIO ENCERRADO';
              textoSubtitulo = 'Este horário já passou no dia de hoje';
              icone = Icons.history;
            }

            return Card(
              margin: const EdgeInsets.only(bottom: 6),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: corBorda, width: 1.5),
              ),
              color: corFundo,
              child: ListTile(
                onTap: (isOcupado || isPassado)
                    ? null
                    : () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => NovoAgendamentoView(dataInicial: slot.inicio),
                          ),
                        );
                      },
                leading: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: corBadge,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    timeFormat.format(slot.inicio),
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
                title: Text(
                  textoTitulo,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: isOcupado ? Colors.red.shade900 : (isPassado ? Colors.grey.shade700 : Colors.green.shade900),
                  ),
                ),
                subtitle: Text(
                  textoSubtitulo,
                  style: TextStyle(fontSize: 11, color: isOcupado ? Colors.black87 : (isPassado ? Colors.grey.shade600 : Colors.green.shade700)),
                ),
                trailing: Icon(
                  icone,
                  color: corBadge,
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
