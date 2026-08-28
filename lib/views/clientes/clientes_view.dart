import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../controllers/financeiro_controller.dart';
import '../../core/theme/app_theme.dart';

class ClientesView extends StatefulWidget {
  const ClientesView({super.key});

  @override
  State<ClientesView> createState() => _ClientesViewState();
}

class _ClientesViewState extends State<ClientesView> {
  String _filtroTexto = '';

  void _exibirHistoricoCliente(BuildContext context, ClienteResumo cliente) {
    final currency = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    final dateFormat = DateFormat('dd/MM/yyyy');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        builder: (_, scrollCtrl) => Padding(
          padding: const EdgeInsets.all(16),
          child: ListView(
            controller: scrollCtrl,
            children: [
              Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 16),
              Row(
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: AppTheme.primary,
                    child: Text(cliente.nome.substring(0, 1).toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(cliente.nome, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      Text('${cliente.totalAtendimentos} atendimento(s) realizados', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(12)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Total Gasto', style: TextStyle(fontSize: 11, color: Colors.green)),
                          const SizedBox(height: 2),
                          Text(currency.format(cliente.totalGasto), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green)),
                        ],
                      ),
                    ),
                  ),
                  if (cliente.totalPendente > 0) ...[
                    const SizedBox(width: 8),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: Colors.amber.shade50, borderRadius: BorderRadius.circular(12)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Pendente', style: TextStyle(fontSize: 11, color: Colors.amber)),
                            const SizedBox(height: 2),
                            Text(currency.format(cliente.totalPendente), style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.amber.shade900)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const Divider(height: 28),
              const Text('Histórico de Atendimentos', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ...cliente.historico.map((t) {
                final isPago = t.status == 'Pago';
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  child: ListTile(
                    leading: Icon(Icons.content_cut, color: isPago ? AppTheme.verdeEntrada : Colors.amber.shade800),
                    title: Text(t.descricao, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    subtitle: Text('${dateFormat.format(t.data)} • ${t.formaPagamento}'),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(currency.format(t.valor), style: const TextStyle(fontWeight: FontWeight.bold)),
                        Text(isPago ? '✓ Pago' : '⏳ Pendente', style: TextStyle(fontSize: 10, color: isPago ? Colors.green : Colors.amber.shade900, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<FinanceiroController>();
    final currency = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    final dateFormat = DateFormat('dd/MM/yy');

    final clientes = controller.listaClientes.where((c) => c.nome.toLowerCase().contains(_filtroTexto.toLowerCase())).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Minhas Clientes')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            onChanged: (val) => setState(() => _filtroTexto = val),
            decoration: InputDecoration(
              hintText: 'Buscar cliente...',
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 16),
          if (clientes.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 60),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.people_outline, size: 48, color: Colors.grey),
                    SizedBox(height: 8),
                    Text('Nenhuma cliente cadastrada ainda.\nInforme o nome da cliente ao salvar um atendimento.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
                  ],
                ),
              ),
            )
          else
            ...clientes.map((c) {
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  onTap: () => _exibirHistoricoCliente(context, c),
                  leading: CircleAvatar(
                    backgroundColor: AppTheme.primary.withOpacity(0.1),
                    child: Text(c.nome.substring(0, 1).toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primary)),
                  ),
                  title: Text(c.nome, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('${c.totalAtendimentos} visita(s) • Última: ${dateFormat.format(c.ultimoAtendimento)}', style: const TextStyle(fontSize: 12)),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(currency.format(c.totalGasto), style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.verdeEntrada, fontSize: 14)),
                      if (c.totalPendente > 0)
                        Text('Pendente: ${currency.format(c.totalPendente)}', style: TextStyle(fontSize: 10, color: Colors.amber.shade900, fontWeight: FontWeight.bold))
                      else
                        const Icon(Icons.chevron_right, size: 18, color: Colors.grey),
                    ],
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }
}
