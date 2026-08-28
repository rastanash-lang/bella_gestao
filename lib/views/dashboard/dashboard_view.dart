import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../controllers/financeiro_controller.dart';
import '../../core/theme/app_theme.dart';
import '../formulario/novo_lancamento_view.dart';

class DashboardView extends StatelessWidget {
  const DashboardView({super.key});

  String _formatarMesAno(DateTime data) {
    const meses = ['Janeiro', 'Fevereiro', 'Março', 'Abril', 'Maio', 'Junho', 'Julho', 'Agosto', 'Setembro', 'Outubro', 'Novembro', 'Dezembro'];
    return '${meses[data.month - 1]} ${data.year}'.toUpperCase();
  }

  void _exibirDialogoRestaurar(BuildContext context) {
    final controller = context.read<FinanceiroController>();
    final textoCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Restaurar Backup'),
        content: TextField(
          controller: textoCtrl,
          maxLines: 5,
          decoration: const InputDecoration(hintText: 'Cole o JSON do backup aqui...', border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              final ok = await controller.restaurarBackupJSON(textoCtrl.text.trim());
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(ok ? '✅ Backup restaurado!' : '❌ Erro ao restaurar JSON.'),
                backgroundColor: ok ? Colors.green : Colors.red,
              ));
            },
            child: const Text('Restaurar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<FinanceiroController>();
    final currency = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    final gruposPorDia = controller.transacoesAgrupadasPorDia;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bella Gestão'),
        actions: [
          IconButton(
            icon: Icon(controller.ocultarSaldo ? Icons.visibility_off : Icons.visibility),
            tooltip: 'Ocultar / Mostrar Saldo',
            onPressed: () => controller.toggleOcultarSaldo(),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (val) {
              if (val == 'csv') controller.exportarRelatorioCSV();
              if (val == 'backup') controller.exportarBackupJSON();
              if (val == 'restaurar') _exibirDialogoRestaurar(context);
            },
            itemBuilder: (ctx) => const [
              PopupMenuItem(value: 'csv', child: Row(children: [Icon(Icons.table_chart, color: Colors.blue), SizedBox(width: 8), Text('Exportar Planilha CSV')])),
              PopupMenuItem(value: 'backup', child: Row(children: [Icon(Icons.download, color: Colors.green), SizedBox(width: 8), Text('Gerar Backup JSON')])),
              PopupMenuItem(value: 'restaurar', child: Row(children: [Icon(Icons.upload, color: Colors.orange), SizedBox(width: 8), Text('Restaurar Backup')])),
            ],
          )
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => controller.carregarTransacoes(),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Toggle PJ / PF
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(12)),
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
                        child: Text('🏢 SALÃO (PJ)', style: TextStyle(color: controller.ambitoAtual == 'PJ' ? Colors.white : Colors.black87, fontWeight: FontWeight.bold)),
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
                        child: Text('🏠 PESSOAL (PF)', style: TextStyle(color: controller.ambitoAtual == 'PF' ? Colors.white : Colors.black87, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Card Estilo Bancário com Saldo e Olhinho (Imagem 2)
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Saldo em Conta (${controller.ambitoAtual})', style: const TextStyle(color: Colors.grey, fontSize: 13)),
                        GestureDetector(
                          onTap: () => controller.toggleOcultarSaldo(),
                          child: Icon(controller.ocultarSaldo ? Icons.visibility_off : Icons.visibility, size: 20, color: Colors.grey),
                        )
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      controller.ocultarSaldo ? 'R\$ ••••••' : currency.format(controller.saldoAtual),
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: controller.saldoAtual >= 0 ? AppTheme.verdeEntrada : AppTheme.carmimSaida,
                      ),
                    ),
                    const Divider(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.arrow_downward, color: AppTheme.verdeEntrada, size: 16),
                            const SizedBox(width: 4),
                            Text(
                              controller.ocultarSaldo ? '••••' : currency.format(controller.totalEntradas),
                              style: const TextStyle(color: AppTheme.verdeEntrada, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            const Icon(Icons.arrow_upward, color: AppTheme.carmimSaida, size: 16),
                            const SizedBox(width: 4),
                            Text(
                              controller.ocultarSaldo ? '••••' : currency.format(controller.totalSaidas),
                              style: const TextStyle(color: AppTheme.carmimSaida, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ],
                    )
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Seletor de Mês
            Card(
              elevation: 0,
              color: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(icon: const Icon(Icons.chevron_left), onPressed: controller.filtrarPorMes ? () => controller.mesAnterior() : null),
                    GestureDetector(
                      onTap: () => controller.toggleFiltroMes(),
                      child: Row(
                        children: [
                          Icon(controller.filtrarPorMes ? Icons.calendar_month : Icons.all_inclusive, size: 18, color: AppTheme.primary),
                          const SizedBox(width: 6),
                          Text(
                            controller.filtrarPorMes ? _formatarMesAno(controller.mesSelecionado) : 'TODOS OS MESES',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                    IconButton(icon: const Icon(Icons.chevron_right), onPressed: controller.filtrarPorMes ? () => controller.proximoMes() : null),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Busca e Filtros (Entradas / Saídas / Todas)
            TextField(
              onChanged: (val) => controller.buscar(val),
              decoration: InputDecoration(
                hintText: 'Buscar lançamento...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 8),

            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: ['Todos', 'Entradas', 'Saídas'].map((tipo) {
                  final selecionado = controller.filtroTipo == tipo;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(tipo),
                      selected: selecionado,
                      onSelected: (_) => controller.filtrarTipo(tipo),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),

            // Extrato Agrupado por Dia (Imagem 2)
            if (gruposPorDia.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Center(child: Text('Nenhuma movimentação neste período.', style: TextStyle(color: Colors.grey))),
              )
            else
              ...gruposPorDia.entries.map((grupo) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                      child: Text(
                        grupo.key, // Ex: "26 AGO"
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.grey),
                      ),
                    ),
                    ...grupo.value.map((t) {
                      final isEntrada = t.tipo == 'entrada';
                      final isPago = t.status == 'Pago';

                      return Dismissible(
                        key: Key(t.id.toString()),
                        direction: DismissDirection.endToStart,
                        confirmDismiss: (direction) async {
                          return await showDialog(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Excluir Lançamento?'),
                              content: Text('Deseja apagar "${t.descricao}"?'),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
                                TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Excluir', style: TextStyle(color: Colors.red))),
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
                              backgroundColor: (isEntrada ? AppTheme.verdeEntrada : Colors.grey.shade400).withOpacity(0.15),
                              child: Icon(
                                isEntrada ? Icons.arrow_downward : Icons.arrow_upward,
                                color: isEntrada ? AppTheme.verdeEntrada : Colors.grey.shade700,
                              ),
                            ),
                            title: Text(t.descricao, style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text(
                              '${t.categoria} • ${t.formaPagamento}${t.totalParcelas > 1 ? ' (${t.parcelaAtual}/${t.totalParcelas}x)' : ''}',
                              style: const TextStyle(fontSize: 12),
                            ),
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  controller.ocultarSaldo ? '••••' : '${isEntrada ? '' : '- '}${currency.format(t.valor)}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                    color: isEntrada ? AppTheme.verdeEntrada : Colors.black87,
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
                                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isPago ? Colors.green.shade800 : Colors.amber.shade900),
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
                );
              }),
            const SizedBox(height: 80),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: const CircleBorder(),
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NovoLancamentoView())),
        child: const Icon(Icons.add, size: 30),
      ),
    );
  }
}
