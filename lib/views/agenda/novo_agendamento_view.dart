import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../controllers/financeiro_controller.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/agendamento_model.dart';

class NovoAgendamentoView extends StatefulWidget {
  final DateTime dataInicial;

  const NovoAgendamentoView({super.key, required this.dataInicial});

  @override
  State<NovoAgendamentoView> createState() => _NovoAgendamentoViewState();
}

class _NovoAgendamentoViewState extends State<NovoAgendamentoView> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _clienteCtrl;
  final _servicoCtrl = TextEditingController();
  final _valorCtrl = TextEditingController();
  final _obsCtrl = TextEditingController();

  late DateTime _dataHora;
  int _duracaoMinutos = 60; // Padrão: 1 hora

  final List<int> _duracoesPredefinidas = [30, 45, 60, 90, 120, 180];

  @override
  void initState() {
    super.initState();
    _clienteCtrl = TextEditingController();
    _dataHora = widget.dataInicial;
  }

  @override
  void dispose() {
    _clienteCtrl.dispose();
    _servicoCtrl.dispose();
    _valorCtrl.dispose();
    _obsCtrl.dispose();
    super.dispose();
  }

  Future<void> _selecionarData() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dataHora,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _dataHora = DateTime(picked.year, picked.month, picked.day, _dataHora.hour, _dataHora.minute);
      });
    }
  }

  Future<void> _selecionarHora() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_dataHora),
    );
    if (picked != null) {
      setState(() {
        _dataHora = DateTime(_dataHora.year, _dataHora.month, _dataHora.day, picked.hour, picked.minute);
      });
    }
  }

  String _formatarDuracao(int min) {
    if (min < 60) return '$min min';
    final h = min ~/ 60;
    final m = min % 60;
    return m == 0 ? '${h}h' : '${h}h${m}min';
  }

  void _salvar() {
    if (_formKey.currentState!.validate()) {
      final valor = double.tryParse(_valorCtrl.text.replaceAll(',', '.')) ?? 0.0;
      final controller = context.read<FinanceiroController>();

      final conflito = controller.verificarConflitoHorario(_dataHora, _duracaoMinutos);
      if (conflito != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('⚠️ Horário ocupado por ${conflito.cliente}! Escolha outro horário.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final novo = Agendamento(
        cliente: _clienteCtrl.text.trim(),
        servico: _servicoCtrl.text.trim(),
        valor: valor,
        dataHoraInicio: _dataHora,
        duracaoMinutos: _duracaoMinutos,
        observacoes: _obsCtrl.text.trim().isNotEmpty ? _obsCtrl.text.trim() : null,
      );

      controller.criarAgendamento(novo);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<FinanceiroController>();
    final nomesSugeridos = controller.nomesClientesUnicos;
    final dateFormat = DateFormat('dd/MM/yyyy');
    final timeFormat = DateFormat('HH:mm');

    // Checagem em tempo real de conflito
    final conflito = controller.verificarConflitoHorario(_dataHora, _duracaoMinutos);
    final proximoVago = conflito != null ? controller.calcularProximoHorarioVago(_dataHora, _duracaoMinutos) : null;

    return Scaffold(
      appBar: AppBar(title: const Text('Novo Agendamento')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Alerta visual de conflito em tempo real
            if (conflito != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.red)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.warning_amber_rounded, color: Colors.red),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Horário em conflito com: ${conflito.cliente} (${timeFormat.format(conflito.dataHoraInicio)} às ${timeFormat.format(conflito.dataHoraFim)})',
                            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                    if (proximoVago != null) ...[
                      const SizedBox(height: 8),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade800, foregroundColor: Colors.white),
                        icon: const Icon(Icons.auto_fix_high, size: 16),
                        label: Text('Usar Próximo Vago (${timeFormat.format(proximoVago)})'),
                        onPressed: () => setState(() => _dataHora = proximoVago),
                      )
                    ]
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Autocomplete Cliente
            Autocomplete<String>(
              initialValue: TextEditingValue(text: _clienteCtrl.text),
              optionsBuilder: (TextEditingValue textVal) {
                if (textVal.text.isEmpty) return const Iterable<String>.empty();
                return nomesSugeridos.where((nome) => nome.toLowerCase().contains(textVal.text.toLowerCase()));
              },
              onSelected: (String selecao) => _clienteCtrl.text = selecao,
              fieldViewBuilder: (ctx, textEditingCtrl, focusNode, onFieldSubmitted) {
                _clienteCtrl = textEditingCtrl;
                return TextFormField(
                  controller: textEditingCtrl,
                  focusNode: focusNode,
                  decoration: InputDecoration(
                    labelText: 'Nome da Cliente',
                    prefixIcon: const Icon(Icons.person),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  validator: (v) => (v == null || v.isEmpty) ? 'Informe a cliente' : null,
                );
              },
            ),
            const SizedBox(height: 12),

            TextFormField(
              controller: _servicoCtrl,
              decoration: InputDecoration(
                labelText: 'Serviço / Procedimento (Ex: Mechas, Corte)',
                prefixIcon: const Icon(Icons.content_cut),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              validator: (v) => (v == null || v.isEmpty) ? 'Informe o serviço' : null,
            ),
            const SizedBox(height: 12),

            TextFormField(
              controller: _valorCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Valor Estimado (R\$)',
                prefixText: 'R\$ ',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              validator: (v) => (v == null || v.isEmpty) ? 'Informe o valor' : null,
            ),
            const SizedBox(height: 16),

            // Seleção de Data e Hora de Início
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                    icon: const Icon(Icons.calendar_today),
                    label: Text(dateFormat.format(_dataHora)),
                    onPressed: _selecionarData,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                    icon: const Icon(Icons.access_time),
                    label: Text(timeFormat.format(_dataHora)),
                    onPressed: _selecionarHora,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Seletor de Duração do Procedimento
            const Text('Duração do Procedimento:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _duracoesPredefinidas.map((dur) {
                  final selecionado = _duracaoMinutos == dur;
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: ChoiceChip(
                      label: Text(_formatarDuracao(dur)),
                      selected: selecionado,
                      onSelected: (val) => setState(() => _duracaoMinutos = dur),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Término previsto às: ${timeFormat.format(_dataHora.add(Duration(minutes: _duracaoMinutos)))}',
              style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            TextFormField(
              controller: _obsCtrl,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: 'Observações (Opcional)',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 24),

            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary, foregroundColor: Colors.white),
              onPressed: _salvar,
              child: const Text('CONFIRMAR AGENDAMENTO', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}
