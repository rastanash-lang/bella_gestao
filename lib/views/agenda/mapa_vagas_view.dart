import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../controllers/financeiro_controller.dart';
import '../../core/theme/app_theme.dart';
import 'novo_agendamento_view.dart';

class MapaVagasView extends StatelessWidget {
  const MapaVagasView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<FinanceiroController>();
    final dia = controller.diaSelecionadoAgenda;
    final dateFormat = DateFormat('EEEE, dd/MM/yyyy', 'pt_BR');
    final timeFormat = DateFormat('HH:mm');

    final gradeSlots = controller.obterGradeVagasDoDia(dia);
    final totalVagasLivres = gradeSlots.where((s) => !s.ocupado).length;
    final totalVagasOcupadas = gradeSlots.where((s) => s.ocupado).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mapa de Horários & Vagas'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Resumo do Dia
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(dateFormat.format(dia).toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(10)),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(children: [Icon(Icons.check_circle, color: Colors.green, size: 16), SizedBox(width: 4), Text('Vagas Livres', style: TextStyle(color: Colors.green, fontSize: 11))]),
                              const SizedBox(height: 4),
                              Text('${(totalVagasLivres * 0.5).toStringAsFixed(1)} horas', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(10)),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(children: [Icon(Icons.cancel, color: Colors.red, size: 16), SizedBox(width: 4), Text('Ocupado', style: TextStyle(color: Colors.red, fontSize: 11))]),
                              const SizedBox(height: 4),
                              Text('${(totalVagasOcupadas * 0.5).toStringAsFixed(1)} horas', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.red)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          const Text('Toque em um horário VERDE para agendar:', style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),

          // Grade de Horários (Tabela)
          ...gradeSlots.map((slot) {
            final isOcupado = slot.ocupado;

            return Card(
              margin: const EdgeInsets.only(bottom: 6),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: isOcupado ? Colors.red.shade300 : Colors.green.shade300, width: 1.5),
              ),
              color: isOcupado ? Colors.red.shade50 : Colors.green.shade50,
              child: ListTile(
                onTap: isOcupado
                    ? null
                    : () {
                        // Tocar no bloco verde abre o agendamento já com esse horário!
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
                    color: isOcupado ? Colors.red : Colors.green,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    timeFormat.format(slot.inicio),
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
                title: Text(
                  isOcupado ? '🔒 ${slot.agendamento!.cliente}' : '🟩 HORÁRIO DISPONÍVEL',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: isOcupado ? Colors.red.shade900 : Colors.green.shade900,
                  ),
                ),
                subtitle: Text(
                  isOcupado ? 'Procedimento: ${slot.agendamento!.servico} (${slot.agendamento!.duracaoMinutos} min)' : 'Toque para agendar cliente neste horário',
                  style: TextStyle(fontSize: 11, color: isOcupado ? Colors.black87 : Colors.green.shade700),
                ),
                trailing: Icon(
                  isOcupado ? Icons.lock : Icons.add_circle,
                  color: isOcupado ? Colors.red : Colors.green,
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
