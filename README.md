# Limite MEI

Aplicativo Flutter para acompanhar o faturamento anual do MEI, controlar alertas de limite e liberar recursos extras com planos pagos.

## Documentos principais

- `PROXIMOS_PASSOS_PLAY_CONSOLE.md`: checklist operacional para subir a versao atual na Google Play
- `GOOGLE_PLAY_BILLING.md`: configuracao dos planos e fluxo de cobranca pela Play Store

## Stack principal

- Flutter
- SharedPreferences
- Google Play Billing via `in_app_purchase`

## Planos pagos

O app oferece 3 planos pela Google Play:

- Mensal: `R$ 9,90` - `br.com.limitemei.premium.mensal`
- Anual: `12x de R$ 6,90` - `br.com.limitemei.premium.anual`
- Vitalicio de lancamento: `R$ 99,90` - `br.com.limitemei.premium.vitalicio`

Os IDs precisam ser iguais aos produtos cadastrados na Play Console.
