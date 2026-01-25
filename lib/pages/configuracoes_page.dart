import 'package:flutter/material.dart';
import '../domain/repositories/settings_repository.dart';
import '../domain/repositories/entitlements_repository.dart';
import '../domain/entities/app_settings.dart';
import '../domain/entities/entitlements.dart';
import '../service_locator.dart';
import '../presentation/widgets/paywall_dialog.dart';

class ConfiguracoesPage extends StatefulWidget {
  const ConfiguracoesPage({super.key});

  @override
  State<ConfiguracoesPage> createState() => _ConfiguracoesPageState();
}

class _ConfiguracoesPageState extends State<ConfiguracoesPage> {
  late SettingsRepository _settingsRepo;
  late EntitlementsRepository _entitlementsRepo;

  late AppSettings _settings;
  bool _isPremium = false;
  bool _loading = true;
  int _anoSelecionado = DateTime.now().year;

  @override
  void initState() {
    super.initState();
    _settingsRepo = getIt<SettingsRepository>();
    _entitlementsRepo = getIt<EntitlementsRepository>();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final settings = await _settingsRepo.getSettings();
      final isPremium = await _entitlementsRepo.isPremiumActive();

      if (mounted) {
        setState(() {
          _settings = settings;
          _isPremium = isPremium;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _saveLimite(double novoLimite) async {
    try {
      AppSettings updated;
      
      if (_isPremium && _anoSelecionado != DateTime.now().year) {
        // Premium: salvar limite específico para o ano selecionado
        final novosLimites = Map<int, double>.from(_settings.limitesPorAno);
        novosLimites[_anoSelecionado] = novoLimite;
        updated = _settings.copyWith(limitesPorAno: novosLimites);
      } else {
        // FREE ou ano atual: salvar como limite padrão
        updated = _settings.copyWith(limiteAnual: novoLimite);
      }
      
      await _settingsRepo.saveSettings(updated);
      setState(() => _settings = updated);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Limite de $_anoSelecionado atualizado!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro: $e')),
      );
    }
  }

  void _selecionarAno(int ano) {
    if (!_isPremium && ano != DateTime.now().year) {
      _showAnosAnterioresPaywall();
      return;
    }
    setState(() => _anoSelecionado = ano);
  }

  void _showAnosAnterioresPaywall() {
    showPaywall(
      context,
      title: 'Anos Anteriores - Premium',
      subtitle: 'Configure limites diferentes para cada ano e consulte o histórico completo!',
      onUpgrade: () async {
        Navigator.pop(context);
        await _activatePremium();
      },
      onRestore: () async {
        Navigator.pop(context);
        await _restorePremium();
      },
    );
  }

  void _toggleAlerta(int threshold) async {
    if (!_isPremium && threshold != 90 && threshold != 100) {
      _showPremiumPaywall();
      return;
    }

    final updated = _settings.copyWith(
      alertasAtivos: {
        ..._settings.alertasAtivos,
        threshold: !(_settings.alertasAtivos[threshold] ?? false),
      },
    );

    setState(() => _settings = updated);
    await _settingsRepo.saveSettings(updated);
  }

  void _showPremiumPaywall() {
    showPaywall(
      context,
      title: 'Alertas avançados',
      subtitle: 'Configure alertas em 70%, 80%, 95% e muito mais!',
      onUpgrade: () async {
        Navigator.pop(context);
        await _activatePremium();
      },
      onRestore: () async {
        Navigator.pop(context);
        await _restorePremium();
      },
    );
  }

  Future<void> _activatePremium() async {
    // TODO: Integrar com Google Play Billing
    // Por enquanto, ativa Premium localmente para testes
    try {
      final entitlements = Entitlements(
        isPremium: true,
        dataCompra: DateTime.now(),
        dataExpiracao: null, // Sem expiração (lifetime)
      );
      await _entitlementsRepo.setEntitlements(entitlements);
      
      if (mounted) {
        setState(() => _isPremium = true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Premium ativado! (modo desenvolvimento)'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao ativar Premium: $e')),
      );
    }
  }

  Future<void> _restorePremium() async {
    try {
      final restored = await _entitlementsRepo.restorePurchase();
      if (restored) {
        setState(() => _isPremium = true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Premium restaurado!')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nenhuma compra encontrada')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro: $e')),
      );
    }
  }

  Future<void> _resetToFree() async {
    // Método de desenvolvimento para resetar para plano FREE
    try {
      await _entitlementsRepo.resetToFree();
      setState(() => _isPremium = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Resetado para plano FREE'),
          backgroundColor: Colors.orange,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Configurações')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Limite Anual
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Limite Anual',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            // Seletor de Ano (Premium)
                            if (_isPremium)
                              DropdownButton<int>(
                                value: _anoSelecionado,
                                items: List.generate(5, (i) {
                                  final ano = DateTime.now().year - i;
                                  return DropdownMenuItem(
                                    value: ano,
                                    child: Text(ano.toString()),
                                  );
                                }),
                                onChanged: (ano) {
                                  if (ano != null) _selecionarAno(ano);
                                },
                              )
                            else
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade200,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      _anoSelecionado.toString(),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    GestureDetector(
                                      onTap: _showAnosAnterioresPaywall,
                                      child: Icon(
                                        Icons.lock,
                                        size: 16,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          key: ValueKey(_anoSelecionado), // Força rebuild ao mudar ano
                          initialValue: _settings
                              .getLimitePorAno(_anoSelecionado)
                              .toStringAsFixed(2),
                          onFieldSubmitted: (value) {
                            final parsed = double.tryParse(
                              value.replaceAll(',', '.'),
                            );
                            if (parsed != null && parsed > 0) {
                              _saveLimite(parsed);
                            }
                          },
                          decoration: InputDecoration(
                            labelText: 'Limite de $_anoSelecionado',
                            prefixText: 'R\$ ',
                            border: const OutlineInputBorder(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Alertas
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Alertas',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),
                        ..._buildAlertTogles(),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Plano
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Plano',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _isPremium ? '⭐ Premium' : 'Grátis',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: _isPremium ? Colors.amber : Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (!_isPremium)
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _showPremiumPaywall,
                              child: const Text('Assinar Premium'),
                            ),
                          ),
                        if (_isPremium)
                          Column(
                            children: [
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton(
                                  onPressed: _resetToFree,
                                  child: const Text('Cancelar Premium (dev)'),
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  List<Widget> _buildAlertTogles() {
    final thresholds = _isPremium ? [70, 80, 90, 95, 100] : [90, 100];

    return thresholds.map((threshold) {
      final isActive = _settings.alertasAtivos[threshold] ?? false;
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('$threshold%'),
            Switch(
              value: isActive,
              onChanged: (_) => _toggleAlerta(threshold),
            ),
          ],
        ),
      );
    }).toList();
  }
}
