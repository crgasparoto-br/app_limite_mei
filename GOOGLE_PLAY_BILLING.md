# Google Play Billing

## Produtos configurados no app

- Mensal: `br.com.limitemei.premium.mensal`
- Anual: `br.com.limitemei.premium.anual`
- Vitalicio: `br.com.limitemei.premium.vitalicio`

Tipos recomendados na Play Console:

- `br.com.limitemei.premium.mensal`: assinatura
- `br.com.limitemei.premium.anual`: assinatura
- `br.com.limitemei.premium.vitalicio`: produto no app nao consumivel

O codigo usa esse ID em `lib/config/premium_config.dart`.

## O que ja esta integrado

- consulta de disponibilidade da loja
- busca dos 3 produtos configurados
- inicio da compra do plano selecionado
- restauracao de compras
- persistencia local do acesso pago apos compra/restauracao
- liberacao das telas pagas com base no entitlement ativo

## O que configurar na Play Console

1. Acesse seu app em `https://play.google.com/console`
2. Entre em `Monetizar`
3. Crie as assinaturas `br.com.limitemei.premium.mensal` e `br.com.limitemei.premium.anual`
4. Crie o produto no app `br.com.limitemei.premium.vitalicio`
5. Defina os precos:
6. Mensal: `R$ 9,90`
7. Anual: `12x de R$ 6,90`
8. Vitalicio de lancamento: `R$ 99,90`
9. Ative os 3 produtos
10. Publique a alteracao da configuracao no track de teste que voce estiver usando

## Textos sugeridos para a Play Console

### Plano mensal

- Nome: `Plano Mensal`
- Descricao curta: `Libere todos os recursos com pagamento mensal`
- Descricao completa: `Ideal para quem quer comecar agora com baixo custo. Libera relatorios, comparativos, exportacao, alertas extras e historico de anos anteriores.`

### Plano anual

- Nome: `Plano Anual`
- Descricao curta: `Acompanhe o ano inteiro com 12 parcelas de 6,90`
- Descricao completa: `A melhor escolha para acompanhar seu faturamento ao longo do ano com pagamento em 12 parcelas de R$ 6,90. Libera todos os recursos extras do app com previsibilidade no custo.`

### Plano vitalicio

- Nome: `Vitalicio de Lancamento`
- Descricao curta: `Pague uma vez e tenha acesso permanente`
- Descricao completa: `Oferta de lancamento para garantir acesso permanente aos recursos extras do app com pagamento unico. Ideal para quem quer o menor custo total no longo prazo.`

## Como validar

1. Instale uma build assinada com a mesma chave de upload usada no app
2. Adicione a conta de teste de licenciamento na Play Console
3. Publique o app em teste interno ou fechado
4. Baixe o app pela Play Store nessa conta de teste
5. Toque em um bloqueio de recurso e escolha um dos planos
6. Confirme que a compra libera os recursos extras
7. Reinstale o app e use `Restaurar compra`

## Checklist do fluxo no app

- O paywall deve abrir sem cortar as opcoes em telas menores
- Os 3 cards devem aparecer com preco, descricao e CTA
- O plano comprado deve liberar os recursos imediatamente
- O texto do plano ativo deve aparecer em `Configuracoes`
- `Restaurar compra` deve recuperar o acesso na mesma conta da loja
- O plano vitalicio deve permanecer ativo sem expiracao local

## Observacoes importantes

- O fluxo de compra real da Google Play nao funciona de forma confiavel em `flutter run` fora da Play Store
- Para validar cobranca, prefira teste interno/fechado com build enviada pela Play Console
- Se mudar algum product ID na Play Console, atualize tambem `lib/config/premium_config.dart`
- O app calcula expiracao local para mensal e anual com base na data da compra restaurada/processada
- Backup em nuvem esta temporariamente fora desta versao
