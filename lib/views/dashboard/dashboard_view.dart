import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../controllers/financeiro_controller.dart';
import '../../core/theme/app_theme.dart';
import '../formulario/novo_lancamento_view.dart';
import '../relatorios/painel_mei_view.dart';

class DashboardView extends StatelessWidget {
  const DashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<FinanceiroController>();
    final currency = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    final dateFormat = DateFormat('dd/MM HH:mm');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bella Gestão'),
        actions: [
          IconButton(
            icon: const Icon(Icons.pie_chart_outline),
            tooltip: 'Painel MEI',
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PainelMeiView())),
          ),
          IconButton(
            icon: const Icon(Icons.backup_outlined),
            tooltip: 'Backup',
            onPressed: () => controller.exportarBackupJSON(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => controller.carregarTransacoes(),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => controller.alternarAmbito('PJ'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: controller.ambitoAtual == 'PJ' ? AppTheme.primary : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '🏢 SALÃO (PJ)',
                          style: TextStyle(
                            color: controller.ambitoAtual == 'PJ' ? Colors.white : Colors.black87,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => controller.alternarAmbito('PF'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: controller.ambitoAtual == 'PF' ? AppTheme.primary : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '🏠 PESSOAL (PF)',
                          style: TextStyle(
                            color: controller.ambitoAtual == 'PF' ? Colors.white : Colors.black87,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Text('Saldo em Caixa (${controller.ambitoAtual})', style: const TextStyle(color: Colors.grey)),
                    const SizedBox(height: 4),
                    Text(
                      currency.format(controller.saldoAtual),
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: controller.saldoAtual >= 0 ? AppTheme.verdeEntrada : AppTheme.carmimSaida,
                      ),
                    ),
                    const Divider(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Column(
                          children: [
                            const Text('Entradas', style: TextStyle(color: Colors.grey)),
                            Text(currency.format(controller.totalEntradas), style: const TextStyle(color: AppTheme.verdeEntrada, fontWeight: FontWeight.bold, fontSize: 16)),
                          ],
                        ),
                        Column(
                          children: [
                            const Text('Saídas', style: TextStyle(color: Colors.grey)),
                            Text(currency.format(controller.totalSaidas), style: const TextStyle(color: AppTheme.carmimSaida, fontWeight: FontWeight.bold, fontSize: 16)),
                          ],
                        ),
                      ],
                    )
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Lançamentos (${controller.transacoesFiltradas.length})', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const Text('Arraste para excluir ➔', style: TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
            const SizedBox(height: 8),
            if (controller.transacoesFiltradas.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Center(child: Text('Nenhum lançamento registrado nesta conta.', style: TextStyle(color: Colors.grey))),
              )
            else
              ...controller.transacoesFiltradas.map((t) {
                final isEntrada = t.tipo == 'entrada';
                final isPago = t.status == 'Pago';

                return Dismissible(
                  key: Key(t.id.toString()),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(12)),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  onDismissed: (_) => controller.removerTransacao(t.id!),
                  child: Card(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: (isEntrada ? AppTheme.verdeEntrada : AppTheme.carmimSaida).withOpacity(0.15),
                        child: Icon(
                          isEntrada ? Icons.arrow_downward : Icons.arrow_upward,
                          color: isEntrada ? AppTheme.verdeEntrada : AppTheme.carmimSaida,
                        ),
                      ),
                      title: Text(t.descricao, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text('${t.categoria} • ${t.formaPagamento}\n${dateFormat.format(t.data)}', style: const TextStyle(fontSize: 12)),
                      isThreeLine: true,
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${isEntrada ? '+' : '-'} ${currency.format(t.valor)}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: isEntrada ? AppTheme.verdeEntrada : AppTheme.carmimSaida,
                            ),
                          ),
                          const SizedBox(height: 4),
                          GestureDetector(
                            onTap: () => controller.alternarStatus(t),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: isPago ? Colors.green.shade50 : Colors.amber.shade50,
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: isPago ? Colors.green : Colors.amber),
                              ),
                              child: Text(
                                isPago ? '✓ Pago' : '⏳ Pendente',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: isPago ? Colors.green.shade800 : Colors.amber.shade900,
                                ),
                              ),
                            ),
                          )
                        ],
                      ),
                    ),
                  ),
                );
              }),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NovoLancamentoView())),
        icon: const Icon(Icons.add),
        label: const Text('NOVO LANÇAMENTO'),
      ),
    );
  }
}
