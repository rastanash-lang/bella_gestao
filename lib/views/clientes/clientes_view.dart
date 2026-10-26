import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../controllers/financeiro_controller.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/cliente_model.dart';
import 'novo_cliente_view.dart';

class ClientesView extends StatefulWidget {
  const ClientesView({super.key});

  @override
  State<ClientesView> createState() => _ClientesViewState();
}

class _ClientesViewState extends State<ClientesView> {
  String _filtroTexto = '';

  void _abrirHistorico360(BuildContext context, Cliente cliente) {
    final controller = context.read<FinanceiroController>();
    final currency = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    final dateFormat = DateFormat('dd/MM/yyyy');
    final timeFormat = DateFormat('HH:mm');

    final historicoFinanceiro = controller.obterHistoricoFinanceiroCliente(cliente.nome);
    final historicoAgendamentos = controller.obterHistoricoAgendamentosCliente(cliente.nome);
    final totalGasto = controller.totalGastoCliente(cliente.nome);
    final totalPendente = controller.totalPendenteCliente(cliente.nome);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.8,
        maxChildSize: 0.95,
        builder: (_, scrollCtrl) => Padding(
          padding: const EdgeInsets.all(16),
          child: ListView(
            controller: scrollCtrl,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: AppTheme.primary,
                    child: Text(
                      cliente.nome.isNotEmpty ? cliente.nome[0].toUpperCase() : '?',
                      style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(cliente.nome, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        if (cliente.telefone != null)
                          Text('📞 ${cliente.telefone!}', style: const TextStyle(color: Colors.grey, fontSize: 13)),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.blue),
                    tooltip: 'Editar / Corrigir',
                    onPressed: () {
                      Navigator.pop(ctx);
                      Navigator.push(context, MaterialPageRoute(builder: (_) => NovoClienteView(clienteParaEditar: cliente)));
                    },
                  )
                ],
              ),
              const SizedBox(height: 16),

              // FICHA TÉCNICA / FÓRMULAS EM DESTAQUE
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.amber.shade300),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.content_cut, color: Colors.amber, size: 18),
                        SizedBox(width: 6),
                        Text('Ficha Técnica & Preferências do Salão:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      cliente.observacoesTecnicas != null && cliente.observacoesTecnicas!.isNotEmpty
                          ? cliente.observacoesTecnicas!
                          : 'Nenhuma observação técnica registrada ainda. Toque em Editar para registrar fórmulas de coloração ou preferências.',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade800),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // CARDS DE RESUMO FINANCEIRO
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(12)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Total Gasto no Salão', style: TextStyle(fontSize: 11, color: Colors.green)),
                          const SizedBox(height: 2),
                          Text(currency.format(totalGasto), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green)),
                        ],
                      ),
                    ),
                  ),
                  if (totalPendente > 0) ...[
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
                            Text(currency.format(totalPendente), style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.amber.shade900)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const Divider(height: 28),

              // AGENDAMENTOS RECENTES OU FUTUROS
              const Text('Agendamentos na Agenda:', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              if (historicoAgendamentos.isEmpty)
                const Text('Nenhum agendamento marcado na agenda.', style: TextStyle(fontSize: 12, color: Colors.grey))
              else
                ...historicoAgendamentos.take(5).map((a) {
                  return Card(
                    margin: const EdgeInsets.only(bottom: 6),
                    child: ListTile(
                      leading: const Icon(Icons.calendar_today, size: 20, color: Colors.blue),
                      title: Text(a.servico, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      subtitle: Text('${dateFormat.format(a.dataHoraInicio)} às ${timeFormat.format(a.dataHoraInicio)} (${a.status})'),
                      trailing: Text(currency.format(a.valor), style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.verdeEntrada)),
                    ),
                  );
                }),
              const SizedBox(height: 16),

              // HISTÓRICO COMPLETO DE SERVIÇOS PRESTADOS
              const Text('Serviços Anteriores (Histórico do Salão):', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              if (historicoFinanceiro.isEmpty)
                const Text('Nenhum serviço anterior registrado.', style: TextStyle(fontSize: 12, color: Colors.grey))
              else
                ...historicoFinanceiro.map((t) {
                  final isPago = t.status == 'Pago';
                  return Card(
                    margin: const EdgeInsets.only(bottom: 6),
                    child: ListTile(
                      leading: Icon(Icons.check_circle, size: 20, color: isPago ? Colors.green : Colors.orange),
                      title: Text(t.descricao, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      subtitle: Text('${dateFormat.format(t.data)} • ${t.formaPagamento}'),
                      trailing: Text(currency.format(t.valor), style: TextStyle(fontWeight: FontWeight.bold, color: isPago ? AppTheme.verdeEntrada : Colors.orange.shade800)),
                    ),
                  );
                }),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmarExclusao(BuildContext context, Cliente c) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir Cliente?'),
        content: Text('Deseja remover "${c.nome}" da lista oficial de clientes? O histórico passado de serviços não será apagado.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          TextButton(
            onPressed: () {
              context.read<FinanceiroController>().excluirCliente(c.id!);
              Navigator.pop(ctx);
            },
            child: const Text('Excluir', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<FinanceiroController>();
    final currency = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    final clientes = controller.clientes.where((c) {
      final matchNome = c.nome.toLowerCase().contains(_filtroTexto.toLowerCase());
      final matchTel = c.telefone != null && c.telefone!.contains(_filtroTexto);
      return matchNome || matchTel;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Minhas Clientes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add),
            tooltip: 'Novo Cliente',
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NovoClienteView())),
          )
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // BOTÃO MÁGICO: IMPORTAR CLIENTES DO HISTÓRICO PASSADO
          Card(
            elevation: 0,
            color: Colors.blue.shade50,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: BorderSide(color: Colors.blue.shade200)),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(
                children: [
                  const Icon(Icons.sync, color: Colors.blue),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Importar Clientes Antigos', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.blue)),
                        Text('Cadastre com 1 toque os nomes que já foram atendidos no início do ano.', style: TextStyle(fontSize: 10, color: Colors.black54)),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.blue.shade700, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 10)),
                    onPressed: () async {
                      final qtd = await controller.importarClientesAntigos();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(qtd > 0 ? '✅ $qtd clientes antigos importados com sucesso!' : '💡 Todos os clientes antigos já estão na lista!'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    },
                    child: const Text('Importar', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // BARRA DE BUSCA
          TextField(
            onChanged: (val) => setState(() => _filtroTexto = val),
            decoration: InputDecoration(
              hintText: 'Buscar por nome ou telefone...',
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 14),

          if (clientes.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Center(
                child: Column(
                  children: [
                    const Icon(Icons.people_outline, size: 54, color: Colors.grey),
                    const SizedBox(height: 8),
                    const Text('Nenhum cliente cadastrado ainda.', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.add),
                      label: const Text('Cadastrar Primeiro Cliente'),
                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NovoClienteView())),
                    )
                  ],
                ),
              ),
            )
          else
            ...clientes.map((c) {
              final totalGasto = controller.totalGastoCliente(c.nome);
              final totalPendente = controller.totalPendenteCliente(c.nome);

              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                child: ListTile(
                  onTap: () => _abrirHistorico360(context, c),
                  leading: CircleAvatar(
                    backgroundColor: AppTheme.primary.withOpacity(0.1),
                    child: Text(
                      c.nome.isNotEmpty ? c.nome[0].toUpperCase() : '?',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primary),
                    ),
                  ),
                  title: Text(c.nome, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(
                    c.telefone != null && c.telefone!.isNotEmpty
                        ? '📞 ${c.telefone!} • ${currency.format(totalGasto)}'
                        : 'Total investido: ${currency.format(totalGasto)}',
                    style: const TextStyle(fontSize: 12),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (c.telefone != null && c.telefone!.isNotEmpty)
                        IconButton(
                          icon: const Icon(Icons.chat, color: Color(0xFF25D366), size: 20),
                          tooltip: 'Enviar WhatsApp',
                          onPressed: () {
                            Share.share('Olá ${c.nome}! Entramos em contato pelo Salão de Beleza.');
                          },
                        ),
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue, size: 20),
                        tooltip: 'Editar / Corrigir',
                        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => NovoClienteView(clienteParaEditar: c))),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                        tooltip: 'Excluir',
                        onPressed: () => _confirmarExclusao(context, c),
                      ),
                    ],
                  ),
                ),
              );
            }),
          const SizedBox(height: 40),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NovoClienteView())),
      ),
    );
  }
}
