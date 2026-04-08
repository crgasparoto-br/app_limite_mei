# Proximos passos para Play Console

## Status tecnico atual

O projeto ja esta pronto para submissao tecnica na Google Play.

Concluido localmente:

- `flutter analyze` sem issues
- Android SDK configurado
- licencas Android aceitas
- `android/upload-keystore.jks` criado
- `android/key.properties` criado localmente
- AAB release gerado com sucesso
- teste em aparelho real concluido

Artefato pronto para upload:

- `build/app/outputs/bundle/release/app-release.aab`

## Passo 1 - Subir o AAB

1. Acesse `https://play.google.com/console`
2. Crie o app ou abra o app existente
3. Escolha um track de distribuicao:
   teste interno
   teste fechado
   producao
4. Envie `build/app/outputs/bundle/release/app-release.aab`

## Passo 2 - Configurar o Premium

Antes de liberar para usuarios finais, confirme o produto da cobranca:

- leia `GOOGLE_PLAY_BILLING.md`
- crie ou valide o produto `br.com.limitemei.premium`
- publique esse produto no mesmo track de teste do app
- teste compra e restauracao pela Play Store

## Passo 3 - Ficha da loja

Ainda falta concluir:

- descricao curta
- descricao completa
- screenshots
- icone 512x512
- banner 1024x500
- politica de privacidade
- classificacao de conteudo
- preco e distribuicao

## Passo 4 - Se precisar gerar novamente

```bash
flutter clean
flutter pub get
flutter build appbundle --release
```
