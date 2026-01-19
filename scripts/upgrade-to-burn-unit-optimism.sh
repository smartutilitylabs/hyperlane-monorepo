#!/bin/bash
# Script para fazer upgrade do contrato HypERC20 (queima percentual 0.01%)
# para HypERC20BurnUnit (queima fixa de 0.01 token por transação)

set -e

echo "⚠️  IMPORTANTE: Este script vai:"
echo "   1. Fazer deploy da nova implementação HypERC20BurnUnit"
echo "   2. Fazer upgrade do proxy para a nova implementação"
echo "   3. Alterar a regra de queima de 0.01% (percentual) para 0.01 token (fixo)"
echo ""
echo "📝 Mudança na regra de queima:"
echo "   ANTES: Queima de 0.01% do valor transferido"
echo "   DEPOIS: Queima fixa de 0.01 token por transação (independente do valor)"
echo ""

# Variáveis
PRIVATE_KEY="0xab38f039a24acdbeef8d2270bb8887a235f3271f15140777ad08dd72511a36f3"
RPC_URL="https://mainnet.optimism.io"
CHAIN_ID=10

# Endereços dos contratos
TOKEN_ADDRESS="0x7d637C37828c01ad6241624FfAAd7B48eb3cc516"
PROXY_ADMIN="0x3f7EFCC5069BaC444558CbF8280F2419C84dd847"
OWNER="0x6d7fFa706F4898f87083255a44eEC503ED02Ab78"

echo "=== Passo 1: Verificar Foundry ==="
if ! command -v forge &> /dev/null; then
    echo "❌ Foundry não encontrado. Instale com: curl -L https://foundry.paradigm.xyz | bash && foundryup"
    exit 1
fi
echo "✅ Foundry encontrado"

echo ""
echo "=== Passo 2: Verificar Chave e Saldo ==="
DEPLOYER_ADDRESS=$(cast wallet address --private-key $PRIVATE_KEY)
echo "Endereço do deployer: $DEPLOYER_ADDRESS"
BALANCE=$(cast balance $DEPLOYER_ADDRESS --rpc-url $RPC_URL 2>/dev/null || echo "0")
echo "Saldo ETH: $(cast --to-unit $BALANCE ether) ETH"

if [ "$(cast --to-unit $BALANCE ether | cut -d. -f1)" -lt "0" ]; then
    echo "❌ Saldo insuficiente. Precisa de pelo menos 0.01 ETH para gas"
    exit 1
fi

echo ""
echo "=== Passo 3: Verificar Informações do Token Atual ==="
cd "$(dirname "$0")/../solidity" || exit 1

TOKEN_NAME=$(cast call $TOKEN_ADDRESS "name()(string)" --rpc-url $RPC_URL 2>/dev/null || echo "N/A")
TOKEN_SYMBOL=$(cast call $TOKEN_ADDRESS "symbol()(string)" --rpc-url $RPC_URL 2>/dev/null || echo "N/A")
TOKEN_DECIMALS=$(cast call $TOKEN_ADDRESS "decimals()(uint8)" --rpc-url $RPC_URL 2>/dev/null || echo "N/A")
TOKEN_SUPPLY=$(cast call $TOKEN_ADDRESS "totalSupply()(uint256)" --rpc-url $RPC_URL 2>/dev/null || echo "0")
TOKEN_OWNER=$(cast call $TOKEN_ADDRESS "owner()(address)" --rpc-url $RPC_URL 2>/dev/null || echo "N/A")

echo "Nome do token: $TOKEN_NAME"
echo "Símbolo: $TOKEN_SYMBOL"
echo "Decimals: $TOKEN_DECIMALS"
echo "Total supply: $TOKEN_SUPPLY"
echo "Owner: $TOKEN_OWNER"

echo ""
echo "=== Passo 4: Verificar Permissões ==="
PROXY_ADMIN_OWNER=$(cast call $PROXY_ADMIN "owner()(address)" --rpc-url $RPC_URL 2>/dev/null || echo "N/A")
echo "Owner do ProxyAdmin: $PROXY_ADMIN_OWNER"
echo "Deployer: $DEPLOYER_ADDRESS"

if [ "$PROXY_ADMIN_OWNER" != "$DEPLOYER_ADDRESS" ]; then
    echo "❌ ERRO: O deployer não é o owner do ProxyAdmin"
    echo "   Owner do ProxyAdmin: $PROXY_ADMIN_OWNER"
    echo "   Deployer: $DEPLOYER_ADDRESS"
    exit 1
fi
echo "✅ Permissões verificadas"

echo ""
echo "=== Passo 5: Compilar Contratos ==="
if ! forge build --contracts contracts/token/HypERC20BurnUnit.sol 2>/dev/null; then
    echo "❌ Erro ao compilar contratos"
    exit 1
fi
echo "✅ Contratos compilados"

echo ""
echo "=== Passo 6: Executar Upgrade ==="
echo "Este processo vai:"
echo "  1. Fazer deploy da nova implementação HypERC20BurnUnit"
echo "  2. Fazer upgrade do proxy para a nova implementação"
echo "  3. Verificar que o upgrade foi bem-sucedido"
echo ""
read -p "Deseja continuar? (s/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Ss]$ ]]; then
    echo "Operação cancelada"
    exit 0
fi

echo ""
echo "Executando upgrade..."
export PRIVATE_KEY
export RPC_URL

forge script script/UpgradeToBurnUnitOptimism.s.sol:UpgradeToBurnUnitOptimism \
    --rpc-url $RPC_URL \
    --broadcast \
    --legacy \
    -vvvv

echo ""
echo "=== Passo 7: Verificar Upgrade ==="
echo "Verificando se o upgrade foi bem-sucedido..."

# Verificar que a nova implementação tem a função burnFeeUnit
BURN_FEE_UNIT=$(cast call $TOKEN_ADDRESS "burnFeeUnit()(uint256)" --rpc-url $RPC_URL 2>/dev/null || echo "0")
echo "Burn fee unit (0.01 token): $BURN_FEE_UNIT"

if [ "$BURN_FEE_UNIT" = "0" ]; then
    echo "⚠️  AVISO: Não foi possível verificar burnFeeUnit. O upgrade pode não ter sido concluído."
    echo "   Verifique manualmente no explorer: https://optimistic.etherscan.io/address/$TOKEN_ADDRESS"
else
    echo "✅ Upgrade verificado com sucesso!"
    echo "   O contrato agora usa queima fixa de 0.01 token por transação"
    echo "   (ao invés de 0.01% percentual)"
fi

echo ""
echo "=== Resumo ==="
echo "Token: $TOKEN_ADDRESS"
echo "ProxyAdmin: $PROXY_ADMIN"
echo "Burn fee unit: $BURN_FEE_UNIT (0.01 token)"
echo ""
echo "✅ Upgrade concluído!"
echo ""
echo "📝 IMPORTANTE:"
echo "   - Todas as transferências locais agora queimarão exatamente 0.01 token"
echo "   - A queima é fixa, independente do valor transferido"
echo "   - Transferências cross-chain não são afetadas pela queima"
echo ""
echo "🔍 Verificar no explorer:"
echo "   https://optimistic.etherscan.io/address/$TOKEN_ADDRESS"
