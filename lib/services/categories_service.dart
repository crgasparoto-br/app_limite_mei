import 'package:shared_preferences/shared_preferences.dart';

class CategoriesService {
  static const _key = 'lm_categories';
  Future<List<String>> loadCategories() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList(_key);
      if (list == null || list.isEmpty) {
        return const ['Geral','Vendas','Serviços','Impostos','Materiais','Transporte','Alimentação','Outros'];
      }
      return list;
    } catch (_) {
      return const ['Geral','Vendas','Serviços','Impostos','Materiais','Transporte','Alimentação','Outros'];
    }
  }
}