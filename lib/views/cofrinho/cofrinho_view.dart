import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../controllers/financeiro_controller.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/cofrinho_model.dart';

class CofrinhoView extends StatelessWidget {
  const CofrinhoView({super.key});

  void _abrirModalNovaMeta(BuildContext context) {
    final tituloCtrl = TextEditingController();
    final valorCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(children: [Icon(Icons.savings, color: Colors.pink), SizedBox(width: 8), Text('Nova Meta / Cofrinho')]),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: tituloCtrl,
              decoration: const InputDecoration(labelText: 'Objetivo (Ex: Secador Novo, Reforma)', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: valorCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Valor Alvo (R\$)', prefixText: 'R\$ ', border: OutlineInputBorder()),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.pink, foregroundColor: Colors.white),
            onPressed: () {
              final titulo = tituloCtrl.text.trim();
              final valor = double.tryParse(valorCtrl.text.replaceAll(',', '.')) ?? 0.0;
              if (titulo.isNotEmpty && valor > 0) {
                context.read<FinanceiroController>().criarCofrinho(titulo, valor);
                Navigator.pop(ctx);
              }
            },
            child: const Text('Criar Meta'),
          ),
        ],
      ),
    );
  }

  void _abrirModalMovimentar(BuildContext context, MetaCofrinho meta, bool isAdicao) {
    final valorCtrl = TextEditingController();
    final controller = context.read<FinanceiroController>();
    final currency = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    final saldoDisponivel = controller.saldoDisponivelCaixaPJ;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(isAdicao ? Icons.savings : Icons.account_balance_wallet, color: isAdicao ? Colors.pink : Colors.orange),
            const SizedBox(width: 8),
            Text(isAdicao ? 'Guardar no Cofrinho' : 'Resgatar Dinheiro'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Meta: ${meta.titulo}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 12),

            // EXIBIÇÃO DO SALDO DISPONÍVEL NO CAIXA EM TEMPO REAL
            if (isAdicao) ...[
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: saldoDisponivel > 0 ? Colors.green.shade50 : Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: saldoDisponivel > 0 ? Colors.green.shade200 : Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    Icon(saldoDisponivel > 0 ? Icons.check_circle_outline : Icons.warning_amber_rounded,
                        color: saldoDisponivel > 0 ? Colors.green : Colors.red, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Saldo disponível no Caixa (Salão):', style: TextStyle(fontSize: 10, color: Colors.black54)),
                          Text(
                            currency.format(saldoDisponivel),
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: saldoDisponivel > 0 ? Colors.green.shade800 : Colors.red.shade800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ] else ...[
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: Colors.blue, size: 18),
                    const SizedBox(width: 8),
                    Text('Guardado nesta meta: ${currency.format(meta.valorAtual)}',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blue)),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],

            TextField(
              controller: valorCtrl,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: isAdicao ? 'Valor a Guardar (R\$)' : 'Valor a Resgatar (R\$)',
                prefixText: 'R\$ ',
                border: const OutlineInputBorder(),
              ),
            ),
            if (isAdicao)
              const Padding(
                padding: EdgeInsets.only(top: 6),
                child: Text('💡 Este valor sairá do caixa do salão para a reserva.',
                    style: TextStyle(fontSize: 10, color: Colors.grey)),
              ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: isAdicao ? Colors.pink : Colors.orange,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              final valor = double.tryParse(valorCtrl.text.replaceAll(',', '.')) ?? 0.0;

              if (valor <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Informe um valor maior que zero.'), backgroundColor: Colors.red),
                );
                return;
              }

              // VALIDAÇÃO LOCAL NO MODAL: Bloqueia se tentar guardar acima do saldo em mãos
              if (isAdicao && valor > saldoDisponivel) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('❌ Saldo insuficiente! Você só possui ${currency.format(saldoDisponivel)} disponível no caixa.'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              // VALIDAÇÃO NO RESGATE: Não pode resgatar mais do que tem no cofrinho
              if (!isAdicao && valor > meta.valorAtual) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('❌ Você só tem ${currency.format(meta.valorAtual)} guardado nesta meta.'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              final sucesso = await controller.movimentarCofrinho(
                id: meta.id!,
                valorAtual: meta.valorAtual,
                valorMovimentado: valor,
                isAdicao: isAdicao,
              );

              if (context.mounted) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(sucesso
                        ? (isAdicao
                            ? '✅ ${currency.format(valor)} guardados! Valor retirado do caixa.'
                            : '✅ ${currency.format(valor)} resgatados e devolvidos ao caixa!')
                        : '❌ Falha ao movimentar cofrinho.'),
                    backgroundColor: sucesso ? Colors.green : Colors.red,
                  ),
                );
              }
            },
            child: Text(isAdicao ? 'Confirmar Depósito' : 'Confirmar Resgate'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<FinanceiroController>();
    final currency = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    final cofrinhos = controller.cofrinhos;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cofrinho / Metas do Salão'),
        actions: [
          // 👁️ BOTÃO DO OLHINHO NO TOPO PARA OCULTAR/MOSTRAR VALOR DO COFRINHO
          IconButton(
            icon: Icon(controller.ocultarSaldo ? Icons.visibility_off : Icons.visibility),
            tooltip: 'Ocultar / Mostrar Saldo',
            onPressed: () => controller.toggleOcultarSaldo(),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // CARD COM O TOTAL GUARDADO E BOTÃO DE OLHINHO DENTRO
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            color: Colors.pink.shade50,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => controller.toggleOcultarSaldo(),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    const CircleAvatar(
                      radius: 28,
                      backgroundColor: Colors.pink,
                      child: Icon(Icons.savings, color: Colors.white, size: 30),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Total Guardado em Metas', style: TextStyle(color: Colors.black54, fontSize: 13)),
                              Icon(controller.ocultarSaldo ? Icons.visibility_off : Icons.visibility,
                                  size: 18, color: Colors.pink.shade400),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            controller.ocultarSaldo ? 'R\$ ••••••' : currency.format(controller.totalGuardadoCofrinhos),
                            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.pink),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Minhas Metas', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Text('${cofrinhos.length} meta(s)', style: const TextStyle(color: Colors.grey, fontSize: 13)),
            ],
          ),
          const SizedBox(height: 10),

          if (cofrinhos.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 60),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.savings_outlined, size: 54, color: Colors.grey),
                    SizedBox(height: 8),
                    Text('Você ainda não tem nenhum cofrinho criado.\nCrie metas para guardar dinheiro para o salão!', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
                  ],
                ),
              ),
            )
          else
            ...cofrinhos.map((meta) {
              final pct = meta.percentual;
              final concluida = meta.concluida;

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(concluida ? Icons.check_circle : Icons.flag, color: concluida ? Colors.green : Colors.pink, size: 20),
                              const SizedBox(width: 8),
                              Text(meta.titulo, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, size: 20, color: Colors.grey),
                            onPressed: () => controller.excluirCofrinho(meta.id!),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            controller.ocultarSaldo ? 'Guardado: ••••••' : 'Guardado: ${currency.format(meta.valorAtual)}',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          Text('Meta: ${currency.format(meta.valorAlvo)}', style: const TextStyle(color: Colors.grey, fontSize: 13)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: pct,
                          minHeight: 10,
                          color: concluida ? Colors.green : Colors.pink,
                          backgroundColor: Colors.grey.shade200,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        concluida ? '🎉 Meta 100% Atingida!' : '${(pct * 100).toStringAsFixed(0)}% concluído • Restam ${currency.format(meta.restante)}',
                        style: TextStyle(fontSize: 12, color: concluida ? Colors.green : Colors.black54, fontWeight: FontWeight.bold),
                      ),
                      const Divider(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              icon: const Icon(Icons.remove, size: 16),
                              label: const Text('Resgatar'),
                              onPressed: () => _abrirModalMovimentar(context, meta, false),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.pink, foregroundColor: Colors.white),
                              icon: const Icon(Icons.add, size: 16),
                              label: const Text('Guardar'),
                              onPressed: () => _abrirModalMovimentar(context, meta, true),
                            ),
                          ),
                        ],
                      )
                    ],
                  ),
                ),
              );
            }),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.pink,
        foregroundColor: Colors.white,
        onPressed: () => _abrirModalNovaMeta(context),
        icon: const Icon(Icons.add),
        label: const Text('NOVA META'),
      ),
    );
  }
}
