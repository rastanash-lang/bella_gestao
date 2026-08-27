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
    final totalSaidas = controller.totalSaidas == 0 ? 1.0 : controller.totalSaidas;

    return Scaffold(
      appBar: AppBar(title: const Text('Relatórios e Custos')),
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
                  const Text('Resultado Financeiro Operacional', style: TextStyle(color: Colors.grey, fontSize: 14)),
                  const SizedBox(height: 6),
                  Text(
                    currency.format(controller.saldoAtual),
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      color: controller.saldoAtual >= 0 ? AppTheme.verdeEntrada : AppTheme.carmimSaida,
                    ),
                  ),
                  const Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Entradas: ${currency.format(controller.totalEntradas)}', style: const TextStyle(color: AppTheme.verdeEntrada)),
                      Text('Saídas: ${currency.format(controller.totalSaidas)}', style: const TextStyle(color: AppTheme.carmimSaida)),
                    ],
                  ),
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
                  const Text('Classificação dos Custos (Saídas)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  _buildBar('Custos Fixos (Aluguel, Água, Luz)', controller.totalCustosFixos, controller.totalCustosFixos / totalSaidas, Colors.blue, currency),
                  const SizedBox(height: 12),
                  _buildBar('Custos Variáveis (Produtos, Insumos)', controller.totalCustosVariaveis, controller.totalCustosVariaveis / totalSaidas, Colors.amber.shade700, currency),
                  const SizedBox(height: 12),
                  _buildBar('Emergências / Imprevistos', controller.totalCustosEmergencia, controller.totalCustosEmergencia / totalSaidas, Colors.red, currency),
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
                  const Text('Meios de Pagamento & Taxas Estimadas', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  ListTile(
                    dense: true,
                    leading: const Icon(Icons.credit_card, color: Colors.blue),
                    title: const Text('Cartão de Débito'),
                    subtitle: const Text('Estimativa de taxa: ~1.99%'),
                    trailing: Text(currency.format(controller.totalRecebidoDebito), style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  ListTile(
                    dense: true,
                    leading: const Icon(Icons.credit_score, color: Colors.purple),
                    title: const Text('Cartão de Crédito'),
                    subtitle: const Text('Estimativa de taxa: ~3.99%'),
                    trailing: Text(currency.format(controller.totalRecebidoCredito), style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.pie_chart, color: Colors.deepOrange),
                    title: const Text('Estimativa Total de Taxas Pagas', style: TextStyle(fontWeight: FontWeight.bold)),
                    trailing: Text(currency.format(controller.estimativaTaxasCartao), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.deepOrange, fontSize: 16)),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            icon: const Icon(Icons.table_chart),
            label: const Text('EXPORTAR PLANILHA CSV'),
            onPressed: () => controller.exportarRelatorioCSV(),
          )
        ],
      ),
    );
  }

  Widget _buildBar(String label, double valor, double percentual, Color cor, NumberFormat currency) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
            Text('${currency.format(valor)} (${(percentual * 100).toStringAsFixed(1)}%)', style: TextStyle(fontWeight: FontWeight.bold, color: cor)),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(value: percentual.clamp(0.0, 1.0), minHeight: 8, color: cor, backgroundColor: Colors.grey.shade200),
        ),
      ],
    );
  }
}
