import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'domain/repositories/receita_repository.dart';
import 'domain/repositories/settings_repository.dart';
import 'domain/repositories/entitlements_repository.dart';
import 'data/repositories/local_receita_repository.dart';
import 'data/repositories/local_settings_repository.dart';
import 'data/repositories/local_entitlements_repository.dart';
import 'data/services/alert_service.dart';
import 'domain/usecases/add_receita_usecase.dart';
import 'domain/usecases/update_receita_usecase.dart';
import 'domain/usecases/get_dashboard_usecase.dart';
import 'domain/usecases/get_relatorio_mensal_usecase.dart';
import 'domain/usecases/get_comparativos_usecase.dart';

final getIt = GetIt.instance;

/// Configurar Injeção de Dependências
Future<void> setupServiceLocator() async {
  // SharedPreferences
  final prefs = await SharedPreferences.getInstance();
  getIt.registerSingleton<SharedPreferences>(prefs);

  // Repositories
  getIt.registerSingleton<ReceitaRepository>(
    LocalReceitaRepository(prefs: prefs),
  );

  getIt.registerSingleton<SettingsRepository>(
    LocalSettingsRepository(prefs: prefs),
  );

  getIt.registerSingleton<EntitlementsRepository>(
    LocalEntitlementsRepository(prefs: prefs),
  );

  // Services
  getIt.registerSingleton<AlertService>(
    AlertService(prefs: prefs),
  );

  // UseCases
  getIt.registerSingleton<AddReceitaUseCase>(
    AddReceitaUseCase(
      receitaRepo: getIt<ReceitaRepository>(),
      entitlementsRepo: getIt<EntitlementsRepository>(),
    ),
  );

  getIt.registerSingleton<UpdateReceitaUseCase>(
    UpdateReceitaUseCase(
      receitaRepo: getIt<ReceitaRepository>(),
    ),
  );

  getIt.registerSingleton<GetDashboardUseCase>(
    GetDashboardUseCase(
      receitaRepo: getIt<ReceitaRepository>(),
      settingsRepo: getIt<SettingsRepository>(),
      entitlementsRepo: getIt<EntitlementsRepository>(),
    ),
  );

  getIt.registerSingleton<GetRelatorioMensalUseCase>(
    GetRelatorioMensalUseCase(
      getIt<ReceitaRepository>(),
    ),
  );

  getIt.registerSingleton<GetComparativosUseCase>(
    GetComparativosUseCase(
      getIt<ReceitaRepository>(),
      getIt<SettingsRepository>(),
    ),
  );
}
