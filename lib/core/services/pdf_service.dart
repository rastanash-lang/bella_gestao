import 'dart:io';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import '../../data/models/transacao_model.dart';

class PdfService {
  static Future<void> gerarRelatorioCompletoPDF({
    required List<Transacao> transacoes,
    required String ambito,
    required double totalEntradas,
    required double totalSaidas,
    required double saldo,
    required double faturamentoServicosMEI,
    required double faturamentoProdutosMEI,
    required double totalCustosFixos,
    required double totalCustosVariaveis,
    required double totalCustosEmergencia,
    required double estimativaTaxasCartao,
    required double totalCofrinhos,
  }) async {
    final pdf = pw.Document();
    final currency = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
    final agora = DateTime.now();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('BELLA GESTAO - RELATORIO FINANCEIRO', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColors.blueGrey900)),
                  pw.Text('CONTA: $ambito', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.blueGrey700)),
                ],
              ),
              pw.Text('Emissao: ${dateFormat.format(agora)}', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
              pw.Divider(thickness: 1, color: PdfColors.grey400),
              pw.SizedBox(height: 10),
            ],
          );
        },
        build: (pw.Context context) {
          return [
            // Resumo Geral
            pw.Text('1. RESUMO EXECUTIVO DO PERIODO', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 8),
            pw.Row(
              children: [
                _buildCardPdf('Entradas Totais', currency.format(totalEntradas), PdfColors.green),
                pw.SizedBox(width: 8),
                _buildCardPdf('Saidas Totais', currency.format(totalSaidas), PdfColors.red),
                pw.SizedBox(width: 8),
                _buildCardPdf('Lucro Liquido', currency.format(saldo), saldo >= 0 ? PdfColors.green : PdfColors.red),
              ],
            ),
            pw.SizedBox(height: 16),

            // Módulo MEI
            if (ambito == 'PJ') ...[
              pw.Text('2. DECLARACAO ANUAL MEI (DASN-SIMEI)', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 8),
              pw.Container(
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(color: PdfColors.grey100, borderRadius: pw.BorderRadius.circular(6)),
                child: pw.Column(
                  children: [
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text('Receita Bruta - Prestacao de Servicos:'),
                        pw.Text(currency.format(faturamentoServicosMEI), style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      ],
                    ),
                    pw.SizedBox(height: 4),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text('Receita Bruta - Venda de Mercadorias (Produtos):'),
                        pw.Text(currency.format(faturamentoProdutosMEI), style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      ],
                    ),
                    pw.Divider(color: PdfColors.grey300),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text('Faturamento Total MEI no Periodo:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        pw.Text(currency.format(faturamentoServicosMEI + faturamentoProdutosMEI), style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.blueGrey800)),
                      ],
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 16),
            ],

            // Detalhamento de Custos
            pw.Text('3. DISCRIMINACAO DE CUSTOS & TAXAS', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 8),
            pw.Row(
              children: [
                _buildCardPdf('Custos Fixos', currency.format(totalCustosFixos), PdfColors.blue),
                pw.SizedBox(width: 8),
                _buildCardPdf('Custos Variaveis', currency.format(totalCustosVariaveis), PdfColors.orange),
                pw.SizedBox(width: 8),
                _buildCardPdf('Emergencias', currency.format(totalCustosEmergencia), PdfColors.redAccent),
              ],
            ),
            pw.SizedBox(height: 6),
            pw.Row(
              children: [
                _buildCardPdf('Taxas de Cartao Pagas (Est.)', currency.format(estimativaTaxasCartao), PdfColors.deepOrange),
                pw.SizedBox(width: 8),
                _buildCardPdf('Total em Cofrinhos / Metas', currency.format(totalCofrinhos), PdfColors.purple),
              ],
            ),
            pw.SizedBox(height: 20),

            // Tabela de Lançamentos
            pw.Text('4. HISTORICO DETALHADO DE LANCAMENTOS', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 8),
            pw.TableHelper.fromTextArray(
              headers: ['Data', 'Cliente', 'Descricao', 'Pagamento', 'Status', 'Valor'],
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9, color: PdfColors.white),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey800),
              cellStyle: const pw.TextStyle(fontSize: 8),
              cellAlignment: pw.Alignment.centerLeft,
              data: transacoes.map((t) {
                final isEntrada = t.tipo == 'entrada';
                final dataFormatada = DateFormat('dd/MM/yy').format(t.data);
                return [
                  dataFormatada,
                  t.cliente ?? '-',
                  t.descricao,
                  t.formaPagamento,
                  t.status,
                  '${isEntrada ? "+" : "-"} ${currency.format(t.valor)}',
                ];
              }).toList(),
            ),
            pw.SizedBox(height: 30),

            // Campo de Assinatura
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Container(width: 200, height: 1, color: PdfColors.black),
                    pw.SizedBox(height: 4),
                    pw.Text('Responsavel Financeiro / MEI', style: const pw.TextStyle(fontSize: 10)),
                  ],
                ),
                pw.Text('Documento emitido pelo Bella Gestao', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
              ],
            )
          ];
        },
      ),
    );

    final directory = await getTemporaryDirectory();
    final file = File('${directory.path}/relatorio_bella_gestao_${DateFormat('yyyyMMdd_HHmm').format(agora)}.pdf');
    await file.writeAsBytes(await pdf.save());

    await Share.shareXFiles([XFile(file.path)], text: 'Relatório Financeiro PDF - Bella Gestão');
  }

  static pw.Widget _buildCardPdf(String label, String valor, PdfColor cor) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.all(8),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: cor, width: 1),
          borderRadius: pw.BorderRadius.circular(6),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(label, style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
            pw.SizedBox(height: 4),
            pw.Text(valor, style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: cor)),
          ],
        ),
      ),
    );
  }
}
