# Guia de Publicação no Google Play

## ✅ Configurações Realizadas

### 1. **Application ID**
- Alterado de `com.example.app_limite_mei` para `br.com.limitemei`
- Este é o identificador único do app na Google Play Store

### 2. **Signing Configuration**
- Configurada leitura de `android/key.properties` para assinatura de release (arquivo local, não versionado)
- Configurado build.gradle.kts para usar signing config em release
- Adicionadas regras ProGuard para otimização e proteção do código

### 3. **Permissões do Android**
- `INTERNET`: Acesso à internet (necessário para Supabase)
- `POST_NOTIFICATIONS`: Envio de notificações
- `ACCESS_NETWORK_STATE`: Verificação do estado da rede

### 4. **Ícones do Launcher**
- Gerados ícones com o logo_06.png
- Criados ícones adaptáveis para Android

### 5. **Otimizações de Release**
- Minificação de código habilitada
- Redução de recursos habilitada
- ProGuard configurado

---

## 🛠️ Atualização local (sem publicar no Google Play)

Se você ainda **não publicou** na Google Play e só precisa atualizar o projeto aqui no VS Code:

1. Salve as alterações no código.
2. Rode as dependências:

```bash
flutter pub get
```

3. (Opcional) Limpe o build anterior se houver erros estranhos:

```bash
flutter clean
flutter pub get
```

4. Rode o app normalmente:

```bash
flutter run
```

⚠️ **Só é necessário gerar APK/AAB novamente** quando você for testar um release ou enviar para a Play Console.

---

## 🔑 Próximos Passos - Gerar Keystore

### 1. Criar o arquivo keystore (execute no terminal):

```bash
cd C:\Users\PC01\OneDrive\Projetos\app_limite_mei\android
keytool -genkey -v -keystore upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

Durante a criação, você será solicitado a fornecer:
- Senha do keystore (lembre-se dela!)
- Nome, organização, cidade, estado, país
- Senha da chave (pode ser a mesma do keystore)

### 2. Criar/atualizar o arquivo `android/key.properties`:

Após criar o keystore, copie `android/key.properties.example` para `android/key.properties` e preencha os valores reais:

```properties
storePassword=SUA_SENHA_KEYSTORE
keyPassword=SUA_SENHA_KEY
keyAlias=upload
storeFile=upload-keystore.jks
```


### 2.1 Usar template seguro (recomendado):

```bash
cp android/key.properties.example android/key.properties
```

⚠️ **IMPORTANTE**: 
- Nunca commite o arquivo `key.properties` ou `upload-keystore.jks` no Git
- Faça backup do keystore em local seguro
- Se perder o keystore, não poderá mais atualizar o app na Play Store

---

## 📦 Gerar APK/AAB para Publicação

### Gerar AAB (Android App Bundle - Recomendado):
```bash
flutter build appbundle --release
```

O arquivo será gerado em: `build/app/outputs/bundle/release/app-release.aab`

### Gerar APK (Alternativo):
```bash
flutter build apk --release
```

O arquivo será gerado em: `build/app/outputs/flutter-apk/app-release.apk`

---

## 📝 Checklist de Publicação

Antes de enviar para a Google Play Console:

- [ ] Keystore criado e configurado
- [ ] Arquivo key.properties atualizado com senhas corretas
- [ ] Build de release gerado com sucesso
- [ ] App testado em dispositivo real
- [ ] Descrição do app preparada (curta e longa)
- [ ] Screenshots preparados (mínimo 2, até 8)
- [ ] Ícone de alta resolução (512x512 px)
- [ ] Banner promocional (1024x500 px)
- [ ] Política de privacidade publicada (se usar dados pessoais)
- [ ] Classificação de conteúdo definida
- [ ] Preço e distribuição configurados

---


> ℹ️ **Status real do projeto no repositório:** os itens acima só devem ser marcados como concluídos depois de validar localmente com os arquivos/artefatos gerados (`android/key.properties`, `android/upload-keystore.jks` e `build/app/outputs/bundle/release/app-release.aab`).

## 🌐 Google Play Console

1. Acesse: https://play.google.com/console
2. Crie um novo app
3. Preencha as informações do app
4. Faça upload do AAB
5. Configure a ficha da loja
6. Envie para revisão

---

## 🔧 Comandos Úteis

### Verificar versão do app:
```bash
flutter pub get
grep version pubspec.yaml
```

### Limpar build anterior:
```bash
flutter clean
flutter pub get
```

### Testar build de release:
```bash
flutter run --release
```

### Verificar assinatura do APK:
```bash
keytool -printcert -jarfile build/app/outputs/flutter-apk/app-release.apk
```

---

## 📞 Suporte

Em caso de dúvidas, consulte:
- [Documentação Flutter - Deploy Android](https://docs.flutter.dev/deployment/android)
- [Google Play Console Help](https://support.google.com/googleplay/android-developer)
