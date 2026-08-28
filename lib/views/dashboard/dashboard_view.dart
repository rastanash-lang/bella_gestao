import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../controllers/financeiro_controller.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/transacao_model.dart';
import '../formulario/novo_lancamento_view.dart';
import '../cofrinho/cofrinho_view.dart';
import '../relatorios/relatorios_view.dart';

class DashboardView extends StatelessWidget {
  const DashboardView({super.key});

  String _formatarMesAno(DateTime data) {
    const meses = ['Janeiro', 'Fevereiro', 'Março', 'Abril', 'Maio', 'Junho', 'Julho', 'Agosto', 'Setembro', 'Outubro', 'Novembro', 'Dezembro'];
    return '${meses[data.month - 1]} ${data.year}'.toUpperCase();
  }

  void _exibirOpcoesTransacao(BuildContext context, Transacao t) {
    final controller = context.read<FinanceiroController>();

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 16),
              Text(t.descricao, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              if (t.cliente != null && t.cliente!.isNotEmpty)
                Text('Cliente: ${t.cliente}', style: const TextStyle(color: Colors.grey, fontSize: 13)),
              const Divider(height: 24),
              if (t.tipo == 'entrada')
                ListTile(
                  leading: const CircleAvatar(backgroundColor: Color(0xFF25D366), child: Icon(Icons.receipt_long, color: Colors.white)),
                  title: const Text('Enviar Recibo no WhatsApp', style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: const Text('Gera comprovante formatado em 1 toque'),
                  onTap: () {
                    Navigator.pop(ctx);
                    controller.compartilharReciboWhatsApp(t);
                  },
                ),
              ListTile(
                leading: const CircleAvatar(backgroundColor: Colors.blue, child: Icon(Icons.edit, color: Colors.white)),
                title: const Text('Editar Lançamento'),
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => NovoLancamentoView(transacaoParaEditar: t)));
                },
              ),
              ListTile(
                leading: const CircleAvatar(backgroundColor: Colors.red, child: Icon(Icons.delete, color: Colors.white)),
                title: const Text('Excluir Lançamento', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(ctx);
                  controller.removerTransacao(t.id!);
                },
              ),
            ],
          ),
        ),
      ),
    );
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

            // Card Saldo
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

            // ATALHOS RÁPIDOS ESTILO BANCÁRIO (Imagem de Referência)
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CofrinhoView())),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                      decoration: BoxDecoration(color: Colors.pink.shade50, borderRadius: BorderRadius.circular(12)),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.savings, color: Colors.pink, size: 20),
                          SizedBox(width: 6),
                          Text('Cofrinho', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.pink, fontSize: 13)),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RelatoriosView())),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                      decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(12)),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.analytics, color: Colors.blue, size: 20),
                          SizedBox(width: 6),
                          Text('Finanças', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue, fontSize: 13)),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
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

            // Busca
            TextField(
              onChanged: (val) => controller.buscar(val),
              decoration: InputDecoration(
                hintText: 'Buscar por cliente, serviço...',
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

            // Extrato
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
                        grupo.key,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.grey),
                      ),
                    ),
                    ...grupo.value.map((t) {
                      final isEntrada = t.tipo == 'entrada';
                      final isPago = t.status == 'Pago';

                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: ListTile(
                          onTap: () => _exibirOpcoesTransacao(context, t),
                          leading: CircleAvatar(
                            backgroundColor: (isEntrada ? AppTheme.verdeEntrada : Colors.grey.shade400).withOpacity(0.15),
                            child: Icon(
                              isEntrada ? Icons.arrow_downward : Icons.arrow_upward,
                              color: isEntrada ? AppTheme.verdeEntrada : Colors.grey.shade700,
                            ),
                          ),
                          title: Text(t.descricao, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(
                            '${t.cliente != null && t.cliente!.isNotEmpty ? "👤 ${t.cliente}\n" : ""}${t.categoria} • ${t.formaPagamento}${t.totalParcelas > 1 ? ' (${t.parcelaAtual}/${t.totalParcelas}x)' : ''}',
                            style: const TextStyle(fontSize: 12),
                          ),
                          isThreeLine: t.cliente != null && t.cliente!.isNotEmpty,
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (isEntrada)
                                IconButton(
                                  icon: const Icon(Icons.receipt_long, color: Color(0xFF25D366), size: 26),
                                  tooltip: 'Enviar Recibo WhatsApp',
                                  onPressed: () => controller.compartilharReciboWhatsApp(t),
                                ),
                              Column(
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
                            ],
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
