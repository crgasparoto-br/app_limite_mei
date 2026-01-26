# Configuração do Supabase para Backup Premium

## Passo 1: Criar Projeto no Supabase

1. Acesse [https://supabase.com](https://supabase.com)
2. Crie uma conta ou faça login
3. Clique em "New Project"
4. Preencha os dados do projeto:
   - Nome: app_limite_mei
   - Database Password: escolha uma senha forte
   - Região: escolha a mais próxima (South America - São Paulo)

## Passo 2: Obter Credenciais

1. No dashboard do projeto, vá em **Settings** > **API**
2. Copie as seguintes informações:
   - **Project URL** (URL do projeto)
   - **anon public** key (chave pública anônima)

## Passo 3: Configurar no App

1. Abra o arquivo `lib/config/supabase_config.dart`
2. Substitua os valores:
   ```dart
   static const String supabaseUrl = 'SUA_URL_AQUI';
   static const String supabaseAnonKey = 'SUA_CHAVE_AQUI';
   ```

## Passo 4: Criar Tabelas no Banco de Dados

No Supabase, vá em **SQL Editor** e execute os seguintes comandos:

### Tabela de Receitas
```sql
CREATE TABLE receitas (
  id TEXT PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  valor DECIMAL(10,2) NOT NULL,
  data TIMESTAMP NOT NULL,
  descricao TEXT,
  criado_em TIMESTAMP NOT NULL DEFAULT NOW(),
  atualizado_em TIMESTAMP,
  CONSTRAINT receitas_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id)
);

-- Índice para melhor performance
CREATE INDEX idx_receitas_user_id ON receitas(user_id);
CREATE INDEX idx_receitas_data ON receitas(data);

-- RLS (Row Level Security)
ALTER TABLE receitas ENABLE ROW LEVEL SECURITY;

-- Política: usuários podem ver apenas suas próprias receitas
CREATE POLICY "Users can view own receitas"
  ON receitas FOR SELECT
  USING (auth.uid() = user_id);

-- Política: usuários podem inserir receitas
CREATE POLICY "Users can insert own receitas"
  ON receitas FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- Política: usuários podem atualizar próprias receitas
CREATE POLICY "Users can update own receitas"
  ON receitas FOR UPDATE
  USING (auth.uid() = user_id);

-- Política: usuários podem deletar próprias receitas
CREATE POLICY "Users can delete own receitas"
  ON receitas FOR DELETE
  USING (auth.uid() = user_id);
```

### Tabela de Configurações
```sql
CREATE TABLE settings (
  user_id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  limite_anual DECIMAL(10,2) NOT NULL DEFAULT 81000.00,
  limites_por_ano JSONB DEFAULT '{}'::jsonb,
  alertas_ativos JSONB DEFAULT '{"70": false, "80": false, "90": true, "95": false, "100": true}'::jsonb,
  backup_automatico BOOLEAN DEFAULT false,
  updated_at TIMESTAMP DEFAULT NOW()
);

-- RLS
ALTER TABLE settings ENABLE ROW LEVEL SECURITY;

-- Política: usuários podem ver apenas suas configurações
CREATE POLICY "Users can view own settings"
  ON settings FOR SELECT
  USING (auth.uid() = user_id);

-- Política: usuários podem inserir configurações
CREATE POLICY "Users can insert own settings"
  ON settings FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- Política: usuários podem atualizar configurações
CREATE POLICY "Users can update own settings"
  ON settings FOR UPDATE
  USING (auth.uid() = user_id);
```

## Passo 5: Configurar Autenticação por Email

1. No Supabase, vá em **Authentication** > **Providers**
2. Certifique-se de que **Email** está habilitado
3. Em **Email Templates**, você pode personalizar o email do código OTP
4. Configure as opções:
   - **Enable email confirmations**: OFF (para facilitar testes)
   - **Secure email change**: ON (recomendado)

## Passo 6: Testar

1. Execute `flutter pub get` para instalar as dependências
2. Execute o app
3. Ative o Premium (modo desenvolvimento)
4. Vá em **Configurações** > **Backup em Nuvem**
5. Digite seu email e solicite o código
6. Verifique sua caixa de entrada
7. Digite o código de 6 dígitos
8. Teste fazer backup e restaurar dados

## Comandos SQL Úteis

### Ver todos os usuários
```sql
SELECT * FROM auth.users;
```

### Ver receitas de um usuário
```sql
SELECT * FROM receitas WHERE user_id = 'UUID_DO_USUARIO';
```

### Limpar dados de um usuário
```sql
DELETE FROM receitas WHERE user_id = 'UUID_DO_USUARIO';
DELETE FROM settings WHERE user_id = 'UUID_DO_USUARIO';
```

## Troubleshooting

### Erro: "Target of URI doesn't exist: 'package:supabase_flutter/supabase_flutter.dart'"
- Certifique-se de executar `flutter pub get` após adicionar a dependência

### Erro: "Auth session missing"
- O usuário não está autenticado. Verifique se fez login com OTP

### Código OTP não chega
- Verifique a caixa de spam
- Verifique as configurações de Email em Authentication > Providers
- Em desenvolvimento, você pode ver os códigos em Authentication > Users > Logs

### Erro de permissão (RLS)
- Verifique se as políticas foram criadas corretamente
- Certifique-se de que `auth.uid()` corresponde ao `user_id` nos dados

## Notas de Produção

Para produção, considere:
1. Usar variáveis de ambiente para as credenciais
2. Implementar backup automático em background
3. Adicionar sincronização automática ao salvar receitas
4. Implementar resolução de conflitos (se editar offline e online)
5. Adicionar retry logic para falhas de rede
6. Implementar cache local para melhor UX
