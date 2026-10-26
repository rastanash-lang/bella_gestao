import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/financeiro_controller.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/cliente_model.dart';

class NovoClienteView extends StatefulWidget {
  final Cliente? clienteParaEditar;

  const NovoClienteView({super.key, this.clienteParaEditar});

  @override
  State<NovoClienteView> createState() => _NovoClienteViewState();
}

class _NovoClienteViewState extends State<NovoClienteView> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nomeCtrl;
  late TextEditingController _telefoneCtrl;
  late TextEditingController _obsCtrl;
  bool _atualizarEmCascata = true;

  @override
  void initState() {
    super.initState();
    final c = widget.clienteParaEditar;
    _nomeCtrl = TextEditingController(text: c?.nome ?? '');
    _telefoneCtrl = TextEditingController(text: c?.telefone ?? '');
    _obsCtrl = TextEditingController(text: c?.observacoesTecnicas ?? '');
  }

  @override
  void dispose() {
    _nomeCtrl.dispose();
    _telefoneCtrl.dispose();
    _obsCtrl.dispose();
    super.dispose();
  }

  void _salvar() {
    if (_formKey.currentState!.validate()) {
      final controller = context.read<FinanceiroController>();
      final editando = widget.clienteParaEditar != null;
      final nomeAntigo = widget.clienteParaEditar?.nome;

      final cliente = Cliente(
        id: widget.clienteParaEditar?.id,
        nome: _nomeCtrl.text.trim(),
        telefone: _telefoneCtrl.text.trim().isNotEmpty ? _telefoneCtrl.text.trim() : null,
        observacoesTecnicas: _obsCtrl.text.trim().isNotEmpty ? _obsCtrl.text.trim() : null,
        dataCadastro: widget.clienteParaEditar?.dataCadastro ?? DateTime.now(),
      );

      if (editando) {
        controller.atualizarCliente(
          cliente,
          atualizarEmCascata: _atualizarEmCascata,
          nomeAntigo: nomeAntigo,
        );
      } else {
        controller.criarCliente(cliente);
      }

      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(editando ? '✅ Cadastro de cliente atualizado!' : '✅ Cliente cadastrado com sucesso!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final editando = widget.clienteParaEditar != null;

    return Scaffold(
      appBar: AppBar(title: Text(editando ? 'Editar / Corrigir Cliente' : 'Novo Cliente')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nomeCtrl,
              autofocus: !editando,
              decoration: InputDecoration(
                labelText: 'Nome Completo da Cliente',
                prefixIcon: const Icon(Icons.person),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Informe o nome' : null,
            ),
            const SizedBox(height: 14),

            TextFormField(
              controller: _telefoneCtrl,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: 'WhatsApp / Telefone (Opcional)',
                prefixIcon: const Icon(Icons.phone),
                hintText: 'Ex: (11) 99999-9999',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 14),

            TextFormField(
              controller: _obsCtrl,
              maxLines: 4,
              decoration: InputDecoration(
                labelText: 'Ficha Técnica / Preferências do Salão',
                hintText: 'Ex: Fórmulas de coloração (Tinta 7.1 + 20vol), alergias a produtos, estilo de corte...',
                prefixIcon: const Icon(Icons.content_cut),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 14),

            if (editando) ...[
              Card(
                color: Colors.blue.shade50,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: SwitchListTile(
                  title: const Text('Correção em Cascata', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  subtitle: const Text(
                    'Atualizar automaticamente todos os agendamentos e transações antigas para este novo nome.',
                    style: TextStyle(fontSize: 11),
                  ),
                  value: _atualizarEmCascata,
                  activeColor: AppTheme.primary,
                  onChanged: (v) => setState(() => _atualizarEmCascata = v),
                ),
              ),
              const SizedBox(height: 14),
            ],

            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _salvar,
              child: Text(editando ? 'SALVAR CORREÇÃO' : 'CADASTRAR CLIENTE', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}
