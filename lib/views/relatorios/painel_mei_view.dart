import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../controllers/financeiro_controller.dart';

class PainelMeiView extends StatelessWidget {
  const PainelMeiView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<FinanceiroController>();
    final currencyFormat = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    final percentual = controller.percentualMEI;
    final total = controller.faturamentoAnualMEI;

    Color progressoCor = Colors.green;
    String alertaTexto = 'Situação Regular';

    if (percentual >= 0.95) {
      progressoCor = Colors.red.shade800;
      alertaTexto = '🚨 ALERTA CRÍTICO: 95% do teto atingido!';
    } else if (percentual >= 0.85) {
      progressoCor = Colors.red;
      alertaTexto = '⚠️ ATENÇÃO: 85% do teto atingido!';
    } else if (percentual >= 0.70) {
      progressoCor = Colors.orange;
      alertaTexto = '⚡ AVISO: 70% do teto atingido!';
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Fechamento MEI (DASN-SIMEI)')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Faturamento Acumulado (Ano Vigente)', style: TextStyle(color: Colors.grey, fontSize: 14)),
                  const SizedBox(height: 6),
                  Text(
                    controller.ocultarSaldo ? 'R\$ ••••••' : currencyFormat.format(total),
                    style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  Text('Teto Anual: ${currencyFormat.format(FinanceiroController.limiteAnualMEI)}', style: const TextStyle(color: Colors.black54)),
                  const SizedBox(height: 16),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: percentual,
                      minHeight: 14,
                      color: progressoCor,
                      backgroundColor: Colors.grey.shade200,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('${(percentual * 100).toStringAsFixed(1)}% utilizado', style: TextStyle(fontWeight: FontWeight.bold, color: progressoCor)),
                      Text('Resta: ${currencyFormat.format(FinanceiroController.limiteAnualMEI - total)}', style: const TextStyle(color: Colors.grey)),
                    ],
                  ),
                  if (percentual >= 0.70) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: progressoCor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                      child: Text(alertaTexto, style: TextStyle(color: progressoCor, fontWeight: FontWeight.bold)),
                    )
                  ]
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Discriminação para Declaração Anual', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const Divider(height: 24),
                  ListTile(
                    leading: const Icon(Icons.content_cut, color: Colors.blue),
                    title: const Text('Prestação de Serviços'),
                    trailing: Text(currencyFormat.format(controller.faturamentoServicosMEI), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                  ListTile(
                    leading: const Icon(Icons.shopping_bag, color: Colors.purple),
                    title: const Text('Venda de Mercadorias (Produtos)'),
                    trailing: Text(currencyFormat.format(controller.faturamentoProdutosMEI), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blueGrey.shade800, foregroundColor: Colors.white),
            icon: const Icon(Icons.picture_as_pdf),
            label: const Text('GERAR RELATÓRIO PDF PARA CONTABILIDADE'),
            onPressed: () => controller.exportarRelatorioPDF(),
          ),
        ],
      ),
    );
  }
}
