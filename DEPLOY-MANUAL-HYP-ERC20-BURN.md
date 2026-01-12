# Guia: Deploy Manual do HypERC20 com Funcionalidade de Queima

Este guia explica como fazer o deploy manual do contrato HypERC20 com funcionalidade de queima (0.01%) usando Foundry, já que o Hyperlane CLI deploya a versão oficial sem essa funcionalidade.

## ⚠️ Problema Identificado

O Hyperlane CLI sempre deploya a versão **oficial** do HypERC20 do repositório do Hyperlane, que **NÃO tem** a funcionalidade de queima. O código local tem a queima, mas o CLI não usa esse código.

## Solução: Deploy Manual com Foundry

### Pré-requisitos

1. **Foundry instalado**:
   ```bash
   curl -L https://foundry.paradigm.xyz | bash
   foundryup
   ```

2. **Variáveis de ambiente**:
   ```bash
   export PRIVATE_KEY="0x819b680e3578eac4f79b8fde643046e88f3f9bb10a3ce1424e3642798ef39b42"
   export RPC_URL="https://bsc-testnet.publicnode.com"
   ```

### Passo 1: Compilar o Contrato

```bash
cd ~/smart-hyperlane-monorepo/solidity

# Compilar contratos
forge build
```

### Passo 2: Executar o Script de Deploy

```bash
# Executar o script de deploy
forge script script/DeployHypERC20WithBurn.s.sol:DeployHypERC20WithBurn \
  --rpc-url $RPC_URL \
  --broadcast \
  --verify \
  --legacy \
  -vvvv
```

### Passo 3: Configurar no Hyperlane

Após o deploy, você precisa:

1. **Registrar o contrato no registry do Hyperlane**
2. **Configurar os routers remotos**
3. **Configurar o ISM**

## Alternativa: Usar o Contrato Deployado Manualmente

Se você já fez o deploy manual, pode usar o endereço do contrato no arquivo de configuração:

```yaml
bsctestnet:
  type: synthetic
  # Use foreignDeployment para referenciar um contrato já deployado
  foreignDeployment: "0xSEU_CONTRATO_DEPLOYADO_MANUALMENTE"
  name: "upusd"
  symbol: "upusd"
  decimals: 6
  initialSupply: 15000000000
  owner: "0x8BD456605473ad4727ACfDCA0040a0dBD4be2DEA"
  mailbox: "0xF9F6F5646F478d5ab4e20B0F910C92F1CCC9Cc6D"
  interchainSecurityModule:
    type: messageIdMultisigIsm
    validators:
      - "0x242d8a855a8c932dec51f7999ae7d1e48b10c95e"
      - "0xf620f5e3d25a3ae848fec74bccae5de3edcd8796"
      - "0x1f030345963c54ff8229720dd3a711c15c554aeb"
    threshold: 2
```

## ⚠️ IMPORTANTE

O deploy manual cria um contrato standalone, mas para funcionar completamente com o Hyperlane, você ainda precisa:

1. Configurar os routers remotos
2. Configurar o ISM
3. Registrar no registry

O script de deploy manual cria o contrato, mas você precisará fazer a configuração adicional manualmente ou usar o CLI do Hyperlane para configurar os routers.
