# Guia Completo: Criar Warp Route Sintético no Ethereum

Este guia fornece instruções passo a passo para criar um warp route sintético no Ethereum (testnet ou mainnet) seguindo a mesma lógica do deploy na Solana. O contrato `HypERC20` já inclui funcionalidade de queima (burn) automática de 0.01% em transferências locais.

## Dados do Seu Deploy

- **Token**: 
  - Name: `Luna Classic`
  - Symbol: `wwwwLUNC`
  - Decimals: `18` (padrão Ethereum)
  - Type: `synthetic`
- **Funcionalidade de Queima**: 
  - Taxa de queima: `0.01%` (1/10000) em transferências locais
  - Implementada automaticamente no contrato `HypERC20`
  - Não afeta transferências cross-chain

---

## Passo 1: Preparar Configuração do Token

### 1.1. Criar Diretório de Configuração

```bash
cd ~/smart-hyperlane-monorepo

# Criar diretório para a configuração
mkdir -p environments/testnet/warp-routes/lunc-ethereum
```

### 1.2. Criar Arquivo de Configuração do Token

**⚠️ IMPORTANTE**: O arquivo de configuração deve ser em formato YAML (não JSON como na Solana), seguindo o padrão do [guia oficial](https://github.com/igorv43/cw-hyperlane/blob/main/WARP-ROUTES-TESTNET.md):

```bash
cat > environments/testnet/warp-routes/lunc-ethereum/warp-route-deployment.yaml << 'EOF'
---
# Configuração do Warp Route Sintético no Ethereum
# Token com funcionalidade de queima automática (0.01% em transferências locais)
# Baseado em: https://github.com/igorv43/cw-hyperlane/blob/main/WARP-ROUTES-TESTNET.md

ethereum:
  isNft: false  # Token fungível (false) ou NFT (true)
  type: synthetic
  
  # Metadados do token (obrigatórios para synthetic)
  name: "Luna Classic"
  symbol: "wwwwLUNC"
  decimals: 18  # Padrão para Ethereum (pode ser 6 para compatibilidade com Terra Classic)
  totalSupply: 0  # Supply inicial - pode ser 0 para tokens sintéticos
  
  # Owner do contrato (obrigatório - substitua pelo seu endereço)
  owner: "0xYOUR_ETHEREUM_ADDRESS_HERE"
  
  # Endereço do Mailbox (opcional - será preenchido automaticamente se não especificado)
  # mailbox: "0x35231d4c2D8B8ADcB5617Aea1C3DF4fB04F6a8F4"
  
  # Interchain Gas Paymaster (opcional)
  # interchainGasPaymaster: "0xYourIGPAddress"
  
  # Interchain Security Module (ISM) - Configuração de segurança
  # Define quais validadores devem assinar as mensagens cross-chain
  interchainSecurityModule:
    type: messageIdMultisigIsm  # Tipo de ISM: multisig baseado em message ID
    validators:  # Lista de endereços dos validadores (hexadecimal sem 0x)
      - "242d8a855a8c932dec51f7999ae7d1e48b10c95e"
      - "f620f5e3d25a3ae848fec74bccae5de3edcd8796"
      - "1f030345963c54ff8229720dd3a711c15c554aeb"
    threshold: 2  # Número mínimo de assinaturas necessárias (2 de 3 validadores)
EOF
```

**⚠️ IMPORTANTE**: 
- **Substitua `0xYOUR_ETHEREUM_ADDRESS_HERE`** pelo seu endereço Ethereum real
- Para tokens sintéticos, `totalSupply` pode ser `0` (sem supply inicial)
- O token será mintado conforme necessário em transferências cross-chain
- A função de queima já está implementada no contrato `HypERC20`
- **Validadores**: Use os endereços dos validadores da sua rede (exemplo mostra validadores do Terra Classic Testnet)
- **Threshold**: Define quantas assinaturas são necessárias (ex: `2` significa que 2 de 3 validadores devem assinar)

### 1.3. Verificar Arquivo Criado

```bash
cat environments/testnet/warp-routes/lunc-ethereum/warp-route-deployment.yaml
```

---

## Passo 2: Verificar Pré-requisitos

### 2.1. Verificar Instalação do CLI

```bash
# Verificar se o CLI está instalado
cd ~/smart-hyperlane-monorepo/typescript/cli
npm list -g | grep hyperlane || echo "CLI não instalado globalmente"

# Ou usar o CLI local
pnpm install
```

### 2.2. Verificar Configuração do Registry

```bash
# Verificar se o registry existe
ls -la ~/.hyperlane/registry

# Se não existir, criar
mkdir -p ~/.hyperlane/registry
```

### 2.3. Verificar Chave Privada

```bash
# Verificar se você tem uma chave privada configurada
# Você precisará de uma chave privada com ETH para gas fees

# Exemplo: exportar chave privada (NUNCA compartilhe esta chave!)
# export PRIVATE_KEY="0xYourPrivateKey"
```

---

## Passo 3: Deploy do Warp Route Sintético

### 3.1. Preparar Variáveis de Ambiente

```bash
# Configurar variáveis
WARP_ROUTE_NAME="lunc-ethereum"
CONFIG_FILE="environments/testnet/warp-routes/lunc-ethereum/warp-route-deployment.yaml"
REGISTRY_PATH="~/.hyperlane/registry"
PRIVATE_KEY="0xYourPrivateKey"  # Substitua pela sua chave privada

# Para testnet (Sepolia, Goerli, etc.)
# Para mainnet, use a rede apropriada
```

### 3.2. Deploy do Warp Route

**⚠️ IMPORTANTE**: O deploy no Ethereum usa o CLI TypeScript, diferente da Solana que usa Rust.

```bash
cd ~/smart-hyperlane-monorepo/typescript/cli

# Instalar dependências se necessário
pnpm install

# Deploy do warp route sintético
pnpm hyperlane warp deploy \
  --config ${CONFIG_FILE} \
  --registry ${REGISTRY_PATH} \
  --key ${PRIVATE_KEY} \
  --yes \
  --verbosity debug
```

**Alternativa usando npx (se instalado globalmente):**

```bash
hyperlane warp deploy \
  --config environments/testnet/warp-routes/lunc-ethereum/warp-route-deployment.yaml \
  --registry ~/.hyperlane/registry \
  --key ${PRIVATE_KEY} \
  --yes
```

**Saída esperada:**
```
Deploying Warp Route contracts...
✓ Deployed HypERC20Synthetic to ethereum at 0x...
✓ Initialized token with name: Luna Classic, symbol: wwwwLUNC
✓ Enrolled remote routers...
✓ Configured destination gas amounts...
✅ Warp route deployment complete!
```

### 3.3. Verificar Deploy

```bash
# Verificar o contrato deployado
# O endereço do contrato será exibido na saída do deploy

CONTRACT_ADDRESS="0x..."  # Substitua pelo endereço retornado

# Verificar no Etherscan (testnet)
# https://sepolia.etherscan.io/address/${CONTRACT_ADDRESS}
```

---

## Passo 4: Entender a Configuração do ISM (Interchain Security Module)

### 4.1. O que é o ISM?

O ISM (Interchain Security Module) é responsável por validar mensagens cross-chain. Ele define quais validadores devem assinar as mensagens antes que sejam aceitas.

### 4.2. Estrutura da Configuração do ISM

```yaml
interchainSecurityModule:
  type: messageIdMultisigIsm  # Tipo de ISM
  validators:                  # Lista de validadores
    - "242d8a855a8c932dec51f7999ae7d1e48b10c95e"
    - "f620f5e3d25a3ae848fec74bccae5de3edcd8796"
    - "1f030345963c54ff8229720dd3a711c15c554aeb"
  threshold: 2                 # Mínimo de assinaturas necessárias
```

**Campos explicados:**

| Campo | Descrição | Exemplo |
|-------|-----------|---------|
| `type` | Tipo de ISM. `messageIdMultisigIsm` requer assinaturas de múltiplos validadores | `messageIdMultisigIsm` |
| `validators` | Array de endereços dos validadores em hexadecimal (sem prefixo `0x`) | Lista de endereços hex |
| `threshold` | Número mínimo de validadores que devem assinar uma mensagem | `2` (2 de 3 validadores) |

**⚠️ IMPORTANTE sobre Validadores:**
- Os endereços devem estar em formato hexadecimal, **sem o prefixo `0x`**
- Use os endereços dos validadores da sua rede (exemplo mostra validadores do Terra Classic Testnet)
- O `threshold` deve ser menor ou igual ao número de validadores
- Exemplo: 3 validadores com threshold 2 = 2 de 3 validadores devem assinar

## Passo 5: Configurar ISM (Interchain Security Module)

### 4.1. ISM Configurado no Deploy

O ISM (Interchain Security Module) já está configurado no arquivo YAML durante o deploy. A configuração inclui:

- **Tipo**: `messageIdMultisigIsm` - Requer assinaturas de múltiplos validadores
- **Validadores**: Lista de endereços dos validadores (sem prefixo `0x`)
- **Threshold**: Número mínimo de assinaturas necessárias

**Exemplo de configuração:**
```yaml
interchainSecurityModule:
  type: messageIdMultisigIsm
  validators:
    - "242d8a855a8c932dec51f7999ae7d1e48b10c95e"
    - "f620f5e3d25a3ae848fec74bccae5de3edcd8796"
    - "1f030345963c54ff8229720dd3a711c15c554aeb"
  threshold: 2
```

### 4.2. Atualizar Validadores Após Deploy

Se você precisar adicionar ou remover validadores após o deploy, use o comando `hyperlane warp apply`:

```bash
# 1. Criar arquivo warp.json com o token deployado
cat > warp/warp.json << EOF
{
  "tokens": [
    {
      "chainName": "ethereum",
      "standard": "ERC20",
      "addressOrDenom": "0xYOUR_DEPLOYED_TOKEN_ADDRESS",
      "name": "Luna Classic",
      "symbol": "wwwwLUNC",
      "decimals": 18
    }
  ]
}
EOF

# 2. Atualizar o arquivo de configuração com novos validadores
# Edite warp-route-deployment.yaml e adicione/remova validadores

# 3. Aplicar as mudanças
pnpm hyperlane warp apply \
  --config ${CONFIG_FILE} \
  --warp ./warp/warp.json \
  --key ${PRIVATE_KEY}
```

**Referência**: Veja a seção "Managing Validators on Existing Warp Routes" no [guia oficial](https://github.com/igorv43/cw-hyperlane/blob/main/WARP-ROUTES-TESTNET.md).

---

## Passo 6: Funcionalidade de Queima (Burn)

### 5.1. Como Funciona a Queima

O contrato `HypERC20` implementa automaticamente:

- **Taxa de queima**: `0.01%` (1/10000) em todas as transferências locais
- **Transferências cross-chain**: Não são afetadas pela queima
- **Evento emitido**: `BurnFeeApplied` quando a queima ocorre

### 5.2. Verificar Queima em Ação

```bash
# Após o deploy, você pode testar a funcionalidade de queima
# usando um script ou interagindo diretamente com o contrato

# Exemplo de transferência que acionará a queima:
# transfer(to, amount) - queima 0.01% do amount
# transferFrom(from, to, amount) - queima 0.01% do amount
```

### 5.3. Código do Contrato

A funcionalidade de queima está implementada em:
```solidity
// solidity/contracts/token/HypERC20.sol
// Linhas 100-161

function transfer(address to, uint256 amount) public virtual override returns (bool) {
    address owner = msg.sender;
    uint256 burnAmount = amount / BURN_RATE;  // 0.01%
    uint256 transferAmount = amount - burnAmount;
    
    if (burnAmount > 0) {
        _burn(owner, burnAmount);
        super._transfer(owner, to, transferAmount);
        emit BurnFeeApplied(owner, to, amount, burnAmount, transferAmount);
    } else {
        super._transfer(owner, to, amount);
    }
    return true;
}
```

---

## Passo 7: Linkar com Outras Chains

### 6.1. Adicionar Remote Routers

Para linkar o warp route com outras chains (ex: Terra Classic, Solana):

```bash
# Adicionar configuração para outras chains no mesmo arquivo YAML
cat >> environments/testnet/warp-routes/lunc-ethereum/warp-route-deployment.yaml << EOF

# Exemplo: Linkar com Terra Classic
# terraclassic:
#   type: synthetic
#   name: "Luna Classic"
#   symbol: "wwwwLUNC"
#   totalSupply: 0
EOF
```

### 6.2. Deploy Multi-Chain

```bash
# Deploy em múltiplas chains de uma vez
pnpm hyperlane warp deploy \
  --config environments/testnet/warp-routes/lunc-ethereum/warp-route-deployment.yaml \
  --registry ~/.hyperlane/registry \
  --key ${PRIVATE_KEY} \
  --yes
```

---

## Passo 8: Verificar Configuração Completa

### 7.1. Verificar Token Sintético

```bash
# Ler configuração do warp route
pnpm hyperlane warp read \
  --config ${CONFIG_FILE} \
  --chain ethereum
```

### 7.2. Verificar Funcionalidade de Queima

```bash
# Interagir com o contrato para testar a queima
# Use um script ou ferramenta como cast (Foundry) ou ethers.js

# Exemplo com cast (Foundry):
# cast send ${CONTRACT_ADDRESS} "transfer(address,uint256)" ${TO_ADDRESS} ${AMOUNT} \
#   --rpc-url https://sepolia.infura.io/v3/YOUR_KEY \
#   --private-key ${PRIVATE_KEY}

# Verificar eventos de queima no Etherscan
```

---

## Resumo dos Comandos

### Script Completo

```bash
#!/bin/bash
# criar-warp-ethereum.sh

set -e

# Variáveis
WARP_ROUTE_NAME="lunc-ethereum"
CONFIG_DIR="environments/testnet/warp-routes/${WARP_ROUTE_NAME}"
CONFIG_FILE="${CONFIG_DIR}/warp-route-deployment.yaml"
REGISTRY_PATH="~/.hyperlane/registry"
PRIVATE_KEY="0xYourPrivateKey"  # ⚠️ Substitua pela sua chave privada

echo "=== Passo 1: Criar Configuração do Token ==="
cd ~/smart-hyperlane-monorepo
mkdir -p ${CONFIG_DIR}

cat > ${CONFIG_FILE} << 'EOF'
---
ethereum:
  isNft: false
  type: synthetic
  name: "Luna Classic"
  symbol: "wwwwLUNC"
  decimals: 18
  totalSupply: 0
  owner: "0xYOUR_ETHEREUM_ADDRESS_HERE"
  interchainSecurityModule:
    type: messageIdMultisigIsm
    validators:
      - "242d8a855a8c932dec51f7999ae7d1e48b10c95e"
      - "f620f5e3d25a3ae848fec74bccae5de3edcd8796"
      - "1f030345963c54ff8229720dd3a711c15c554aeb"
    threshold: 2
EOF

echo "⚠️ IMPORTANTE: Edite o arquivo e substitua 0xYOUR_ETHEREUM_ADDRESS_HERE pelo seu endereço real"

echo "✅ Configuração do token criada"

echo ""
echo "=== Passo 2: Deploy do Warp Route Sintético ==="
cd typescript/cli

pnpm hyperlane warp deploy \
  --config ${CONFIG_FILE} \
  --registry ${REGISTRY_PATH} \
  --key ${PRIVATE_KEY} \
  --yes \
  --verbosity debug

echo "✅ Warp route sintético deployado"

echo ""
echo "=== Passo 3: Verificar Deploy ==="
echo "Verificando configuração do warp route..."
pnpm hyperlane warp read \
  --config ${CONFIG_FILE} \
  --chain ethereum

echo ""
echo "✅ Configuração completa!"
echo ""
echo "Próximos passos:"
echo "1. Anotar o endereço do contrato retornado no Passo 2"
echo "2. Verificar o contrato no Etherscan"
echo "3. Testar transferências locais (que acionarão a queima de 0.01%)"
echo "4. Linkar com outras chains se necessário"
```

---

## Troubleshooting

### Erro: "Missing mailbox address"

**Problema**: O Mailbox não foi configurado.

**Solução**: Adicione o endereço do Mailbox ao arquivo de configuração:

```yaml
ethereum:
  type: synthetic
  mailbox: "0xYourMailboxAddress"
  # ... resto da configuração
```

### Erro: "Insufficient funds"

**Problema**: Você não tem ETH suficiente para gas fees.

**Solução**: 
- Para testnet: Obtenha ETH de um faucet (Sepolia, Goerli, etc.)
- Para mainnet: Certifique-se de ter ETH suficiente

### Erro: "Invalid token config"

**Problema**: O arquivo de configuração está incorreto.

**Solução**: Verifique o formato YAML:

```bash
# Validar YAML
cat ${CONFIG_FILE} | yq eval '.' -  # Requer yq instalado
```

### Erro: "Contract already deployed"

**Problema**: O contrato já foi deployado anteriormente.

**Solução**: 
- Use `foreignDeployment` no arquivo de configuração para referenciar um contrato existente
- Ou remova o contrato existente e faça um novo deploy

### Erro: "Invalid validator address"

**Problema**: O endereço do validator não está no formato correto.

**Solução**: 
- Use endereços hexadecimais de exatamente 20 bytes (40 caracteres)
- **NÃO inclua** o prefixo `0x` no início
- Exemplo correto: `242d8a855a8c932dec51f7999ae7d1e48b10c95e`
- Exemplo incorreto: `0x242d8a855a8c932dec51f7999ae7d1e48b10c95e`

### Erro: "Threshold exceeds number of validators"

**Problema**: O threshold é maior que o número de validadores.

**Solução**: 
- O `threshold` deve ser menor ou igual ao número de validadores
- Exemplo: Se você tem 3 validadores, o threshold pode ser 1, 2 ou 3 (não pode ser 4)

---

## Diferenças entre Solana e Ethereum

| Aspecto | Solana | Ethereum |
|---------|--------|----------|
| **Formato de Config** | JSON | YAML |
| **CLI** | Rust (`cargo run`) | TypeScript (`pnpm hyperlane`) |
| **Contrato** | Program ID (base58) | Endereço (hex) |
| **Gas Fees** | SOL (lamports) | ETH (wei) |
| **Decimals** | 9 (padrão) | 18 (padrão) |
| **Queima** | Não implementada | 0.01% automático |

---

## Próximos Passos

Após completar este guia:

1. **Informações Importantes**:
   - Endereço do contrato: Anotar o endereço retornado no deploy
   - Funcionalidade de queima: Já implementada (0.01% em transferências locais)

2. **Linkar com Outras Chains**:
   - Adicionar outras chains ao arquivo de configuração
   - Fazer deploy em múltiplas chains
   - Configurar routers remotos

3. **Testar Funcionalidades**:
   - Testar transferências locais (verificar queima)
   - Testar transferências cross-chain
   - Verificar eventos no Etherscan

---

## Referências

- [Hyperlane Warp Routes Documentation](https://docs.hyperlane.xyz/docs/guides/warp-routes/overview)
- [WARP-ROUTES-TESTNET.md](https://github.com/igorv43/cw-hyperlane/blob/main/WARP-ROUTES-TESTNET.md) - Guia oficial de Warp Routes (referência principal)
- [HypERC20 Contract](../solidity/contracts/token/HypERC20.sol) - Contrato com funcionalidade de queima
- [CRIAR-WARP-SOLANA-COMPLETO.md](./CRIAR-WARP-SOLANA-COMPLETO.md) - Guia completo para Solana
- [Hyperlane Ethereum Documentation](https://docs.hyperlane.xyz/docs/guides/warp-routes/evm/evm-warp-route-guide)
