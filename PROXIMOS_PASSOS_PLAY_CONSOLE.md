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

Antes de liberar para usuarios finais, confirme os planos da cobranca:

- leia `GOOGLE_PLAY_BILLING.md`
- crie ou valide os planos:
  `br.com.limitemei.premium.mensal`
  `br.com.limitemei.premium.anual`
  `br.com.limitemei.premium.vitalicio`
- publique os 3 planos no mesmo track de teste do app
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

## Passo 4 - Validacao do fluxo pago

Antes de publicar para mais usuarios, valide este roteiro:

1. Abrir um bloqueio de recurso no app
2. Verificar se o paywall mostra os 3 planos
3. Comprar o plano mensal e confirmar liberacao imediata
4. Reinstalar o app e testar `Restaurar compra`
5. Repetir o teste com o plano anual
6. Repetir o teste com o plano vitalicio
7. Confirmar que os recursos liberados incluem:
   relatorio mensal
   comparativos
   exportacao
   filtro por mes
   anos anteriores
8. Confirmar que o plano ativo aparece corretamente em Configuracoes

## Passo 5 - Se precisar gerar novamente

```bash
flutter clean
flutter pub get
flutter build appbundle --release
```
