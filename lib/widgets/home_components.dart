import 'package:flutter/material.dart';
import '../models/lancamento.dart';
import '../models/settings_model.dart';

class ResumoCard extends StatelessWidget {
  final DateTime now;
  final int year;
  final String mesLabel;
  final double limiteAnual;
  final double totalReceitasAno;
  final double saldoAnualLimite;
  final double receitasPeriodo;
  final double despesasPeriodo;
  final List<double> receitasMes;
  final List<double> despesasMes;
  final String Function(double) formatBRL;

  const ResumoCard({super.key, required this.now, required this.year, required this.mesLabel, required this.limiteAnual, required this.totalReceitasAno, required this.saldoAnualLimite, required this.receitasPeriodo, required this.despesasPeriodo, required this.receitasMes, required this.despesasMes, required this.formatBRL});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(padding: const EdgeInsets.all(12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Resumo ($year - $mesLabel)'),
        const SizedBox(height: 8),
        Text('Receitas no ano: ${formatBRL(totalReceitasAno)}'),
        Text('Limite anual: ${formatBRL(limiteAnual)}'),
        Text('Saldo até o limite: ${formatBRL(saldoAnualLimite)}'),
      ])),
    );
  }
} 

class ResumoFiltrosCard extends StatelessWidget {
  final int count;
  final double receitas;
  final double despesas;
  final double saldo;
  final String Function(double) formatBRL;
  const ResumoFiltrosCard({super.key, required this.count, required this.receitas, required this.despesas, required this.saldo, required this.formatBRL});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(padding: const EdgeInsets.all(12), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text('$count lançamentos'),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text('Receitas: ${formatBRL(receitas)}'),
          Text('Despesas: ${formatBRL(despesas)}'),
          Text('Saldo: ${formatBRL(saldo)}'),
        ])
      ])),
    );
  }
}

class FiltersCard extends StatelessWidget {
  final TextEditingController searchCtrl;
  final String tipoFiltro;
  final void Function(String) onTipoChanged;
  final List<String> categorias;
  final String? categoriaFiltro;
  final void Function(String?) onCategoriaChanged;
  final VoidCallback onClear;

  const FiltersCard({super.key, required this.searchCtrl, required this.tipoFiltro, required this.onTipoChanged, required this.categorias, required this.categoriaFiltro, required this.onCategoriaChanged, required this.onClear});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(padding: const EdgeInsets.all(12), child: Column(children: [
        TextField(controller: searchCtrl, decoration: const InputDecoration(labelText: 'Buscar', hintText: 'Descrição, categoria, data...', prefixIcon: Icon(Icons.search))),
        const SizedBox(height: 8),
        Align(alignment: Alignment.centerLeft, child: Wrap(spacing: 8, runSpacing: 8, children: [
          ChoiceChip(label: const Text('Todos'), selected: tipoFiltro == 'T', onSelected: (_) => onTipoChanged('T')),
          ChoiceChip(label: const Text('Receitas'), selected: tipoFiltro == 'R', onSelected: (_) => onTipoChanged('R')),
          ChoiceChip(label: const Text('Despesas'), selected: tipoFiltro == 'D', onSelected: (_) => onTipoChanged('D')),
        ])),
        const SizedBox(height: 6),
        Row(children: [
          const Spacer(),
          TextButton.icon(onPressed: onClear, icon: const Icon(Icons.refresh, size: 18), label: const Text('Limpar filtros')), 
        ]),
        const SizedBox(height: 8),
        Row(children: [
          const Text('Categoria: '),
          const SizedBox(width: 12),
          Expanded(child: DropdownButton<String?>(isExpanded: true, value: categoriaFiltro, items: [
            const DropdownMenuItem<String?>(value: null, child: Text('Todas')),
            ...[]
          ], onChanged: onCategoriaChanged)),
        ]),
      ])),
    );
  }
}

class LancamentoItem extends StatelessWidget {
  final Lancamento lancamento;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const LancamentoItem({super.key, required this.lancamento, required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final titulo = lancamento.tipo == 'D' ? '- R\$ ${lancamento.valor.toStringAsFixed(2)}' : 'R\$ ${lancamento.valor.toStringAsFixed(2)}';
    return Dismissible(
      key: ValueKey('lan_
${lancamento.id}'),
      background: Container(color: Colors.red, alignment: Alignment.centerLeft, padding: const EdgeInsets.only(left: 16), child: const Icon(Icons.delete, color: Colors.white)),
      secondaryBackground: Container(color: Colors.red, alignment: Alignment.centerRight, padding: const EdgeInsets.only(right: 16), child: const Icon(Icons.delete, color: Colors.white)),
      onDismissed: (_) => onDelete(),
      confirmDismiss: (_) async {
        final res = await showDialog<bool>(context: context, builder: (_) => AlertDialog(title: const Text('Excluir lançamento?'), content: const Text('Essa ação não pode ser desfeita.'), actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')), ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Excluir'))]));
        return res == true;
      },
      child: ListTile(
        title: Text(titulo),
        subtitle: Text('${lancamento.categoria} • ${lancamento.descricao}'),
        trailing: Text(lancamento.data.toIso8601String().split('T').first),
        onTap: onEdit,
      ),
    );
  }
}
