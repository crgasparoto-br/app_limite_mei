import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/lancamento.dart';
import '../models/settings_model.dart';

class ExportService {
  Future<String> exportCsv({required List<Lancamento> lancamentos, required SettingsModel settings, int? mesSelecionado}) async {
    final sb = StringBuffer();
    sb.writeln('data;tipo;categoria;valor;descricao');
    for (final r in lancamentos) {
      final data = r.data.toIso8601String().split('T').first;
      final tipo = r.tipo;
      final categoria = r.categoria.replaceAll(';', ',');
      final valorTxt = r.valor.toStringAsFixed(2).replaceAll('.', ',');
      final desc = r.descricao.replaceAll('\n', ' ').replaceAll(';', ',');
      sb.writeln('$data;$tipo;$categoria;$valorTxt;$desc');
    }
    final dir = await getTemporaryDirectory();
    final mesTag = mesSelecionado == null ? 'todos' : mesSelecionado.toString().padLeft(2, '0');
    final file = File('${dir.path}/limite_mei_lancamentos_${settings.year}_$mesTag.csv');
    await file.writeAsString(sb.toString(), flush: true);
    return file.path;
  }

  Future<void> shareFile(String path, {required BuildContext context, String? text}) async {
    await Share.shareXFiles([XFile(path)], text: text ?? 'Exportação - Limite MEI');
  }
}