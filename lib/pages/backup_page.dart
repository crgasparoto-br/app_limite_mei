import 'package:flutter/material.dart';

class BackupPage extends StatelessWidget {
  const BackupPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Backup')),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Backup em nuvem está temporariamente indisponível nesta versão.',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
