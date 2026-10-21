import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../controllers/financeiro_controller.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/transacao_model.dart';
import '../formulario/novo_lancamento_view.dart';
import '../cofrinho/cofrinho_view.dart';
import '../estoque/estoque_view.dart';

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
              if (t.tipo == 'entrada' && t.categoria != 'Saldo Histórico / Início de Uso')
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

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.settings_backup_restore, color: Colors.blue),
            SizedBox(width: 8),
            Text('Restaurar Backup'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Escolha o arquivo (.json) da sua pasta de Downloads ou Documentos do celular:',
              style: TextStyle(fontSize: 13, color: Colors.black87),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.folder_open),
              label: const Text('SELECIONAR ARQUIVO NO CELULAR', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              onPressed: () async {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Abrindo pastas do celular...'), duration: Duration(seconds: 1)),
                );

                final sucesso = await controller.selecionarERestaurarBackupArquivo();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(sucesso ? '✅ Backup restaurado com sucesso!' : '❌ Nenhum arquivo selecionado ou inválido.'),
                      backgroundColor: sucesso ? Colors.green : Colors.red,
                    ),
                  );
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Voltar'),
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
    final isPJ = controller.ambitoAtual == 'PJ';

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
              PopupMenuItem(value: 'restaurar', child: Row(children: [Icon(Icons.upload, color: Colors.orange), SizedBox(width: 8), Text('Restaurar Backup do Celular')])),
            ],
          )
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => controller.carregarTransacoes(),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // TOGGLE LIMPO: SALÃO (PJ) OU PESSOAL (PF)
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(14)),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => controller.alternarAmbito('PJ'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: isPJ ? AppTheme.primary : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        alignment: Alignment.center,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.storefront, size: 16, color: isPJ ? Colors.white : Colors.black87),
                            const SizedBox(width: 6),
                            Text('SALÃO (PJ)', style: TextStyle(color: isPJ ? Colors.white : Colors.black87, fontWeight: FontWeight.bold, fontSize: 13)),
                          ],
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
                          color: !isPJ ? Colors.purple.shade700 : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        alignment: Alignment.center,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.person, size: 16, color: !isPJ ? Colors.white : Colors.black87),
                            const SizedBox(width: 6),
                            Text('PESSOAL (PF)', style: TextStyle(color: !isPJ ? Colors.white : Colors.black87, fontWeight: FontWeight.bold, fontSize: 13)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // CARD PRINCIPAL: SALDO TOTAL + GRADE DE BALANÇO ESPAÇOSA
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          isPJ ? 'Saldo em Caixa (Dinheiro em Mãos)' : 'Saldo Pessoal (Montantes - Gastos)',
                          style: const TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                        GestureDetector(
                          onTap: () => controller.toggleOcultarSaldo(),
                          child: Icon(controller.ocultarSaldo ? Icons.visibility_off : Icons.visibility, size: 20, color: Colors.grey),
                        )
                      ],
                    ),
                    const SizedBox(height: 8),

                    Text(
                      controller.ocultarSaldo ? 'R\$ ••••••' : currency.format(controller.saldoGeralAcumulado),
                      style: TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.bold,
                        color: controller.saldoGeralAcumulado >= 0
                            ? (isPJ ? AppTheme.verdeEntrada : Colors.purple.shade700)
                            : AppTheme.carmimSaida,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Divider(height: 1),
                    const SizedBox(height: 16),

                    if (isPJ) ...[
                      // SEÇÃO SALÃO (PJ): GRADE 2x2
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(12)),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Row(children: [Icon(Icons.arrow_downward, color: Colors.green, size: 14), SizedBox(width: 4), Text('Receita do Mês', style: TextStyle(color: Colors.green, fontSize: 11, fontWeight: FontWeight.bold))]),
                                  const SizedBox(height: 6),
                                  Text(controller.ocultarSaldo ? '••••' : currency.format(controller.totalEntradasMes), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.green)),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(12)),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Row(children: [Icon(Icons.arrow_upward, color: Colors.red, size: 14), SizedBox(width: 4), Text('Despesas Salão', style: TextStyle(color: Colors.red, fontSize: 11, fontWeight: FontWeight.bold))]),
                                  const SizedBox(height: 6),
                                  Text(controller.ocultarSaldo ? '••••' : '- ${currency.format(controller.totalSaidasMes)}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.red)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(color: Colors.purple.shade50, borderRadius: BorderRadius.circular(12)),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Row(children: [Icon(Icons.person_outline, color: Colors.purple, size: 14), SizedBox(width: 4), Text('Gastos Pessoais', style: TextStyle(color: Colors.purple, fontSize: 11, fontWeight: FontWeight.bold))]),
                                  const SizedBox(height: 6),
                                  Text(controller.ocultarSaldo ? '••••' : '- ${currency.format(controller.totalGastosPessoaisMes)}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.purple)),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(12)),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(children: [Icon(Icons.wallet, color: Colors.blue.shade800, size: 14), const SizedBox(width: 4), Text('Sobra do Mês', style: TextStyle(color: Colors.blue.shade900, fontSize: 11, fontWeight: FontWeight.bold))]),
                                  const SizedBox(height: 6),
                                  Text(
                                    controller.ocultarSaldo ? '••••' : currency.format(controller.saldoSaladoAposGastosPessoaisMes),
                                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: controller.saldoSaladoAposGastosPessoaisMes >= 0 ? AppTheme.verdeEntrada : AppTheme.carmimSaida),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ] else ...[
                      // SEÇÃO PESSOAL (PF): GRADE DE ENTRADAS/MONTANTES E GASTOS PESSOAIS
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(color: Colors.purple.shade50, borderRadius: BorderRadius.circular(12)),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Row(children: [Icon(Icons.arrow_downward, color: Colors.purple, size: 14), SizedBox(width: 4), Text('Montantes / Renda', style: TextStyle(color: Colors.purple, fontSize: 11, fontWeight: FontWeight.bold))]),
                                  const SizedBox(height: 6),
                                  Text(controller.ocultarSaldo ? '••••' : currency.format(controller.totalEntradasMes), style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.purple.shade800)),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(12)),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Row(children: [Icon(Icons.arrow_upward, color: Colors.red, size: 14), SizedBox(width: 4), Text('Gastos Pessoais', style: TextStyle(color: Colors.red, fontSize: 11, fontWeight: FontWeight.bold))]),
                                  const SizedBox(height: 6),
                                  Text(controller.ocultarSaldo ? '••••' : '- ${currency.format(controller.totalSaidasMes)}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.red)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ATALHOS RÁPIDOS
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CofrinhoView())),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: Colors.pink.shade50,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.pink.shade100),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.savings, color: Colors.pink, size: 22),
                          SizedBox(width: 8),
                          Text('Cofrinho / Metas', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.pink, fontSize: 13)),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EstoqueView())),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.orange.shade100),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.inventory_2, color: Colors.orange, size: 22),
                          SizedBox(width: 8),
                          Text('Estoque Insumos', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange, fontSize: 13)),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // SELETOR DE MÊS
            Card(
              elevation: 0,
              color: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
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

            // BUSCA
            TextField(
              onChanged: (val) => controller.buscar(val),
              decoration: InputDecoration(
                hintText: isPJ ? 'Buscar lançamentos do salão...' : 'Buscar lançamentos pessoais...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 16),

            // EXTRATO
            if (gruposPorDia.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: Center(
                  child: Text(
                    isPJ ? 'Nenhuma movimentação do salão neste período.' : 'Nenhuma movimentação pessoal neste período.',
                    style: const TextStyle(color: Colors.grey),
                  ),
                ),
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
                      final isHistorico = t.categoria == 'Saldo Histórico / Início de Uso';

                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                          side: isHistorico
                              ? BorderSide(color: Colors.amber.shade400, width: 1.2)
                              : BorderSide.none,
                        ),
                        child: ListTile(
                          onTap: () => _exibirOpcoesTransacao(context, t),
                          leading: CircleAvatar(
                            backgroundColor: isHistorico
                                ? Colors.amber.shade100
                                : (isPJ
                                    ? (isEntrada ? AppTheme.verdeEntrada : Colors.grey.shade400).withOpacity(0.15)
                                    : (isEntrada ? Colors.purple.shade100 : Colors.purple.withOpacity(0.15))),
                            child: Icon(
                              isHistorico
                                  ? Icons.history
                                  : (isPJ
                                      ? (isEntrada ? Icons.arrow_downward : Icons.arrow_upward)
                                      : (isEntrada ? Icons.arrow_downward : Icons.shopping_bag_outlined)),
                              color: isHistorico
                                  ? Colors.amber.shade900
                                  : (isPJ
                                      ? (isEntrada ? AppTheme.verdeEntrada : Colors.grey.shade700)
                                      : Colors.purple.shade700),
                            ),
                          ),
                          title: Row(
                            children: [
                              Expanded(
                                child: Text(t.descricao, style: const TextStyle(fontWeight: FontWeight.bold)),
                              ),
                              if (isHistorico)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(color: Colors.amber.shade100, borderRadius: BorderRadius.circular(4)),
                                  child: const Text('HISTÓRICO', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.amber)),
                                ),
                            ],
                          ),
                          subtitle: Text(
                            '${t.cliente != null && t.cliente!.isNotEmpty ? "👤 ${t.cliente}\n" : ""}${t.categoria} • ${t.formaPagamento}${t.totalParcelas > 1 ? ' (${t.parcelaAtual}/${t.totalParcelas}x)' : ''}',
                            style: const TextStyle(fontSize: 12),
                          ),
                          isThreeLine: t.cliente != null && t.cliente!.isNotEmpty,
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (isEntrada && isPJ && !isHistorico)
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
                                      color: isHistorico
                                          ? (isEntrada ? AppTheme.verdeEntrada : AppTheme.carmimSaida)
                                          : (isPJ ? (isEntrada ? AppTheme.verdeEntrada : Colors.black87) : (isEntrada ? Colors.purple.shade700 : Colors.red.shade700)),
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
        backgroundColor: isPJ ? AppTheme.primary : Colors.purple.shade700,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: const CircleBorder(),
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NovoLancamentoView())),
        child: const Icon(Icons.add, size: 30),
      ),
    );
  }
}
