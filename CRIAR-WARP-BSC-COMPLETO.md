# Guia Completo: Criar Warp Route Sintético no BSC (Binance Smart Chain)

Este guia fornece instruções passo a passo para criar um warp route sintético no BSC Testnet seguindo a mesma lógica do deploy na Solana. O contrato `HypERC20` já inclui funcionalidade de queima (burn) automática de 0.01% em transferências locais.

## Dados do Seu Deploy

- **Token**: 
  - Name: `Luna Classic`
  - Symbol: `wwwwLUNC`
  - Decimals: `6` (compatível com Terra Classic) ou `18` (padrão BSC)
  - Type: `synthetic`
- **Chain**: BSC Testnet (Domain ID: 97)
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
mkdir -p environments/testnet/warp-routes/lunc-bsc
```

### 1.2. Criar Arquivo de Configuração do Token

**⚠️ IMPORTANTE**: O arquivo de configuração deve ser em formato YAML, seguindo o padrão do [guia oficial](https://github.com/igorv43/cw-hyperlane/blob/main/WARP-ROUTES-TESTNET.md):

```bash
cat > environments/testnet/warp-routes/lunc-bsc/warp-route-deployment.yaml << 'EOF'
---
# Configuração do Warp Route Sintético no BSC Testnet
# Token com funcionalidade de queima automática (0.01% em transferências locais)
# 
# Este arquivo segue a mesma lógica do deploy na Solana, mas adaptado para BSC
# O contrato HypERC20 já implementa a funcionalidade de queima
# 
# Baseado no exemplo: https://github.com/igorv43/cw-hyperlane/blob/main/WARP-ROUTES-TESTNET.md

bsctestnet:
  isNft: false  # Token fungível (false) ou NFT (true)
  type: synthetic
  
  # Metadados do token (obrigatórios para synthetic)
  name: "Luna Classic"
  symbol: "wwwwLUNC"
  decimals: 6  # 6 para compatibilidade com Terra Classic, ou 18 para padrão BSC
  totalSupply: 0  # Supply inicial - pode ser 0 para tokens sintéticos
  
  # Owner do contrato (obrigatório - substitua pelo seu endereço BSC)
  owner: "0xYOUR_BSC_ADDRESS_HERE"
  
  # Endereço do Mailbox (opcional - será preenchido automaticamente se não especificado)
  # O CLI tentará encontrar automaticamente no registry
  # BSC Testnet Mailbox: 0xF9F6F5646F478d5ab4e20B0F910C92F1CCC9Cc6D
  # mailbox: "0xF9F6F5646F478d5ab4e20B0F910C92F1CCC9Cc6D"
  
  # Interchain Gas Paymaster (opcional)
  # BSC Testnet IGP: 0x0dD20e410bdB95404f71c5a4e7Fa67B892A5f949
  # interchainGasPaymaster: "0x0dD20e410bdB95404f71c5a4e7Fa67B892A5f949"
  
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
- **Substitua `0xYOUR_BSC_ADDRESS_HERE`** pelo seu endereço BSC real
- Para tokens sintéticos, `totalSupply` pode ser `0` (sem supply inicial)
- O token será mintado conforme necessário em transferências cross-chain
- A função de queima já está implementada no contrato `HypERC20`
- **Validadores**: Use os endereços dos validadores da sua rede (exemplo mostra validadores do Terra Classic Testnet)
- **Threshold**: Define quantas assinaturas são necessárias (ex: `2` significa que 2 de 3 validadores devem assinar)
- **Decimals**: Use `6` para manter compatibilidade com Terra Classic, ou `18` para padrão BSC

### 1.3. Verificar Arquivo Criado

```bash
cat environments/testnet/warp-routes/lunc-bsc/warp-route-deployment.yaml
```

---

## Passo 2: Verificar Pré-requisitos

### 2.1. Verificar Instalação do CLI

```bash
# Verificar se o CLI está instalado
npm list -g | grep hyperlane || echo "CLI não instalado globalmente"

# Instalar globalmente se necessário
npm install -g @hyperlane-xyz/cli

# Verificar versão
hyperlane --version
```

### 2.2. Verificar Configuração do Registry

```bash
# Verificar se o registry existe
ls -la ~/.hyperlane/registry

# Se não existir, criar
mkdir -p ~/.hyperlane/registry
```

### 2.3. Verificar Chave Privada e BNB

```bash
# Verificar se você tem uma chave privada configurada
# Você precisará de uma chave privada com BNB para gas fees no BSC Testnet

# Obter BNB Testnet de um faucet:
# https://testnet.bnbchain.org/faucet-smart
# https://www.bnbchain.org/en/testnet-faucet

# Exemplo: exportar chave privada (NUNCA compartilhe esta chave!)
# export BSC_PRIVATE_KEY="0xYourPrivateKey"
```

---

## Passo 3: Deploy do Warp Route Sintético

### 3.1. ⚠️ IMPORTANTE: Deploy com Funcionalidade de Queima

**PROBLEMA**: O Hyperlane CLI sempre deploya a versão **oficial** do HypERC20 do pacote npm, que **NÃO tem** a funcionalidade de queima (0.01%).

**SOLUÇÃO**: Para ter a funcionalidade de queima, você precisa fazer o **deploy manual** usando Foundry do contrato local que tem a queima implementada.

### 3.2. Opção A: Deploy Manual com Queima (Recomendado)

Se você precisa da funcionalidade de queima (0.01% em transferências locais):

```bash
cd ~/smart-hyperlane-monorepo/solidity

# 1. Instalar dependências do Soldeer (gerenciador de dependências do Foundry)
forge soldeer install

# 2. Compilar contratos
forge build

# 3. Executar deploy manual com queima
export PRIVATE_KEY="0x819b680e3578eac4f79b8fde643046e88f3f9bb10a3ce1424e3642798ef39b42"

forge script script/DeployHypERC20WithBurn.s.sol:DeployHypERC20WithBurn \
  --rpc-url https://bsc-testnet.publicnode.com \
  --broadcast \
  --legacy \
  -vvv
```

**O script irá:**
- ✅ Deploy do ProxyAdmin
- ✅ Deploy da implementação HypERC20 **com funcionalidade de queima**
- ✅ Deploy do Proxy (endereço do token)
- ✅ Inicialização com supply inicial de 15.000.000.000 tokens

**Anotar o endereço do Proxy** retornado (esse é o endereço do token com queima).

### 3.3. Opção B: Deploy via Hyperlane CLI (Sem Queima)

Se você não precisa da funcionalidade de queima, pode usar o CLI normalmente:

```bash
# Configurar variáveis
WARP_ROUTE_NAME="lunc-bsc"
CONFIG_FILE="environments/testnet/warp-routes/lunc-bsc/warp-route-deployment.yaml"
REGISTRY_PATH="~/.hyperlane/registry"
BSC_PRIVATE_KEY="0xYourPrivateKey"  # ⚠️ Substitua pela sua chave privada

# Deploy do warp route sintético no BSC Testnet
npx @hyperlane-xyz/cli warp deploy \
  --config ${CONFIG_FILE} \
  --registry ${REGISTRY_PATH} \
  --private-key ${BSC_PRIVATE_KEY} \
  --yes \
  --verbosity debug
```

**⚠️ ATENÇÃO**: Este método deploya a versão oficial **SEM** funcionalidade de queima.

**Alternativa usando npx (sem instalação global):**

```bash
npx @hyperlane-xyz/cli warp deploy \
  --config environments/testnet/warp-routes/lunc-bsc/warp-route-deployment.yaml \
  --registry ~/.hyperlane/registry \
  --private-key ${BSC_PRIVATE_KEY} \
  --yes
```

**Saída esperada:**
```
Deploying Warp Route contracts...
✓ Deployed HypERC20Synthetic to bsctestnet at 0x...
✓ Initialized token with name: Luna Classic, symbol: wwwwLUNC
✓ Enrolled remote routers...
✓ Configured destination gas amounts...
✅ Warp route deployment complete!
```

### 3.4. Verificar Deploy

```bash
# Verificar o contrato deployado
# O endereço do contrato será exibido na saída do deploy

CONTRACT_ADDRESS="0x..."  # Substitua pelo endereço retornado

# Verificar supply total (deve ser 15000000000)
cast call ${CONTRACT_ADDRESS} \
  "totalSupply()" \
  --rpc-url https://bsc-testnet.publicnode.com

# Verificar saldo do owner (deve ter 15000000000)
cast call ${CONTRACT_ADDRESS} \
  "balanceOf(address)" \
  0x8BD456605473ad4727ACfDCA0040a0dBD4be2DEA \
  --rpc-url https://bsc-testnet.publicnode.com

# Verificar no BscScan Testnet
# https://testnet.bscscan.com/address/${CONTRACT_ADDRESS}
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

### 5.1. ISM Configurado no Deploy

O ISM (Interchain Security Module) já está configurado no arquivo YAML durante o deploy. A configuração inclui:

- **Tipo**: `messageIdMultisigIsm` - Requer assinaturas de múltiplos validadores
- **Validadores**: Lista de endereços dos validadores (sem prefixo `0x`)
- **Threshold**: Número mínimo de assinaturas necessárias

### 5.2. Atualizar Validadores Após Deploy

Se você precisar adicionar ou remover validadores após o deploy, use o comando `hyperlane warp apply`:

```bash
# 1. Criar arquivo warp.json com o token deployado
cat > warp/warp.json << EOF
{
  "tokens": [
    {
      "chainName": "bsctestnet",
      "standard": "ERC20",
      "addressOrDenom": "0xYOUR_DEPLOYED_TOKEN_ADDRESS",
      "name": "Luna Classic",
      "symbol": "wwwwLUNC",
      "decimals": 6
    }
  ]
}
EOF

# 2. Atualizar o arquivo de configuração com novos validadores
# Edite warp-route-deployment.yaml e adicione/remova validadores

# 3. Aplicar as mudanças
hyperlane warp apply \
  --config ${CONFIG_FILE} \
  --warp ./warp/warp.json \
  --private-key ${BSC_PRIVATE_KEY}
```

**Referência**: Veja a seção "Managing Validators on Existing Warp Routes" no [guia oficial](https://github.com/igorv43/cw-hyperlane/blob/main/WARP-ROUTES-TESTNET.md).

---

## Passo 6: Funcionalidade de Queima (Burn)

### 6.1. Como Funciona a Queima

O contrato `HypERC20` implementa automaticamente:

- **Taxa de queima**: `0.01%` (1/10000) em todas as transferências locais
- **Transferências cross-chain**: Não são afetadas pela queima
- **Evento emitido**: `BurnFeeApplied` quando a queima ocorre

### 6.2. Testar Transferência e Verificar Queima

**⚠️ IMPORTANTE**: A funcionalidade de queima só funciona se você fez o **deploy manual** usando Foundry (Opção A do Passo 3). Se usou o Hyperlane CLI (Opção B), o contrato não tem queima.

#### 6.2.1. Transferir Tokens para Testar

```bash
# Substitua <TOKEN_ADDRESS> pelo endereço do seu contrato
# Exemplo: 0xC61134c6794043db11120018BbFDD2F4280F2268 (contrato com queima)

# Transferir 100 tokens (com 6 decimais = 100000000)
cast send <TOKEN_ADDRESS> \
  "transfer(address,uint256)" \
  0x867f9CE9F0D7218b016351CB6122406E6D247a5e \
  100000000 \
  --rpc-url https://bsc-testnet.publicnode.com \
  --private-key 0x819b680e3578eac4f79b8fde643046e88f3f9bb10a3ce1424e3642798ef39b42 \
  --legacy
```

#### 6.2.2. Verificar Queima na Transação

Após a transferência, verifique no BscScan:

1. **Acesse a transação no BscScan**:
   ```
   https://testnet.bscscan.com/tx/<TRANSACTION_HASH>
   ```

2. **Procure pelos eventos**:
   - ✅ **Evento `BurnFeeApplied`**: Confirma que a queima ocorreu
     - `totalAmount`: 100000000 (100 tokens)
     - `burnAmount`: 10000 (0.01 token = 0.01%)
     - `transferAmount`: 99990000 (99.99 tokens)
   - ✅ **Transfer para `0x0000...0000`**: Tokens queimados (10000)
   - ✅ **Transfer para destinatário**: Tokens recebidos (99990000)

3. **Verificar supply total** (deve ter diminuído):
   ```bash
   cast call <TOKEN_ADDRESS> \
     "totalSupply()" \
     --rpc-url https://bsc-testnet.publicnode.com
   ```
   - Deve ter diminuído em 10000 (0.01 token queimado)

4. **Verificar saldo do destinatário**:
   ```bash
   cast call <TOKEN_ADDRESS> \
     "balanceOf(address)" \
     0x867f9CE9F0D7218b016351CB6122406E6D247a5e \
     --rpc-url https://bsc-testnet.publicnode.com
   ```
   - Deve mostrar 99990000 (99.99 tokens recebidos)

#### 6.2.3. Exemplo Completo de Teste

```bash
# Variáveis
TOKEN_ADDRESS="0xC61134c6794043db11120018BbFDD2F4280F2268"
RECIPIENT="0x867f9CE9F0D7218b016351CB6122406E6D247a5e"
AMOUNT="100000000"  # 100 tokens com 6 decimais
PRIVATE_KEY="0x819b680e3578eac4f79b8fde643046e88f3f9bb10a3ce1424e3642798ef39b42"
RPC_URL="https://bsc-testnet.publicnode.com"

# 1. Verificar supply antes
echo "Supply antes:"
cast call ${TOKEN_ADDRESS} "totalSupply()" --rpc-url ${RPC_URL}

# 2. Fazer transferência
echo "Fazendo transferência de 100 tokens..."
cast send ${TOKEN_ADDRESS} \
  "transfer(address,uint256)" \
  ${RECIPIENT} \
  ${AMOUNT} \
  --rpc-url ${RPC_URL} \
  --private-key ${PRIVATE_KEY} \
  --legacy

# 3. Verificar supply depois (deve ter diminuído em 10000)
echo "Supply depois:"
cast call ${TOKEN_ADDRESS} "totalSupply()" --rpc-url ${RPC_URL}

# 4. Verificar saldo do destinatário (deve ter recebido 99990000)
echo "Saldo do destinatário:"
cast call ${TOKEN_ADDRESS} \
  "balanceOf(address)" \
  ${RECIPIENT} \
  --rpc-url ${RPC_URL}
```

### 6.3. Código do Contrato

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

### 7.1. Adicionar Remote Routers

Para linkar o warp route com outras chains (ex: Terra Classic, Solana, Ethereum):

```bash
# Adicionar configuração para outras chains no mesmo arquivo YAML
cat >> environments/testnet/warp-routes/lunc-bsc/warp-route-deployment.yaml << EOF

# Exemplo: Linkar com Terra Classic
# terraclassic:
#   isNft: false
#   type: synthetic
#   name: "Luna Classic"
#   symbol: "wwwwLUNC"
#   decimals: 6
#   totalSupply: 0
#   owner: "0xYourTerraAddress"
#   interchainSecurityModule:
#     type: messageIdMultisigIsm
#     validators:
#       - "242d8a855a8c932dec51f7999ae7d1e48b10c95e"
#       - "f620f5e3d25a3ae848fec74bccae5de3edcd8796"
#       - "1f030345963c54ff8229720dd3a711c15c554aeb"
#     threshold: 2
EOF
```

### 7.2. Deploy Multi-Chain

```bash
# Deploy em múltiplas chains de uma vez
hyperlane warp deploy \
  --config environments/testnet/warp-routes/lunc-bsc/warp-route-deployment.yaml \
  --registry ~/.hyperlane/registry \
  --private-key ${BSC_PRIVATE_KEY} \
  --yes
```

---

## Passo 8: Verificar Configuração Completa

### 8.1. Verificar Token Sintético

```bash
# Ler configuração do warp route
hyperlane warp read \
  --config ${CONFIG_FILE} \
  --chain bsctestnet
```

### 8.2. Testar Funcionalidade de Queima

**⚠️ IMPORTANTE**: A queima só funciona se você fez deploy manual (Passo 3.2). Se usou o Hyperlane CLI, não há queima.

#### Transferir Tokens para Testar

```bash
# Substitua <TOKEN_ADDRESS> pelo endereço do seu contrato
TOKEN_ADDRESS="0xC61134c6794043db11120018BbFDD2F4280F2268"  # Exemplo
RECIPIENT="0x867f9CE9F0D7218b016351CB6122406E6D247a5e"
AMOUNT="100000000"  # 100 tokens com 6 decimais

# Fazer transferência
cast send ${TOKEN_ADDRESS} \
  "transfer(address,uint256)" \
  ${RECIPIENT} \
  ${AMOUNT} \
  --rpc-url https://bsc-testnet.publicnode.com \
  --private-key 0x819b680e3578eac4f79b8fde643046e88f3f9bb10a3ce1424e3642798ef39b42 \
  --legacy
```

#### Verificar Queima no BscScan

1. Acesse a transação no BscScan usando o hash retornado
2. Procure pelo evento `BurnFeeApplied`:
   - `totalAmount`: 100000000 (100 tokens enviados)
   - `burnAmount`: 10000 (0.01 token queimado = 0.01%)
   - `transferAmount`: 99990000 (99.99 tokens recebidos)
3. Verifique o supply total (deve ter diminuído em 10000)

#### Verificar Resultados

```bash
# Verificar supply total (deve ter diminuído)
cast call ${TOKEN_ADDRESS} \
  "totalSupply()" \
  --rpc-url https://bsc-testnet.publicnode.com

# Verificar saldo do destinatário (deve ter 99990000)
cast call ${TOKEN_ADDRESS} \
  "balanceOf(address)" \
  ${RECIPIENT} \
  --rpc-url https://bsc-testnet.publicnode.com
```

---

## Resumo dos Comandos

### Script Completo

```bash
#!/bin/bash
# criar-warp-bsc.sh

set -e

# Variáveis
WARP_ROUTE_NAME="lunc-bsc"
CONFIG_DIR="environments/testnet/warp-routes/${WARP_ROUTE_NAME}"
CONFIG_FILE="${CONFIG_DIR}/warp-route-deployment.yaml"
REGISTRY_PATH="~/.hyperlane/registry"
BSC_PRIVATE_KEY="0xYourPrivateKey"  # ⚠️ Substitua pela sua chave privada

echo "=== Passo 1: Criar Configuração do Token ==="
cd ~/smart-hyperlane-monorepo
mkdir -p ${CONFIG_DIR}

cat > ${CONFIG_FILE} << 'EOF'
---
bsctestnet:
  isNft: false
  type: synthetic
  name: "Luna Classic"
  symbol: "wwwwLUNC"
  decimals: 6
  totalSupply: 0
  owner: "0xYOUR_BSC_ADDRESS_HERE"
  interchainSecurityModule:
    type: messageIdMultisigIsm
    validators:
      - "242d8a855a8c932dec51f7999ae7d1e48b10c95e"
      - "f620f5e3d25a3ae848fec74bccae5de3edcd8796"
      - "1f030345963c54ff8229720dd3a711c15c554aeb"
    threshold: 2
EOF

echo "⚠️ IMPORTANTE: Edite o arquivo e substitua 0xYOUR_BSC_ADDRESS_HERE pelo seu endereço real"
echo "✅ Configuração do token criada"

echo ""
echo "=== Passo 2: Deploy do Warp Route Sintético ==="

hyperlane warp deploy \
  --config ${CONFIG_FILE} \
  --registry ${REGISTRY_PATH} \
  --private-key ${BSC_PRIVATE_KEY} \
  --yes \
  --verbosity debug

echo "✅ Warp route sintético deployado"

echo ""
echo "=== Passo 3: Verificar Deploy ==="
echo "Verificando configuração do warp route..."
hyperlane warp read \
  --config ${CONFIG_FILE} \
  --chain bsctestnet

echo ""
echo "✅ Configuração completa!"
echo ""
echo "Próximos passos:"
echo "1. Anotar o endereço do contrato retornado no Passo 2"
echo "2. Verificar o contrato no BscScan Testnet"
echo "3. Testar transferências locais (que acionarão a queima de 0.01%)"
echo "4. Linkar com outras chains se necessário"
```

---

## Troubleshooting

### Erro: "Missing mailbox address"

**Problema**: O Mailbox não foi configurado.

**Solução**: Adicione o endereço do Mailbox ao arquivo de configuração:

```yaml
bsctestnet:
  type: synthetic
  mailbox: "0xF9F6F5646F478d5ab4e20B0F910C92F1CCC9Cc6D"  # BSC Testnet Mailbox
  # ... resto da configuração
```

### Erro: "Insufficient funds"

**Problema**: Você não tem BNB suficiente para gas fees.

**Solução**: 
- Para testnet: Obtenha BNB Testnet de um faucet:
  - https://testnet.bnbchain.org/faucet-smart
  - https://www.bnbchain.org/en/testnet-faucet
- Para mainnet: Certifique-se de ter BNB suficiente

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

## Diferenças entre Solana, Ethereum e BSC

| Aspecto | Solana | Ethereum | BSC |
|---------|--------|----------|-----|
| **Formato de Config** | JSON | YAML | YAML |
| **CLI** | Rust (`cargo run`) | TypeScript (`hyperlane`) | TypeScript (`hyperlane`) |
| **Contrato** | Program ID (base58) | Endereço (hex) | Endereço (hex) |
| **Gas Fees** | SOL (lamports) | ETH (wei) | BNB (wei) |
| **Decimals** | 9 (padrão) | 18 (padrão) | 18 (padrão) ou 6 (Terra) |
| **Chain Name** | `solanatestnet` | `ethereum` | `bsctestnet` |
| **Domain ID** | 1399811150 | 1 | 97 |
| **Queima** | Não implementada | 0.01% automático | 0.01% automático |
| **Explorer** | Solscan | Etherscan | BscScan |

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
   - Verificar eventos no BscScan

---

## Referências

- [Hyperlane Warp Routes Documentation](https://docs.hyperlane.xyz/docs/guides/warp-routes/overview)
- [WARP-ROUTES-TESTNET.md](https://github.com/igorv43/cw-hyperlane/blob/main/WARP-ROUTES-TESTNET.md) - Guia oficial de Warp Routes (referência principal)
- [HypERC20 Contract](../solidity/contracts/token/HypERC20.sol) - Contrato com funcionalidade de queima
- [CRIAR-WARP-SOLANA-COMPLETO.md](./CRIAR-WARP-SOLANA-COMPLETO.md) - Guia completo para Solana
- [CRIAR-WARP-ETHEREUM-COMPLETO.md](./CRIAR-WARP-ETHEREUM-COMPLETO.md) - Guia completo para Ethereum
- [BSC Testnet Explorer](https://testnet.bscscan.com/)
- [BSC Testnet Faucet](https://testnet.bnbchain.org/faucet-smart)
