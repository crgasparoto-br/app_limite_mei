import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../domain/entities/receita.dart';

class ExportService {
  /// Exporta receitas para CSV
  Future<void> exportToCSV(List<Receita> receitas, {int? mes, int? ano}) async {
    if (receitas.isEmpty) {
      throw Exception('Nenhuma receita para exportar');
    }

    // Filtrar por mês/ano se especificado
    var receitasFiltradas = receitas;
    if (ano != null) {
      receitasFiltradas = receitasFiltradas.where((r) => r.data.year == ano).toList();
    }
    if (mes != null) {
      receitasFiltradas = receitasFiltradas.where((r) => r.data.month == mes).toList();
    }

    if (receitasFiltradas.isEmpty) {
      throw Exception('Nenhuma receita encontrada para o período selecionado');
    }

    // Ordenar por data
    receitasFiltradas.sort((a, b) => a.data.compareTo(b.data));

    // Criar conteúdo CSV
    final buffer = StringBuffer();
    buffer.writeln('Data,Valor,Descrição');

    for (final receita in receitasFiltradas) {
      final data = '${receita.data.day.toString().padLeft(2, '0')}/${receita.data.month.toString().padLeft(2, '0')}/${receita.data.year}';
      final valor = receita.valor.toStringAsFixed(2).replaceAll('.', ',');
      final descricao = receita.descricao?.replaceAll(',', ';') ?? '';
      buffer.writeln('$data,$valor,$descricao');
    }

    // Salvar arquivo
    final directory = await getApplicationDocumentsDirectory();
    final fileName = mes != null && ano != null
        ? 'receitas_${mes}_$ano.csv'
        : ano != null
            ? 'receitas_$ano.csv'
            : 'receitas.csv';
    final file = File('${directory.path}/$fileName');
    await file.writeAsString(buffer.toString());

    // Compartilhar arquivo
    await Share.shareXFiles(
      [XFile(file.path)],
      subject: 'Receitas MEI - $fileName',
      text: 'Exportação de receitas do app Limite MEI',
    );
  }

  /// Exporta receitas para PDF
  Future<void> exportToPDF(List<Receita> receitas, {int? mes, int? ano}) async {
    if (receitas.isEmpty) {
      throw Exception('Nenhuma receita para exportar');
    }

    // Filtrar por mês/ano se especificado
    var receitasFiltradas = receitas;
    if (ano != null) {
      receitasFiltradas = receitasFiltradas.where((r) => r.data.year == ano).toList();
    }
    if (mes != null) {
      receitasFiltradas = receitasFiltradas.where((r) => r.data.month == mes).toList();
    }

    if (receitasFiltradas.isEmpty) {
      throw Exception('Nenhuma receita encontrada para o período selecionado');
    }

    // Ordenar por data
    receitasFiltradas.sort((a, b) => a.data.compareTo(b.data));

    // Calcular total
    final total = receitasFiltradas.fold<double>(0, (sum, r) => sum + r.valor);

    // Criar PDF
    final pdf = pw.Document();

    // Cabeçalho do período
    final periodo = mes != null && ano != null
        ? '${_getNomeMes(mes)} de $ano'
        : ano != null
            ? 'Ano de $ano'
            : 'Todas as receitas';

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Cabeçalho
              pw.Text(
                'Relatório de Receitas MEI',
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Text(
                periodo,
                style: const pw.TextStyle(fontSize: 16),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                'Total: ${_formatCurrency(total)}',
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 24),

              // Tabela
              pw.Table(
                border: pw.TableBorder.all(),
                columnWidths: {
                  0: const pw.FlexColumnWidth(2),
                  1: const pw.FlexColumnWidth(2),
                  2: const pw.FlexColumnWidth(4),
                },
                children: [
                  // Header
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(
                      color: PdfColors.grey300,
                    ),
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(
                          'Data',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(
                          'Valor',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(
                          'Descrição',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  // Dados
                  ...receitasFiltradas.map((receita) {
                    return pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(
                            '${receita.data.day.toString().padLeft(2, '0')}/${receita.data.month.toString().padLeft(2, '0')}/${receita.data.year}',
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(_formatCurrency(receita.valor)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(receita.descricao ?? '-'),
                        ),
                      ],
                    );
                  }),
                ],
              ),
            ],
          );
        },
      ),
    );

    // Salvar arquivo
    final directory = await getApplicationDocumentsDirectory();
    final fileName = mes != null && ano != null
        ? 'receitas_${mes}_$ano.pdf'
        : ano != null
            ? 'receitas_$ano.pdf'
            : 'receitas.pdf';
    final file = File('${directory.path}/$fileName');
    await file.writeAsBytes(await pdf.save());

    // Compartilhar arquivo
    await Share.shareXFiles(
      [XFile(file.path)],
      subject: 'Receitas MEI - $fileName',
      text: 'Exportação de receitas do app Limite MEI',
    );
  }

  String _formatCurrency(double value) {
    final parts = value.toStringAsFixed(2).split('.');
    final intPart = int.parse(parts[0]);
    final intFormatted = intPart.toString().replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (_) => '.',
    );
    return 'R\$ $intFormatted,${parts[1]}';
  }

  /// Formata mês para nome
  String _getNomeMes(int mes) {
    const meses = [
      'Janeiro', 'Fevereiro', 'Março', 'Abril',
      'Maio', 'Junho', 'Julho', 'Agosto',
      'Setembro', 'Outubro', 'Novembro', 'Dezembro'
    ];
    return meses[mes - 1];
  }
}
