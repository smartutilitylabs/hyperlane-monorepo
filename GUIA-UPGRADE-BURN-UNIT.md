# Guia Completo: Upgrade de Queima Percentual para Queima Fixa

Este guia fornece instruções detalhadas para fazer upgrade do contrato HypERC20 (queima percentual de 0.01%) para HypERC20BurnUnit (queima fixa de 0.01 token por transação).

## 📋 Índice

1. [Visão Geral](#visão-geral)
2. [Pré-requisitos](#pré-requisitos)
3. [Entendendo a Mudança](#entendendo-a-mudança)
4. [Como Fazer o Upgrade](#como-fazer-o-upgrade)
5. [Como Verificar o Upgrade](#como-verificar-o-upgrade)
6. [Troubleshooting](#troubleshooting)
7. [Exemplos Práticos](#exemplos-práticos)

---

## Visão Geral

### O que é este upgrade?

Este upgrade altera a lógica de queima de tokens do contrato de uma taxa **percentual** (0.01% do valor transferido) para uma taxa **fixa** (0.01 token por transação).

### Por que fazer este upgrade?

- **Previsibilidade**: A queima é sempre a mesma, independente do valor transferido
- **Transparência**: Usuários sabem exatamente quanto será queimado
- **Eficiência**: Para transferências grandes, a queima fixa é mais econômica

### O que é preservado?

✅ **Todas as informações do token**:
- Nome
- Símbolo
- Decimals
- Total Supply
- Owner
- Mailbox
- Endereço do contrato (proxy)

✅ **Funcionalidades**:
- Transferências locais
- Transferências cross-chain
- Todas as funções ERC20

---

## Pré-requisitos

### 1. Ferramentas Necessárias

- **Foundry** instalado (`forge`, `cast`)
- **Chave privada** com saldo suficiente de ETH na Optimism
- **Acesso à Optimism Mainnet**

### 2. Verificar Instalação do Foundry

```bash
forge --version
cast --version
```

Se não estiver instalado:

```bash
curl -L https://foundry.paradigm.xyz | bash
foundryup
```

### 3. Informações do Contrato

Antes de fazer o upgrade, você precisa ter:

- **Endereço do Token (Proxy)**: `0x7d637C37828c01ad6241624FfAAd7B48eb3cc516`
- **Endereço do ProxyAdmin**: `0x3f7EFCC5069BaC444558CbF8280F2419C84dd847`
- **Owner do ProxyAdmin**: Deve ser o mesmo endereço que vai executar o upgrade

### 4. Verificar Permissões

```bash
# Verificar owner do ProxyAdmin
cast call 0x3f7EFCC5069BaC444558CbF8280F2419C84dd847 \
  "owner()(address)" \
  --rpc-url https://mainnet.optimism.io

# Verificar seu endereço
cast wallet address --private-key <SUA_PRIVATE_KEY>
```

**⚠️ IMPORTANTE**: Apenas o owner do ProxyAdmin pode fazer o upgrade!

---

## Entendendo a Mudança

### Antes do Upgrade (HypERC20)

**Regra de Queima**: 0.01% do valor transferido

**Exemplos**:
- Transferir 150 bilhões → queima **15 milhões** (0.01%)
- Transferir 1 milhão → queima **100 tokens** (0.01%)
- Transferir 10.000 → queima **1 token** (0.01%)

**Cálculo**: `burnAmount = amount / 10000`

### Depois do Upgrade (HypERC20BurnUnit)

**Regra de Queima**: 0.01 token fixo por transação

**Exemplos**:
- Transferir 150 bilhões → queima **0.01 token** (fixo)
- Transferir 1 milhão → queima **0.01 token** (fixo)
- Transferir 10.000 → queima **0.01 token** (fixo)
- Transferir 0.01 token ou menos → **sem queima** (proteção)

**Cálculo**: `burnAmount = 0.01 token` (fixo, independente do valor)

**Para 6 decimals**: `0.01 token = 10000` (em wei)

---

## Como Fazer o Upgrade

### Opção 1: Usar Script Bash (Recomendado)

#### Passo 1: Navegar para o diretório do projeto

```bash
cd ~/smart-hyperlane-monorepo
```

#### Passo 2: Executar o script

```bash
bash scripts/upgrade-to-burn-unit-optimism.sh
```

O script irá:
1. ✅ Verificar dependências (Foundry)
2. ✅ Verificar saldo da wallet
3. ✅ Verificar informações do token atual
4. ✅ Verificar permissões
5. ✅ Compilar contratos
6. ✅ Executar o upgrade
7. ✅ Verificar o resultado

#### Passo 3: Confirmar execução

O script pedirá confirmação antes de executar. Digite `s` para continuar.

### Opção 2: Executar Manualmente com Foundry

#### Passo 1: Configurar variáveis de ambiente

```bash
cd ~/smart-hyperlane-monorepo/solidity

export PRIVATE_KEY="0xab38f039a24acdbeef8d2270bb8887a235f3271f15140777ad08dd72511a36f3"
export RPC_URL="https://mainnet.optimism.io"
```

#### Passo 2: Compilar contratos

```bash
forge build --contracts contracts/token/HypERC20BurnUnit.sol
```

#### Passo 3: Executar o script de upgrade

```bash
forge script script/UpgradeToBurnUnitOptimism.s.sol:UpgradeToBurnUnitOptimism \
  --rpc-url $RPC_URL \
  --broadcast \
  --legacy \
  -vvvv
```

### O que acontece durante o upgrade?

1. **Deploy da Nova Implementação**: 
   - Nova implementação `HypERC20BurnUnit` é deployada
   - Endereço será exibido nos logs

2. **Upgrade do Proxy**:
   - O ProxyAdmin atualiza o proxy para apontar para a nova implementação
   - O endereço do token permanece o mesmo

3. **Verificação Automática**:
   - O script verifica que todas as informações foram preservadas
   - Verifica que a nova função `burnFeeUnit()` está disponível

---

## Como Verificar o Upgrade

### Opção 1: Script Automático de Verificação (Recomendado)

Execute o script de verificação que faz todas as checagens automaticamente:

```bash
cd ~/smart-hyperlane-monorepo
bash scripts/verify-upgrade-burn-unit.sh
```

O script verifica:
- ✅ Função `burnFeeUnit()` disponível
- ✅ Nome do token preservado
- ✅ Símbolo do token preservado
- ✅ Total supply preservado
- ✅ Decimals preservado
- ✅ Owner preservado
- ✅ Mailbox preservado

### Opção 2: Verificação Manual

### 1. Verificar Função burnFeeUnit()

A função `burnFeeUnit()` só existe na nova implementação. Se retornar um valor, o upgrade foi bem-sucedido.

```bash
cast call 0x7d637C37828c01ad6241624FfAAd7B48eb3cc516 \
  "burnFeeUnit()(uint256)" \
  --rpc-url https://mainnet.optimism.io
```

**Resultado esperado**: `10000` (0.01 token para 6 decimals)

**Se retornar erro**: O upgrade não foi concluído ou falhou.

### 2. Verificar Informações Preservadas

#### Nome do Token

```bash
cast call 0x7d637C37828c01ad6241624FfAAd7B48eb3cc516 \
  "name()(string)" \
  --rpc-url https://mainnet.optimism.io
```

**Resultado esperado**: `"upusd"`

#### Símbolo do Token

```bash
cast call 0x7d637C37828c01ad6241624FfAAd7B48eb3cc516 \
  "symbol()(string)" \
  --rpc-url https://mainnet.optimism.io
```

**Resultado esperado**: `"upusd"`

#### Total Supply

```bash
cast call 0x7d637C37828c01ad6241624FfAAd7B48eb3cc516 \
  "totalSupply()(uint256)" \
  --rpc-url https://mainnet.optimism.io
```

**Resultado esperado**: Deve ser o mesmo valor de antes do upgrade

#### Decimals

```bash
cast call 0x7d637C37828c01ad6241624FfAAd7B48eb3cc516 \
  "decimals()(uint8)" \
  --rpc-url https://mainnet.optimism.io
```

**Resultado esperado**: `6`

#### Owner

```bash
cast call 0x7d637C37828c01ad6241624FfAAd7B48eb3cc516 \
  "owner()(address)" \
  --rpc-url https://mainnet.optimism.io
```

**Resultado esperado**: Deve ser o mesmo owner de antes do upgrade

#### Mailbox

```bash
cast call 0x7d637C37828c01ad6241624FfAAd7B48eb3cc516 \
  "mailbox()(address)" \
  --rpc-url https://mainnet.optimism.io
```

**Resultado esperado**: `0xd4C1905BB1D26BC93DAC913e13CaCC278CdCC80D`

### 3. Verificar Implementação Ativa

#### Verificar Slot de Storage do Proxy

O slot `0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc` contém o endereço da implementação ativa.

```bash
cast storage 0x7d637C37828c01ad6241624FfAAd7B48eb3cc516 \
  0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc \
  --rpc-url https://mainnet.optimism.io
```

**Resultado esperado**: Endereço da nova implementação (será exibido nos logs do upgrade)

### 4. Script de Verificação Completa

Crie um script para verificar tudo de uma vez:

```bash
#!/bin/bash
TOKEN="0x7d637C37828c01ad6241624FfAAd7B48eb3cc516"
RPC="https://mainnet.optimism.io"

echo "=== Verificação do Upgrade ==="
echo ""

echo "1. Função burnFeeUnit():"
cast call $TOKEN "burnFeeUnit()(uint256)" --rpc-url $RPC
echo ""

echo "2. Nome:"
cast call $TOKEN "name()(string)" --rpc-url $RPC
echo ""

echo "3. Símbolo:"
cast call $TOKEN "symbol()(string)" --rpc-url $RPC
echo ""

echo "4. Total Supply:"
cast call $TOKEN "totalSupply()(uint256)" --rpc-url $RPC
echo ""

echo "5. Decimals:"
cast call $TOKEN "decimals()(uint8)" --rpc-url $RPC
echo ""

echo "6. Owner:"
cast call $TOKEN "owner()(address)" --rpc-url $RPC
echo ""

echo "7. Mailbox:"
cast call $TOKEN "mailbox()(address)" --rpc-url $RPC
echo ""

echo "=== Verificação Concluída ==="
```

---

## Troubleshooting

### Erro: "Apenas o owner do ProxyAdmin pode fazer upgrade"

**Causa**: Você não é o owner do ProxyAdmin.

**Solução**:
1. Verifique o owner do ProxyAdmin:
   ```bash
   cast call <PROXY_ADMIN> "owner()(address)" --rpc-url https://mainnet.optimism.io
   ```
2. Use a chave privada do owner correto
3. Ou peça ao owner para executar o upgrade

### Erro: "Saldo insuficiente"

**Causa**: Não há ETH suficiente para pagar o gas.

**Solução**:
1. Verifique seu saldo:
   ```bash
   cast balance <SEU_ENDERECO> --rpc-url https://mainnet.optimism.io
   ```
2. Adicione ETH à sua wallet
3. Recomendado: pelo menos 0.01 ETH

### Erro: "burnFeeUnit() não encontrado" após upgrade

**Causa**: O upgrade pode não ter sido concluído corretamente.

**Solução**:
1. Verifique o slot de storage do proxy:
   ```bash
   cast storage <TOKEN_ADDRESS> 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc --rpc-url https://mainnet.optimism.io
   ```
2. Verifique se o endereço corresponde à nova implementação
3. Se não corresponder, execute o upgrade novamente

### Erro: "Failed to estimate gas"

**Causa**: Pode ser problema de rede ou configuração.

**Solução**:
1. Verifique a conexão com a RPC
2. Tente novamente após alguns segundos
3. Verifique se o contrato existe no endereço especificado

### Informações do Token Não Correspondem

**Causa**: Algo deu errado durante o upgrade.

**Solução**:
1. Verifique os logs do upgrade
2. Compare os valores antes e depois
3. Se necessário, faça rollback (requer outro upgrade)

---

## Exemplos Práticos

### Exemplo 1: Verificação Rápida

```bash
# Verificar se o upgrade foi bem-sucedido
cast call 0x7d637C37828c01ad6241624FfAAd7B48eb3cc516 \
  "burnFeeUnit()(uint256)" \
  --rpc-url https://mainnet.optimism.io

# Se retornar 10000, o upgrade foi bem-sucedido!
```

### Exemplo 2: Teste de Transferência

Após o upgrade, teste uma transferência para verificar a nova regra de queima:

```bash
# Transferir 1 milhão de tokens
cast send 0x7d637C37828c01ad6241624FfAAd7B48eb3cc516 \
  "transfer(address,uint256)" \
  <DESTINO> \
  1000000 \
  --rpc-url https://mainnet.optimism.io \
  --private-key <PRIVATE_KEY> \
  --legacy

# Verificar saldo do destinatário
cast call 0x7d637C37828c01ad6241624FfAAd7B48eb3cc516 \
  "balanceOf(address)(uint256)" \
  <DESTINO> \
  --rpc-url https://mainnet.optimism.io

# Resultado esperado: 999900 (1 milhão - 0.01 token de queima)
```

### Exemplo 3: Comparação Antes e Depois

#### Antes do Upgrade (Queima Percentual)

```bash
# Transferir 150 bilhões
# Queima: 15 milhões (0.01% de 150 bilhões)
# Recebido: 149.985 bilhões
```

#### Depois do Upgrade (Queima Fixa)

```bash
# Transferir 150 bilhões
# Queima: 0.01 token (fixo)
# Recebido: 149.99999999 bilhões (praticamente tudo)
```

---

## Checklist de Verificação

Use este checklist para garantir que tudo está correto:

- [ ] Foundry instalado e funcionando
- [ ] Saldo suficiente de ETH na wallet
- [ ] Sou o owner do ProxyAdmin
- [ ] Contratos compilados com sucesso
- [ ] Upgrade executado sem erros
- [ ] Função `burnFeeUnit()` retorna `10000`
- [ ] Nome do token preservado
- [ ] Símbolo do token preservado
- [ ] Total supply preservado
- [ ] Decimals preservado
- [ ] Owner preservado
- [ ] Mailbox preservado
- [ ] Teste de transferência funcionando

---

## Informações Importantes

### Endereços

- **Token (Proxy)**: `0x7d637C37828c01ad6241624FfAAd7B48eb3cc516`
- **ProxyAdmin**: `0x3f7EFCC5069BaC444558CbF8280F2419C84dd847`
- **Nova Implementação**: Será exibida nos logs do upgrade

### Exploradores

- **Optimism Explorer**: https://optimistic.etherscan.io/address/0x7d637C37828c01ad6241624FfAAd7B48eb3cc516
- **OP Mainnet Explorer**: https://optimism.blockscout.com/address/0x7d637C37828c01ad6241624FfAAd7B48eb3cc516

### Arquivos Relacionados

- **Script Solidity de Upgrade**: `solidity/script/UpgradeToBurnUnitOptimism.s.sol`
- **Script Bash de Upgrade**: `scripts/upgrade-to-burn-unit-optimism.sh`
- **Script de Verificação**: `scripts/verify-upgrade-burn-unit.sh`
- **Contrato**: `solidity/contracts/token/HypERC20BurnUnit.sol`

---

## Suporte

Para mais informações:

- **Documentação Hyperlane**: https://docs.hyperlane.xyz/
- **Documentação Optimism**: https://docs.optimism.io/
- **Foundry Book**: https://book.getfoundry.sh/

---

**Última atualização**: Janeiro 2025
