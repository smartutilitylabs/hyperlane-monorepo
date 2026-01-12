# Solução: Deploy do HypERC20 com Funcionalidade de Queima no BSC

## ⚠️ Problema Identificado

O Hyperlane CLI sempre deploya a versão **oficial** do HypERC20 do pacote npm `@hyperlane-xyz/core`, que **NÃO tem** a funcionalidade de queima. O código local (`solidity/contracts/token/HypERC20.sol`) tem a queima implementada, mas o CLI não usa esse código.

## ✅ Solução: Deploy Manual com Foundry

### Opção 1: Deploy Manual Completo (Recomendado)

1. **Instalar dependências do Soldeer** (gerenciador de dependências do Foundry):
   ```bash
   cd ~/smart-hyperlane-monorepo/solidity
   forge soldeer install
   ```

2. **Compilar contratos**:
   ```bash
   forge build
   ```

3. **Executar script de deploy**:
   ```bash
   export PRIVATE_KEY="0x819b680e3578eac4f79b8fde643046e88f3f9bb10a3ce1424e3642798ef39b42"
   
   forge script script/DeployHypERC20WithBurn.s.sol:DeployHypERC20WithBurn \
     --rpc-url https://bsc-testnet.publicnode.com \
     --broadcast \
     --legacy \
     -vvv
   ```

4. **Anotar o endereço do Proxy** retornado (esse será o endereço do token)

5. **Usar o contrato deployado no Hyperlane**:
   - O contrato já estará deployado e inicializado
   - Você precisará configurar os routers remotos manualmente
   - Ou usar o Hyperlane CLI para configurar apenas os routers

### Opção 2: Usar Script Automatizado

```bash
cd ~/smart-hyperlane-monorepo
./scripts/deploy-hyp-erc20-burn-completo.sh
```

## 📝 Após o Deploy Manual

Após fazer o deploy manual, você terá:
- ✅ Contrato HypERC20 com funcionalidade de queima (0.01%)
- ✅ Supply inicial de 15.000.000.000 tokens
- ✅ Contrato inicializado e pronto para uso

**Próximos passos:**
1. Testar transferência local para verificar queima
2. Configurar routers remotos usando Hyperlane CLI
3. Linkar com outras chains

## 🔍 Verificar Funcionalidade de Queima

### Passo 1: Transferir Tokens para Testar

Após o deploy, teste uma transferência:

```bash
# Substitua <TOKEN_ADDRESS> pelo endereço do seu contrato deployado
# Exemplo: 0xC61134c6794043db11120018BbFDD2F4280F2268

TOKEN_ADDRESS="<TOKEN_ADDRESS>"
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

### Passo 2: Verificar Queima no BscScan

1. **Acesse a transação no BscScan** usando o hash retornado:
   ```
   https://testnet.bscscan.com/tx/<TRANSACTION_HASH>
   ```

2. **Procure pelo evento `BurnFeeApplied`**:
   - `totalAmount`: `100000000` (100 tokens enviados)
   - `burnAmount`: `10000` (0.01 token queimado = 0.01%)
   - `transferAmount`: `99990000` (99.99 tokens recebidos)

3. **Verifique também**:
   - Transfer para `0x0000...0000` (endereço zero) = tokens queimados (10000)
   - Transfer para destinatário = tokens recebidos (99990000)

### Passo 3: Verificar Resultados via CLI

```bash
# Verificar supply total (deve ter diminuído em 10000)
cast call ${TOKEN_ADDRESS} \
  "totalSupply()" \
  --rpc-url https://bsc-testnet.publicnode.com

# Verificar saldo do destinatário (deve ter 99990000 = 99.99 tokens)
cast call ${TOKEN_ADDRESS} \
  "balanceOf(address)" \
  ${RECIPIENT} \
  --rpc-url https://bsc-testnet.publicnode.com

# Verificar saldo do owner (deve ter diminuído em 100000000)
cast call ${TOKEN_ADDRESS} \
  "balanceOf(address)" \
  0x8BD456605473ad4727ACfDCA0040a0dBD4be2DEA \
  --rpc-url https://bsc-testnet.publicnode.com
```

### Exemplo Completo de Teste

```bash
# Variáveis
TOKEN_ADDRESS="0xC61134c6794043db11120018BbFDD2F4280F2268"
RECIPIENT="0x867f9CE9F0D7218b016351CB6122406E6D247a5e"
AMOUNT="100000000"  # 100 tokens com 6 decimais
PRIVATE_KEY="0x819b680e3578eac4f79b8fde643046e88f3f9bb10a3ce1424e3642798ef39b42"
RPC_URL="https://bsc-testnet.publicnode.com"

# 1. Verificar supply antes
echo "=== Supply antes ==="
cast call ${TOKEN_ADDRESS} "totalSupply()" --rpc-url ${RPC_URL}

# 2. Fazer transferência
echo ""
echo "=== Fazendo transferência de 100 tokens ==="
cast send ${TOKEN_ADDRESS} \
  "transfer(address,uint256)" \
  ${RECIPIENT} \
  ${AMOUNT} \
  --rpc-url ${RPC_URL} \
  --private-key ${PRIVATE_KEY} \
  --legacy

# 3. Verificar supply depois (deve ter diminuído em 10000)
echo ""
echo "=== Supply depois (deve ter diminuído em 10000) ==="
cast call ${TOKEN_ADDRESS} "totalSupply()" --rpc-url ${RPC_URL}

# 4. Verificar saldo do destinatário (deve ter recebido 99990000)
echo ""
echo "=== Saldo do destinatário (deve ter 99990000 = 99.99 tokens) ==="
cast call ${TOKEN_ADDRESS} \
  "balanceOf(address)" \
  ${RECIPIENT} \
  --rpc-url ${RPC_URL}
```

## ⚠️ Limitações

- O deploy manual cria um contrato standalone
- Você precisará configurar routers remotos manualmente
- O Hyperlane CLI não gerencia completamente contratos deployados manualmente

## 📚 Arquivos Criados

- `solidity/script/DeployHypERC20WithBurn.s.sol` - Script de deploy
- `scripts/deploy-hyp-erc20-burn-completo.sh` - Script automatizado
- `DEPLOY-MANUAL-HYP-ERC20-BURN.md` - Guia detalhado
