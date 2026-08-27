import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../controllers/financeiro_controller.dart';
import '../../core/theme/app_theme.dart';
import '../formulario/novo_lancamento_view.dart';

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
            icon: const Icon(Icons.file_download_outlined),
            tooltip: 'Exportar CSV',
            onPressed: () => controller.exportarRelatorioCSV(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => controller.carregarTransacoes(),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // RF-01: Toggle Switch PJ / PF
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

            // Card de Saldo
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
            const SizedBox(height: 16),

            // RF-02: Barra de Pesquisa
            TextField(
              onChanged: (val) => controller.buscar(val),
              decoration: InputDecoration(
                hintText: 'Buscar por cliente, serviço ou produto...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 10),

            // RF-02: Filtros por Status (Todos / Pagos / Pendentes)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: ['Todos', 'Pago', 'Pendente'].map((st) {
                  final selecionado = controller.filtroStatus == st;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(st == 'Todos' ? 'Todos' : (st == 'Pago' ? 'Concluídos' : 'Pendentes')),
                      selected: selecionado,
                      onSelected: (_) => controller.filtrarStatus(st),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),

            // Cabeçalho da Lista
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Lançamentos (${controller.transacoesFiltradas.length})', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const Text('Toque p/ editar • Deslize p/ apagar', style: TextStyle(fontSize: 11, color: Colors.grey)),
              ],
            ),
            const SizedBox(height: 8),

            // Lista de Movimentações
            if (controller.transacoesFiltradas.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Center(child: Text('Nenhum lançamento encontrado.', style: TextStyle(color: Colors.grey))),
              )
            else
              ...controller.transacoesFiltradas.map((t) {
                final isEntrada = t.tipo == 'entrada';
                final isPago = t.status == 'Pago';

                return Dismissible(
                  key: Key(t.id.toString()),
                  direction: DismissDirection.endToStart,
                  // RF-02: Confirmação antes de remover
                  confirmDismiss: (direction) async {
                    return await showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Excluir Lançamento?'),
                        content: Text('Deseja realmente apagar "${t.descricao}"?'),
                        actions: [
                          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancelar')),
                          TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Excluir', style: TextStyle(color: Colors.red))),
                        ],
                      ),
                    );
                  },
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
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => NovoLancamentoView(transacaoParaEditar: t))),
                      leading: CircleAvatar(
                        backgroundColor: (isEntrada ? AppTheme.verdeEntrada : AppTheme.carmimSaida).withOpacity(0.15),
                        child: Icon(
                          isEntrada ? Icons.arrow_downward : Icons.arrow_upward,
                          color: isEntrada ? AppTheme.verdeEntrada : AppTheme.carmimSaida,
                        ),
                      ),
                      title: Text(t.descricao, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(
                        '${t.categoria}${t.tipoCusto != null ? ' • ${t.tipoCusto}' : ''} • ${t.formaPagamento}\n${dateFormat.format(t.data)}',
                        style: const TextStyle(fontSize: 12),
                      ),
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
                          // RF-02: Baixa rápida com 1 toque
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
        label: const Text('Lançar'),
      ),
    );
  }
}
