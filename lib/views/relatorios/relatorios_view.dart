import 'dart:math';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../controllers/financeiro_controller.dart';
import '../../core/theme/app_theme.dart';

class RelatoriosView extends StatelessWidget {
  const RelatoriosView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<FinanceiroController>();
    final currency = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    final comparativo = controller.comparativoUltimosMeses;

    double maxValor = 1.0;
    for (final mes in comparativo) {
      maxValor = max(maxValor, max(mes.entradas, mes.saidas));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Minhas finanças'),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            tooltip: 'Exportar PDF',
            onPressed: () => controller.exportarRelatorioPDF(),
          )
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Controle as entradas e saídas de sua conta e acompanhe o balanço mensal.', style: TextStyle(color: Colors.grey, fontSize: 13)),
          const SizedBox(height: 16),

          // Gráfico de Barras
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  SizedBox(
                    height: 180,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: comparativo.map((m) {
                        final altEntrada = (m.entradas / maxValor) * 120;
                        final altSaida = (m.saidas / maxValor) * 120;

                        return Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Container(width: 24, height: max(altEntrada, 6.0), decoration: BoxDecoration(color: AppTheme.verdeEntrada, borderRadius: BorderRadius.circular(4))),
                                const SizedBox(width: 4),
                                Container(width: 24, height: max(altSaida, 6.0), decoration: BoxDecoration(color: AppTheme.carmimSaida, borderRadius: BorderRadius.circular(4))),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(m.label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.black87)),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                  const Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(children: [
                        Container(width: 10, height: 10, decoration: const BoxDecoration(color: AppTheme.verdeEntrada, shape: BoxShape.circle)),
                        const SizedBox(width: 6),
                        const Text('Entradas', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      ]),
                      const SizedBox(width: 24),
                      Row(children: [
                        Container(width: 10, height: 10, decoration: const BoxDecoration(color: AppTheme.carmimSaida, shape: BoxShape.circle)),
                        const SizedBox(width: 6),
                        const Text('Saídas', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      ]),
                    ],
                  )
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Lista de Balanço
          const Text('Balanço por mês', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),

          ...comparativo.reversed.map((m) {
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.analytics_outlined, size: 18, color: Colors.black54),
                            const SizedBox(width: 6),
                            Text(m.nomeMes, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${m.saldo >= 0 ? '+ ' : '- '}${currency.format(m.saldo.abs())}',
                          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: m.saldo >= 0 ? AppTheme.verdeEntrada : AppTheme.carmimSaida),
                        ),
                        const SizedBox(height: 4),
                        Text('Entradas: ${currency.format(m.entradas)}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                        Text('Saídas: ${currency.format(m.saidas)}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                    const Icon(Icons.chevron_right, color: Colors.blue),
                  ],
                ),
              ),
            );
          }),

          const SizedBox(height: 16),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blueGrey.shade900, foregroundColor: Colors.white),
            icon: const Icon(Icons.picture_as_pdf),
            label: const Text('GERAR RELATÓRIO COMPLETO EM PDF'),
            onPressed: () => controller.exportarRelatorioPDF(),
          ),
        ],
      ),
    );
  }
}
