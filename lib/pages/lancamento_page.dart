import 'package:flutter/material.dart';
import 'models/lancamento.dart';

class LancamentoPage extends StatefulWidget {
  final int year;
  final List<String> categorias;
  final Lancamento? lancamento;

  const LancamentoPage({
    super.key,
    required this.year,
    required this.categorias,
    this.lancamento,
  });

  @override
  State<LancamentoPage> createState() => _LancamentoPageState();
}

class _LancamentoPageState extends State<LancamentoPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.lancamento == null
            ? 'Novo lançamento'
            : 'Editar lançamento'),
      ),
      body: const Center(
        child: Text('Formulário do lançamento aqui'),
      ),
    );
  }
}
