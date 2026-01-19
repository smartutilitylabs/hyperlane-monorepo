# Referência dos Scripts - Optimism Mainnet

Este documento contém a referência completa de todos os scripts disponíveis para deploy e gerenciamento de tokens na Optimism Mainnet.

📄 **Guia Principal**: [GUIA-COMPLETO-OPTIMISM.md](./GUIA-COMPLETO-OPTIMISM.md)

---

## 📁 Estrutura dos Scripts

Os scripts estão organizados em duas pastas principais:

- **`scripts/`**: Scripts bash para automação completa
- **`solidity/script/`**: Scripts Solidity (Foundry) para deploy e operações

---

## 🚀 Scripts de Deploy

### 1. `scripts/deploy-hyp-erc20-optimism-completo.sh`

**Descrição**: Script completo para fazer deploy do HypERC20 Sintético na Optimism Mainnet.

**Funcionalidades**:
- ✅ Verifica dependências (Foundry)
- ✅ Verifica saldo da wallet
- ✅ Compila contratos
- ✅ Faz deploy completo (ProxyAdmin + Implementation + Proxy)
- ✅ Cria automaticamente arquivo de configuração warp
- ✅ Extrai endereços automaticamente

**Uso**:
```bash
bash scripts/deploy-hyp-erc20-optimism-completo.sh
```

**Configurações**:
- **Token**: upusd
- **Decimals**: 6
- **Supply Inicial**: 15,000,000,000 (15 bilhões)
- **Rede**: Optimism Mainnet (Chain ID: 10)
- **Funcionalidade**: Queima automática de 0.01%

**Arquivos Gerados**:
- `environments/mainnet/warp-routes/upusd-optimism/warp-route-deployment.yaml`

**Script Solidity Correspondente**:
- `solidity/script/DeployHypERC20Optimism.s.sol`

---

### 2. `scripts/deploy-hypnative-optimism-completo.sh`

**Descrição**: Script completo para fazer deploy do HypNative (Token Nativo) na Optimism Mainnet.

**Funcionalidades**:
- ✅ Deploy do HypNative (wrapper para ETH nativo)
- ✅ Cria arquivo de configuração warp
- ✅ Configuração para token nativo

**Uso**:
```bash
bash scripts/deploy-hypnative-optimism-completo.sh
```

**Nota**: HypNative não cria um token ERC20, apenas permite wrap de ETH nativo.

**Script Solidity Correspondente**:
- `solidity/script/DeployHypNativeOptimism.s.sol`

---

## 🔧 Scripts de Gerenciamento

### 3. `scripts/mint-additional-supply-optimism.sh`

**Descrição**: Script para aumentar o supply do token fazendo upgrade e mint.

**Funcionalidades**:
- ✅ Deploy da nova implementation com função `mint`
- ✅ Upgrade do proxy para nova implementation
- ✅ Mint de tokens adicionais
- ✅ Verificação do novo supply

**Uso**:
```bash
bash scripts/mint-additional-supply-optimism.sh
```

**Configurações**:
- **Supply Adicional**: 135,000,000,000 (135 bilhões)
- **Supply Final**: 150,000,000,000 (150 bilhões)

**Requisitos**:
- Deve ser owner do ProxyAdmin (para upgrade)
- Deve ser owner do token (para mint)

**Script Solidity Correspondente**:
- `solidity/script/MintAdditionalSupplyOptimism.s.sol`

---

### 4. `scripts/mint-tokens-optimism.sh`

**Descrição**: Script simplificado apenas para fazer mint de tokens (após upgrade).

**Funcionalidades**:
- ✅ Mint de tokens adicionais
- ✅ Verificação de permissões
- ✅ Verificação do supply final

**Uso**:
```bash
bash scripts/mint-tokens-optimism.sh
```

**Requisitos**:
- Contrato já deve ter função `mint` (após upgrade)
- Deve ser owner do token

---

## 📜 Scripts Solidity (Foundry)

### 5. `solidity/script/DeployHypERC20Optimism.s.sol`

**Descrição**: Script Solidity para deploy do HypERC20 Sintético.

**Parâmetros Configurados**:
```solidity
uint8 decimals = 6;
uint256 scale = 1;
address mailbox = 0xd4C1905BB1D26BC93DAC913e13CaCC278CdCC80D;
address owner = 0x6d7fFa706F4898f87083255a44eEC503ED02Ab78;
address ism = 0x38164E63A4F67b32b2EfF4b45aCC1f2EE9b77b07;
uint256 initialSupply = 15000000000;
string memory name = "upusd";
string memory symbol = "upusd";
```

**Uso Direto**:
```bash
cd ~/smart-hyperlane-monorepo/solidity
export PRIVATE_KEY="0x..."
export RPC_URL="https://mainnet.optimism.io"

forge script script/DeployHypERC20Optimism.s.sol:DeployHypERC20Optimism \
  --rpc-url $RPC_URL \
  --broadcast \
  --verify \
  --etherscan-api-key <API_KEY> \
  --legacy \
  -vvvv
```

---

### 6. `solidity/script/MintAdditionalSupplyOptimism.s.sol`

**Descrição**: Script Solidity para upgrade do contrato e mint de tokens adicionais.

**Parâmetros Configurados**:
```solidity
address tokenProxyAddress = 0x7d637C37828c01ad6241624FfAAd7B48eb3cc516;
address proxyAdminAddress = 0x3f7EFCC5069BaC444558CbF8280F2419C84dd847;
address owner = 0x6d7fFa706F4898f87083255a44eEC503ED02Ab78;
uint256 additionalSupply = 135000000000;
```

**Uso Direto**:
```bash
cd ~/smart-hyperlane-monorepo/solidity
export PRIVATE_KEY="0x..."
export RPC_URL="https://mainnet.optimism.io"

forge script script/MintAdditionalSupplyOptimism.s.sol:MintAdditionalSupplyOptimism \
  --rpc-url $RPC_URL \
  --broadcast \
  --verify \
  --etherscan-api-key <API_KEY> \
  --legacy \
  -vvvv
```

**O que faz**:
1. Deploy da nova implementation `HypERC20Mintable`
2. Upgrade do proxy para nova implementation
3. Mint de tokens adicionais para o owner

---

### 7. `solidity/script/DeployHypNativeOptimism.s.sol`

**Descrição**: Script Solidity para deploy do HypNative (token nativo).

**Nota**: Este contrato não cria um token ERC20, apenas permite wrap de ETH nativo.

---

## 🔍 Comandos Cast Úteis

### Consultar Saldo

```bash
cast call <TOKEN_ADDRESS> \
  "balanceOf(address)(uint256)" \
  <WALLET_ADDRESS> \
  --rpc-url https://mainnet.optimism.io
```

### Consultar Owner

```bash
cast call <TOKEN_ADDRESS> \
  "owner()(address)" \
  --rpc-url https://mainnet.optimism.io
```

### Consultar Total Supply

```bash
cast call <TOKEN_ADDRESS> \
  "totalSupply()(uint256)" \
  --rpc-url https://mainnet.optimism.io
```

### Consultar Nome do Token

```bash
cast call <TOKEN_ADDRESS> \
  "name()(string)" \
  --rpc-url https://mainnet.optimism.io
```

### Consultar Símbolo

```bash
cast call <TOKEN_ADDRESS> \
  "symbol()(string)" \
  --rpc-url https://mainnet.optimism.io
```

### Consultar Decimals

```bash
cast call <TOKEN_ADDRESS> \
  "decimals()(uint8)" \
  --rpc-url https://mainnet.optimism.io
```

### Transferir Tokens

```bash
cast send <TOKEN_ADDRESS> \
  "transfer(address,uint256)" \
  <DESTINO> \
  <QUANTIDADE> \
  --rpc-url https://mainnet.optimism.io \
  --private-key <PRIVATE_KEY> \
  --legacy
```

### Mint Tokens (após upgrade)

```bash
cast send <TOKEN_ADDRESS> \
  "mint(address,uint256)" \
  <DESTINO> \
  <QUANTIDADE> \
  --rpc-url https://mainnet.optimism.io \
  --private-key <PRIVATE_KEY> \
  --legacy
```

---

## 📋 Contratos Criados

### HypERC20Mintable

**Localização**: `solidity/contracts/token/extensions/HypERC20Mintable.sol`

**Descrição**: Extensão do HypERC20 que adiciona função pública `mint`.

**Função Principal**:
```solidity
function mint(address _to, uint256 _amount) external onlyOwner {
    _mint(_to, _amount);
}
```

**Uso**: Este contrato é usado como upgrade do HypERC20 para permitir mint de tokens adicionais.

---

## 🔐 Segurança e Permissões

### Hierarquia de Permissões

1. **Owner do ProxyAdmin**:
   - Pode fazer upgrade do contrato
   - Pode mudar o admin do proxy

2. **Owner do Token**:
   - Pode fazer mint (após upgrade)
   - Pode configurar ISM, hooks, etc.
   - Pode transferir ownership

3. **Usuários**:
   - Podem transferir seus próprios tokens
   - Podem aprovar gastos (approve)

### Verificar Permissões

```bash
# Verificar owner do ProxyAdmin
cast call <PROXY_ADMIN_ADDRESS> \
  "owner()(address)" \
  --rpc-url https://mainnet.optimism.io

# Verificar owner do token
cast call <TOKEN_ADDRESS> \
  "owner()(address)" \
  --rpc-url https://mainnet.optimism.io
```

---

## 📊 Exemplos Práticos

### Exemplo 1: Deploy Completo

```bash
# 1. Deploy do token
bash scripts/deploy-hyp-erc20-optimism-completo.sh

# 2. Anotar endereços retornados
# Token: 0x...
# ProxyAdmin: 0x...

# 3. Verificar deploy
cast call 0x... "totalSupply()(uint256)" --rpc-url https://mainnet.optimism.io
```

### Exemplo 2: Aumentar Supply

```bash
# 1. Editar script para ajustar quantidade
# Editar: solidity/script/MintAdditionalSupplyOptimism.s.sol
# Alterar: additionalSupply = 135000000000;

# 2. Executar upgrade e mint
bash scripts/mint-additional-supply-optimism.sh

# 3. Verificar novo supply
cast call 0x... "totalSupply()(uint256)" --rpc-url https://mainnet.optimism.io
```

### Exemplo 3: Transferir Tokens

```bash
# 1. Verificar saldo atual
cast call 0x7d637C37828c01ad6241624FfAAd7B48eb3cc516 \
  "balanceOf(address)(uint256)" \
  0x6d7fFa706F4898f87083255a44eEC503ED02Ab78 \
  --rpc-url https://mainnet.optimism.io

# 2. Transferir
cast send 0x7d637C37828c01ad6241624FfAAd7B48eb3cc516 \
  "transfer(address,uint256)" \
  0x52DEC0991bF0B44E1d292443E27981f217Ee400F \
  150000000000 \
  --rpc-url https://mainnet.optimism.io \
  --private-key 0x... \
  --legacy

# 3. Verificar saldo do destinatário
cast call 0x7d637C37828c01ad6241624FfAAd7B48eb3cc516 \
  "balanceOf(address)(uint256)" \
  0x52DEC0991bF0B44E1d292443E27981f217Ee400F \
  --rpc-url https://mainnet.optimism.io
```

---

## 🗂️ Arquivos de Configuração

### Warp Route Deployment

**Localização**: `environments/mainnet/warp-routes/upusd-optimism/warp-route-deployment.yaml`

**Estrutura**:
```yaml
optimism:
  type: synthetic
  name: "upusd"
  symbol: "upusd"
  decimals: 6
  initialSupply: 15000000000
  owner: "0x..."
  mailbox: "0x..."
  interchainSecurityModule:
    type: messageIdMultisigIsm
    validators: [...]
    threshold: 4
  foreignDeployment: "0x..."
```

**Uso**: Este arquivo é usado pelo Hyperlane CLI para conectar o token com outras chains.

---

## 🔗 Links Relacionados

- **Guia Principal**: [GUIA-COMPLETO-OPTIMISM.md](./GUIA-COMPLETO-OPTIMISM.md)
- **Documentação Hyperlane**: https://docs.hyperlane.xyz/
- **Documentação Optimism**: https://docs.optimism.io/
- **Optimism Explorer**: https://optimistic.etherscan.io

---

## 📝 Notas Importantes

1. **Taxa de Queima**: Todos os contratos HypERC20 têm taxa de queima de 0.01% em transferências locais
2. **Proxy Pattern**: Os contratos usam padrão proxy para permitir upgrades
3. **Owner vs Deployer**: O owner pode ser diferente do deployer
4. **Gas**: Sempre verifique saldo suficiente antes de executar transações
5. **Chaves Privadas**: Nunca compartilhe ou commite chaves privadas no código

---

**Última atualização**: Janeiro 2025
