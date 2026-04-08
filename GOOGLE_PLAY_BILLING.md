# Google Play Billing

## Produto configurado no app

- Product ID: `br.com.limitemei.premium`
- Tipo recomendado na Play Console: produto no app nao consumivel

O codigo usa esse ID em `lib/config/premium_config.dart`.

## O que ja esta integrado

- consulta de disponibilidade da loja
- busca do produto configurado
- inicio da compra do Premium
- restauracao de compras
- persistencia local do entitlement Premium apos compra/restauracao
- liberacao das telas pagas com base no entitlement ativo

## O que configurar na Play Console

1. Acesse seu app em `https://play.google.com/console`
2. Entre em `Monetizar > Produtos > Produtos no app`
3. Crie o produto com o ID `br.com.limitemei.premium`
4. Defina nome, descricao e preco
5. Ative o produto
6. Publique a alteracao da configuracao no track de teste que voce estiver usando

## Como validar

1. Instale uma build assinada com a mesma chave de upload usada no app
2. Adicione a conta de teste de licenciamento na Play Console
3. Publique o app em teste interno ou fechado
4. Baixe o app pela Play Store nessa conta de teste
5. Toque em `Assinar Premium`
6. Confirme que a compra libera os recursos Premium
7. Reinstale o app e use `Restaurar compra`

## Observacoes importantes

- O fluxo de compra real da Google Play nao funciona de forma confiavel em `flutter run` fora da Play Store
- Para validar cobranca, prefira teste interno/fechado com build enviada pela Play Console
- Se mudar o product ID na Play Console, atualize tambem `lib/config/premium_config.dart`
- O Premium atual esta modelado como compra vitalicia, sem expiracao
- Backup em nuvem esta temporariamente fora desta versao
