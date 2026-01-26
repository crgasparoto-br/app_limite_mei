import 'package:flutter/material.dart';
import '../data/services/supabase_service.dart';
import '../domain/repositories/receita_repository.dart';
import '../domain/repositories/settings_repository.dart';
import '../config/supabase_config.dart';
import '../service_locator.dart';

class BackupPage extends StatefulWidget {
  const BackupPage({super.key});

  @override
  State<BackupPage> createState() => _BackupPageState();
}

class _BackupPageState extends State<BackupPage> {
  final _emailCtrl = TextEditingController();
  final _otpCtrl = TextEditingController();

  SupabaseService? _supabaseService;
  late ReceitaRepository _receitaRepo;
  late SettingsRepository _settingsRepo;

  bool _loading = false;
  bool _otpSent = false;
  bool _isAuthenticated = false;
  bool _devMode = false; // Modo desenvolvimento

  @override
  void initState() {
    super.initState();
    if (SupabaseConfig.isConfigured) {
      _supabaseService = getIt<SupabaseService>();
      _checkAuth();
    }
    _receitaRepo = getIt<ReceitaRepository>();
    _settingsRepo = getIt<SettingsRepository>();
  }

  // Login simulado para desenvolvimento (sem Supabase)
  void _devLogin() {
    if (_emailCtrl.text.trim().isEmpty) {
      _showSnackbar('Digite um email');
      return;
    }

    setState(() {
      _devMode = true;
      _isAuthenticated = true;
    });

    _showSnackbar('✅ Modo desenvolvimento ativado!');
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _otpCtrl.dispose();
    super.dispose();
  }

  void _checkAuth() {
    if (_supabaseService != null) {
      setState(() {
        _isAuthenticated = _supabaseService!.isAuthenticated;
      });
    }
  }

  Future<void> _sendOTP() async {
    if (_supabaseService == null) {
      _showSnackbar('Serviço de backup não disponível');
      return;
    }

    if (_emailCtrl.text.trim().isEmpty) {
      _showSnackbar('Digite seu email');
      return;
    }

    setState(() => _loading = true);

    try {
      await _supabaseService!.sendOTP(_emailCtrl.text.trim());
      setState(() {
        _otpSent = true;
        _loading = false;
      });
      _showSnackbar('Código enviado para ${_emailCtrl.text}');
    } catch (e) {
      setState(() => _loading = false);
      _showSnackbar('Erro: $e');
    }
  }

  Future<void> _verifyOTP() async {
    if (_supabaseService == null) {
      _showSnackbar('Serviço de backup não disponível');
      return;
    }

    if (_otpCtrl.text.trim().isEmpty) {
      _showSnackbar('Digite o código');
      return;
    }

    setState(() => _loading = true);

    try {
      final success = await _supabaseService!.verifyOTP(
        _emailCtrl.text.trim(),
        _otpCtrl.text.trim(),
      );

      if (success) {
        setState(() {
          _isAuthenticated = true;
          _loading = false;
        });
        _showSnackbar('Login realizado com sucesso!');
      } else {
        setState(() => _loading = false);
        _showSnackbar('Código inválido');
      }
    } catch (e) {
      setState(() => _loading = false);
      _showSnackbar('Erro: $e');
    }
  }

  Future<void> _makeBackup() async {
    if (_devMode) {
      // Modo desenvolvimento - simular backup local
      await Future.delayed(const Duration(seconds: 1));
      _showSnackbar('✅ Backup simulado (modo dev)', Colors.orange);
      return;
    }

    if (_supabaseService == null) {
      _showSnackbar('Serviço de backup não disponível', Colors.red);
      return;
    }

    setState(() => _loading = true);

    try {
      // Obter todas as receitas
      final year = await _settingsRepo.getSelectedYear();
      final receitas = await _receitaRepo.getReceitasByYear(year);

      // Obter configurações
      final settings = await _settingsRepo.getSettings();

      // Fazer backup
      await _supabaseService!.backupReceitas(receitas);
      await _supabaseService!.backupSettings(settings);

      setState(() => _loading = false);
      _showSnackbar('✅ Backup realizado com sucesso!', Colors.green);
    } catch (e) {
      setState(() => _loading = false);
      _showSnackbar('Erro ao fazer backup: $e', Colors.red);
    }
  }

  Future<void> _restoreBackup() async {
    if (_devMode) {
      _showSnackbar('⚠️ Restauração não disponível em modo dev', Colors.orange);
      return;
    }

    if (_supabaseService == null) {
      _showSnackbar('Serviço de backup não disponível', Colors.red);
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Restaurar Backup'),
        content: const Text(
          'Isso irá substituir todos os seus dados locais. Deseja continuar?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Restaurar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _loading = true);

    try {
      // Restaurar receitas
      final receitas = await _supabaseService!.restoreReceitas();
      for (final receita in receitas) {
        await _receitaRepo.addReceita(receita);
      }

      // Restaurar configurações
      final settings = await _supabaseService!.restoreSettings();
      if (settings != null) {
        await _settingsRepo.saveSettings(settings);
      }

      setState(() => _loading = false);
      _showSnackbar('✅ Backup restaurado com sucesso!', Colors.green);
    } catch (e) {
      setState(() => _loading = false);
      _showSnackbar('Erro ao restaurar backup: $e', Colors.red);
    }
  }

  Future<void> _signOut() async {
    if (_supabaseService != null && !_devMode) {
      await _supabaseService!.signOut();
    }
    setState(() {
      _isAuthenticated = false;
      _otpSent = false;
      _devMode = false;
      _emailCtrl.clear();
      _otpCtrl.clear();
    });
    _showSnackbar('Logout realizado');
  }

  void _showSnackbar(String message, [Color? color]) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message), backgroundColor: color));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Backup Premium'),
        actions: [
          if (_isAuthenticated)
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: _signOut,
              tooltip: 'Sair',
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _isAuthenticated
          ? _buildBackupInterface()
          : _buildLoginInterface(),
    );
  }

  Widget _buildLoginInterface() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Icon(Icons.cloud_upload, size: 80, color: Colors.blue),
          const SizedBox(height: 24),
          const Text(
            'Backup em Nuvem',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          const Text(
            'Faça login para salvar suas receitas na nuvem',
            style: TextStyle(color: Colors.grey),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),

          TextField(
            controller: _emailCtrl,
            decoration: const InputDecoration(
              labelText: 'Email',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.email),
            ),
            keyboardType: TextInputType.emailAddress,
            enabled: !_otpSent,
          ),

          if (_otpSent) ...[
            const SizedBox(height: 16),
            TextField(
              controller: _otpCtrl,
              decoration: const InputDecoration(
                labelText: 'Código (6 dígitos)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.lock),
              ),
              keyboardType: TextInputType.number,
              maxLength: 6,
            ),
          ],

          const SizedBox(height: 24),

          ElevatedButton(
            onPressed: _otpSent ? _verifyOTP : _sendOTP,
            style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(16)),
            child: Text(_otpSent ? 'Verificar Código' : 'Enviar Código'),
          ),

          if (_otpSent) ...[
            const SizedBox(height: 16),
            TextButton(
              onPressed: () {
                setState(() {
                  _otpSent = false;
                  _otpCtrl.clear();
                });
              },
              child: const Text('Voltar'),
            ),
          ],

          // Botão de desenvolvimento
          const SizedBox(height: 32),
          const Divider(),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: _devLogin,
            icon: const Icon(Icons.developer_mode),
            label: const Text('Modo Desenvolvimento'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.all(16),
              foregroundColor: Colors.orange,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '⚠️ Usar apenas para testes locais.\nBackup funcionará apenas neste dispositivo.',
            style: TextStyle(fontSize: 12, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildBackupInterface() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_devMode)
            Card(
              color: Colors.orange.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.developer_mode, color: Colors.orange.shade700),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Modo Desenvolvimento\nBackup local apenas',
                        style: TextStyle(
                          color: Colors.orange.shade900,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (_devMode) const SizedBox(height: 16),

          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Icon(
                    Icons.check_circle,
                    size: 60,
                    color: _devMode ? Colors.orange : Colors.green,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _devMode ? 'Modo Desenvolvimento' : 'Conectado',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _emailCtrl.text,
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),

          ElevatedButton.icon(
            onPressed: _makeBackup,
            icon: const Icon(Icons.cloud_upload),
            label: const Text('Fazer Backup Agora'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.all(16),
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
          ),

          const SizedBox(height: 16),

          OutlinedButton.icon(
            onPressed: _restoreBackup,
            icon: const Icon(Icons.cloud_download),
            label: const Text('Restaurar Backup'),
            style: OutlinedButton.styleFrom(padding: const EdgeInsets.all(16)),
          ),

          const SizedBox(height: 32),

          const Divider(),

          const SizedBox(height: 16),

          const Text(
            'ℹ️ Backup Automático',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'O backup automático salva suas receitas e configurações sempre que você fizer alterações.',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
