# Limite MEI

Aplicativo Flutter para acompanhar o faturamento anual do MEI, controlar alertas de limite e desbloquear recursos Premium.

## Documentos principais

- `PROXIMOS_PASSOS_PLAY_CONSOLE.md`: checklist operacional para subir a versao atual na Google Play
- `GOOGLE_PLAY_BILLING.md`: configuracao do produto Premium e fluxo de cobranca pela Play Store

## Stack principal

- Flutter
- SharedPreferences
- Google Play Billing via `in_app_purchase`

## Premium

O Premium usa compra nao consumivel pela Google Play.

Produto configurado no app:

- `br.com.limitemei.premium`

Esse ID precisa ser igual ao produto cadastrado na Play Console.
