# Guia Completo: Deploy e Gerenciamento de Token Sintético na Optimism

Este guia fornece instruções completas para fazer deploy, gerenciar supply, consultar informações e transferir tokens sintéticos (HypERC20) na Optimism Mainnet.

## 📋 Índice

1. [Deploy do Contrato Sintético](#1-deploy-do-contrato-sintético)
2. [Aumentar o Supply do Token](#2-aumentar-o-supply-do-token)
3. [Consultar Saldo de uma Carteira](#3-consultar-saldo-de-uma-carteira)
4. [Consultar Owner do Contrato](#4-consultar-owner-do-contrato)
5. [Transferir Tokens para Outra Carteira](#5-transferir-tokens-para-outra-carteira)
6. [Referência dos Scripts](#referência-dos-scripts)

---

## 1. Deploy do Contrato Sintético

### Pré-requisitos

- Foundry instalado (`forge`, `cast`)
- Chave privada com saldo suficiente de ETH na Optimism
- Acesso à Optimism Mainnet

### Executar Deploy

```bash
cd ~/smart-hyperlane-monorepo
bash scripts/deploy-hyp-erc20-optimism-completo.sh
```

### O que o script faz:

1. ✅ Verifica se o Foundry está instalado
2. ✅ Verifica saldo da wallet
3. ✅ Compila os contratos
4. ✅ Faz deploy do HypERC20 sintético
5. ✅ Cria automaticamente o arquivo de configuração warp

### Contratos Deployados:

- **ProxyAdmin**: Gerencia upgrades do contrato
- **Implementation**: Implementação do HypERC20
- **Proxy (Token)**: Endereço do token que será usado

### Arquivo de Configuração Warp Criado:

O script cria automaticamente:
```
environments/mainnet/warp-routes/upusd-optimism/warp-route-deployment.yaml
```

Este arquivo é necessário para conectar o token com outras chains via Hyperlane CLI.

---

## 2. Aumentar o Supply do Token

Para aumentar o supply do token, é necessário fazer upgrade do contrato para adicionar a função `mint`.

### Executar Upgrade e Mint

```bash
cd ~/smart-hyperlane-monorepo
bash scripts/mint-additional-supply-optimism.sh
```

### O que o script faz:

1. ✅ Faz deploy da nova implementation com função `mint`
2. ✅ Faz upgrade do proxy para a nova implementation
3. ✅ Executa o mint dos tokens adicionais
4. ✅ Verifica o novo supply

### Exemplo: Aumentar de 15 bilhões para 150 bilhões

O script está configurado para mintar 135 bilhões adicionais (totalizando 150 bilhões).

Para ajustar a quantidade, edite o arquivo:
```
solidity/script/MintAdditionalSupplyOptimism.s.sol
```

Altere a variável `additionalSupply` na linha 27.

### ⚠️ Importante:

- O upgrade pode ser feito pelo **owner do ProxyAdmin**
- O mint deve ser feito pelo **owner do token**
- Se o deployer não for o owner do token, o mint precisa ser feito separadamente

---

## 3. Consultar Saldo de uma Carteira

### Usando Cast

```bash
cast call <TOKEN_ADDRESS> \
  "balanceOf(address)(uint256)" \
  <WALLET_ADDRESS> \
  --rpc-url https://mainnet.optimism.io
```

### Exemplo:

```bash
cast call 0x7d637C37828c01ad6241624FfAAd7B48eb3cc516 \
  "balanceOf(address)(uint256)" \
  0x52DEC0991bF0B44E1d292443E27981f217Ee400F \
  --rpc-url https://mainnet.optimism.io
```

### Resultado:

O resultado será em wei (menor unidade). Para converter:
- 1 token = 10^6 wei (decimals: 6)
- 150000000000 = 150 bilhões de tokens

---

## 4. Consultar Owner do Contrato

### Usando Cast

```bash
cast call <TOKEN_ADDRESS> \
  "owner()(address)" \
  --rpc-url https://mainnet.optimism.io
```

### Exemplo:

```bash
cast call 0x7d637C37828c01ad6241624FfAAd7B48eb3cc516 \
  "owner()(address)" \
  --rpc-url https://mainnet.optimism.io
```

### Outras Consultas Úteis:

#### Consultar Total Supply

```bash
cast call <TOKEN_ADDRESS> \
  "totalSupply()(uint256)" \
  --rpc-url https://mainnet.optimism.io
```

#### Consultar Nome do Token

```bash
cast call <TOKEN_ADDRESS> \
  "name()(string)" \
  --rpc-url https://mainnet.optimism.io
```

#### Consultar Símbolo do Token

```bash
cast call <TOKEN_ADDRESS> \
  "symbol()(string)" \
  --rpc-url https://mainnet.optimism.io
```

#### Consultar Decimals

```bash
cast call <TOKEN_ADDRESS> \
  "decimals()(uint8)" \
  --rpc-url https://mainnet.optimism.io
```

---

## 5. Transferir Tokens para Outra Carteira

### Usando Cast

```bash
cast send <TOKEN_ADDRESS> \
  "transfer(address,uint256)" \
  <DESTINO_ADDRESS> \
  <QUANTIDADE> \
  --rpc-url https://mainnet.optimism.io \
  --private-key <PRIVATE_KEY> \
  --legacy
```

### Exemplo:

```bash
cast send 0x7d637C37828c01ad6241624FfAAd7B48eb3cc516 \
  "transfer(address,uint256)" \
  0x52DEC0991bF0B44E1d292443E27981f217Ee400F \
  150000000000 \
  --rpc-url https://mainnet.optimism.io \
  --private-key 0xab38f039a24acdbeef8d2270bb8887a235f3271f15140777ad08dd72511a36f3 \
  --legacy
```

### ⚠️ Taxa de Queima

O contrato HypERC20 implementa uma taxa de queima de **0.01%** em transferências locais.

**Exemplo:**
- Transferência de: 150,000,000,000 tokens
- Taxa de queima (0.01%): 15,000,000 tokens
- Valor recebido: 149,985,000,000 tokens

### Verificar Transferência

Após a transferência, verifique o saldo do destinatário:

```bash
cast call <TOKEN_ADDRESS> \
  "balanceOf(address)(uint256)" \
  <DESTINO_ADDRESS> \
  --rpc-url https://mainnet.optimism.io
```

---

## 📝 Configurações da Optimism Mainnet

### Endereços Oficiais

- **Mailbox**: `0xd4C1905BB1D26BC93DAC913e13CaCC278CdCC80D`
- **ISM (Interchain Security Module)**: `0x38164E63A4F67b32b2EfF4b45aCC1f2EE9b77b07`
- **IGP (Interchain Gas Paymaster)**: `0xD8A76C4D91fCbB7Cc8eA795DFDF870E48368995C`
- **RPC URL**: `https://mainnet.optimism.io`
- **Chain ID**: `10`

### Validators (MessageIdMultisig ISM)

- `0x20349eadc6c72e94ce38268b96692b1a5c20de4f` - Abacus Works
- `0x0d4c1394a255568ec0ecd11795b28d1bda183ca4` - Tessellated
- `0xd8c1cCbfF28413CE6c6ebe11A3e29B0D8384eDbB` - Enigma
- `0x1b9e5f36c4bfdb0e3f0df525ef5c888a4459ef99` - Imperator
- `0xf9dfaa5c20ae1d84da4b2696b8dc80c919e48b12` - Luganodes
- `0x5450447aee7b544c462c9352bef7cad049b0c2dc` - Zee Prime

**Threshold recomendado**: 4 de 6 validators

---

## 🔗 Referência dos Scripts

Para informações detalhadas sobre os scripts disponíveis, consulte:

📄 **[REFERENCIA-SCRIPTS-OPTIMISM.md](./REFERENCIA-SCRIPTS-OPTIMISM.md)**

Este documento contém:
- Lista completa de todos os scripts
- Descrição de cada script
- Parâmetros e configurações
- Exemplos de uso
- Comandos Cast úteis
- Estrutura dos contratos

---

## 🔍 Exploradores

- **Optimism Explorer**: https://optimistic.etherscan.io
- **OP Mainnet Explorer**: https://optimism.blockscout.com

### Verificar Contrato no Explorer

Substitua `<TOKEN_ADDRESS>` pelo endereço do seu contrato:
```
https://optimistic.etherscan.io/token/<TOKEN_ADDRESS>
```

---

## ⚠️ Importantes Lembretes

1. **Taxa de Queima**: O contrato aplica 0.01% de queima em transferências locais
2. **Owner vs Deployer**: O owner do token pode ser diferente do deployer
3. **ProxyAdmin**: Necessário para fazer upgrades do contrato
4. **Gas**: Sempre verifique se tem ETH suficiente para as transações
5. **Chaves Privadas**: Nunca compartilhe suas chaves privadas

---

## 📚 Próximos Passos

Após o deploy e configuração:

1. **Conectar com outras chains** usando Hyperlane CLI:
   ```bash
   hyperlane warp deploy \
     --config environments/mainnet/warp-routes/upusd-optimism/warp-route-deployment.yaml
   ```

2. **Adicionar liquidez** em DEXs da Optimism

3. **Integrar em aplicações** DeFi

---

## 🆘 Troubleshooting

### Erro: "execution reverted"
- Verifique se você é o owner do contrato
- Verifique se tem saldo suficiente
- Verifique se os parâmetros estão corretos

### Erro: "Stack too deep"
- O contrato tem muitas variáveis locais
- Simplifique o código ou use `--via-ir` na compilação

### Erro: "Failed to estimate gas"
- Verifique se a função existe no contrato
- Verifique se você tem permissão para executar a função
- Verifique se tem ETH suficiente para gas

---

## 📞 Suporte

Para mais informações, consulte:
- [Documentação do Hyperlane](https://docs.hyperlane.xyz/)
- [Documentação da Optimism](https://docs.optimism.io/)

---

**Última atualização**: Janeiro 2025
