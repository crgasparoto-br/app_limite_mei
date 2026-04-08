import 'package:flutter/material.dart';

import '../domain/entities/app_settings.dart';
import '../domain/repositories/entitlements_repository.dart';
import '../domain/repositories/settings_repository.dart';
import '../presentation/widgets/premium_purchase_flow.dart';
import '../service_locator.dart';
import '../widgets/currency_input_formatter.dart';

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
  String? _planLabel;

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
      final entitlements = await _entitlementsRepo.getEntitlements();

      if (!mounted) return;
      setState(() {
        _settings = settings;
        _isPremium = entitlements.isActive;
        _planLabel = entitlements.planLabel;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _saveLimite(double novoLimite) async {
    try {
      AppSettings updated;

      if (_isPremium && _anoSelecionado != DateTime.now().year) {
        final novosLimites = Map<int, double>.from(_settings.limitesPorAno);
        novosLimites[_anoSelecionado] = novoLimite;
        updated = _settings.copyWith(limitesPorAno: novosLimites);
      } else {
        updated = _settings.copyWith(limiteAnual: novoLimite);
      }

      await _settingsRepo.saveSettings(updated);
      if (!mounted) return;
      setState(() => _settings = updated);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Limite de $_anoSelecionado atualizado!')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erro: $e')));
    }
  }

  void _selecionarAno(int ano) {
    if (!_isPremium && ano != DateTime.now().year) {
      _showAnosAnterioresPaywall();
      return;
    }
    setState(() => _anoSelecionado = ano);
  }

  String _formatarValorParaInput(double valor) {
    final centavos = (valor * 100).round();
    final texto = centavos.toString().padLeft(3, '0');
    final parteDecimal = texto.substring(texto.length - 2);
    var parteInteira = texto.substring(0, texto.length - 2);

    if (parteInteira.length > 3) {
      final buffer = StringBuffer();
      var count = 0;
      for (var i = parteInteira.length - 1; i >= 0; i--) {
        if (count == 3) {
          buffer.write('.');
          count = 0;
        }
        buffer.write(parteInteira[i]);
        count++;
      }
      parteInteira = buffer.toString().split('').reversed.join();
    }

    return '$parteInteira,$parteDecimal';
  }

  void _showAnosAnterioresPaywall() {
    showPremiumPaywallFlow(
      context,
      title: 'Liberar anos anteriores',
      subtitle:
          'Escolha um plano para configurar limites diferentes por ano e consultar o historico completo.',
      onSuccess: _loadSettings,
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
    showPremiumPaywallFlow(
      context,
      title: 'Alertas avançados',
      subtitle: 'Escolha um plano para liberar alertas mais completos e ter mais controle.',
      onSuccess: _loadSettings,
    );
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
                              'Limite anual',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
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
                          key: ValueKey(_anoSelecionado),
                          initialValue: _formatarValorParaInput(
                            _settings.getLimitePorAno(_anoSelecionado),
                          ),
                          inputFormatters: [BrCurrencyInputFormatter()],
                          keyboardType: TextInputType.number,
                          onFieldSubmitted: (value) {
                            final numerico = value
                                .replaceAll('.', '')
                                .replaceAll(',', '.');
                            final parsed = double.tryParse(numerico);
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
                        ..._buildAlertToggles(),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
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
                          _isPremium ? (_planLabel ?? 'Premium') : 'Versao gratuita',
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
                              child: const Text('Ver planos'),
                            ),
                          ),
                        if (_isPremium)
                          Text(
                            'Versao completa ativa e vinculada a compra da loja.',
                            style: TextStyle(color: Colors.green),
                          ),
                        const SizedBox(height: 12),
                        const Text(
                          'Backup em nuvem está temporariamente indisponível nesta versão.',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  List<Widget> _buildAlertToggles() {
    final thresholds = _isPremium ? [70, 80, 90, 95, 100] : [90, 100];

    return thresholds.map((threshold) {
      final isActive = _settings.alertasAtivos[threshold] ?? false;
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('$threshold%'),
            Switch(value: isActive, onChanged: (_) => _toggleAlerta(threshold)),
          ],
        ),
      );
    }).toList();
  }
}
