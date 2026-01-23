import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CategoriesPage extends StatefulWidget {
  const CategoriesPage({super.key});

  @override
  State<CategoriesPage> createState() => _CategoriesPageState();
}

class _CategoriesPageState extends State<CategoriesPage> {
  static const _prefsKey = 'lm_categories';

  final _ctrl = TextEditingController();
  bool _loading = true;
  String? _error;

  List<String> _cats = const [];

  static const List<String> _defaults = [
    'Geral',
    'Vendas',
    'Serviços',
    'Impostos',
    'Materiais',
    'Transporte',
    'Alimentação',
    'Outros',
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList(_prefsKey);

      final cats = (list == null || list.isEmpty) ? _defaults : list;
      setState(() {
        _cats = cats;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Erro ao carregar categorias: $e';
        _loading = false;
      });
    }
  }

  Future<void> _savePrefs(List<String> list) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_prefsKey, list);
  }

  Future<void> _add() async {
    final name = _ctrl.text.trim();
    if (name.isEmpty) return;

    final exists = _cats.any((c) => c.toLowerCase() == name.toLowerCase());
    if (exists) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Categoria já existe.')),
      );
      return;
    }

    final next = [..._cats, name]..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    await _savePrefs(next);

    setState(() {
      _cats = next;
      _ctrl.clear();
    });
  }

  Future<void> _edit(int index) async {
    final old = _cats[index];
    final editCtrl = TextEditingController(text: old);

    final newName = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Renomear categoria'),
        content: TextField(
          controller: editCtrl,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Nome'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, editCtrl.text.trim()),
            child: const Text('Salvar'),
          ),
        ],
      ),
    );

    if (newName == null) return;
    final name = newName.trim();
    if (name.isEmpty) return;

    final exists = _cats.any((c) => c.toLowerCase() == name.toLowerCase() && c != old);
    if (exists) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Já existe uma categoria com esse nome.')),
      );
      return;
    }

    final next = [..._cats];
    next[index] = name;
    next.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    await _savePrefs(next);

    setState(() => _cats = next);
  }

  Future<void> _delete(int index) async {
    final name = _cats[index];

    final ok = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Excluir categoria?'),
            content: Text('Excluir "$name"?'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
              ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Excluir')),
            ],
          ),
        ) ??
        false;

    if (!ok) return;

    final next = [..._cats]..removeAt(index);
    if (next.isEmpty) next.addAll(_defaults);

    await _savePrefs(next);
    setState(() => _cats = next);
  }

  Future<void> _resetDefaults() async {
    final ok = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Restaurar padrão?'),
            content: const Text('Isso substituirá suas categorias atuais pelas categorias padrão.'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
              ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Restaurar')),
            ],
          ),
        ) ??
        false;

    if (!ok) return;

    await _savePrefs(_defaults);
    setState(() => _cats = _defaults);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Categorias'),
        actions: [
          IconButton(
            onPressed: _loading ? null : _resetDefaults,
            icon: const Icon(Icons.restart_alt),
            tooltip: 'Restaurar padrão',
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(_error!, style: const TextStyle(color: Colors.red)),
                ))
              : Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _ctrl,
                              decoration: const InputDecoration(
                                labelText: 'Nova categoria',
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton(
                            onPressed: _add,
                            child: const Text('Adicionar'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: ListView.separated(
                          itemCount: _cats.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (_, i) {
                            final c = _cats[i];
                            return ListTile(
                              title: Text(c),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit),
                                    onPressed: () => _edit(i),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete),
                                    onPressed: () => _delete(i),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}
