#!/bin/bash
# Script para aumentar o supply do token upusd de 15 bilhões para 150 bilhões
# Este script faz upgrade do contrato para adicionar função de mint e então faz o mint

set -e

echo "⚠️  IMPORTANTE: Este script vai:"
echo "   1. Fazer upgrade do contrato para adicionar função de mint"
echo "   2. Mintar 135 bilhões de tokens adicionais"
echo "   3. Total final: 150 bilhões de tokens"
echo ""

# Variáveis
PRIVATE_KEY="0xab38f039a24acdbeef8d2270bb8887a235f3271f15140777ad08dd72511a36f3"
RPC_URL="https://mainnet.optimism.io"
CHAIN_ID=10

# Endereços dos contratos
TOKEN_ADDRESS="0x56f220237c8b26401AA72EDCF9e5B4CC7E96B4a0"
PROXY_ADMIN="0x47f41E8b337e098bA02F819d14c26F5310600fE0"
OWNER="0x6d7fFa706F4898f87083255a44eEC503ED02Ab78"

# Quantidades
CURRENT_SUPPLY=15000000000
ADDITIONAL_SUPPLY=135000000000
FINAL_SUPPLY=150000000000

echo "=== Passo 1: Verificar Foundry ==="
if ! command -v forge &> /dev/null; then
    echo "❌ Foundry não encontrado. Instale com: curl -L https://foundry.paradigm.xyz | bash && foundryup"
    exit 1
fi
echo "✅ Foundry encontrado"

echo ""
echo "=== Passo 2: Verificar Saldo Atual ==="
CURRENT_SUPPLY_ON_CHAIN=$(cast call $TOKEN_ADDRESS "totalSupply()(uint256)" --rpc-url $RPC_URL 2>/dev/null || echo "0")
echo "Supply atual na blockchain: $CURRENT_SUPPLY_ON_CHAIN"

if [ "$CURRENT_SUPPLY_ON_CHAIN" != "$CURRENT_SUPPLY" ]; then
    echo "⚠️  AVISO: Supply atual ($CURRENT_SUPPLY_ON_CHAIN) difere do esperado ($CURRENT_SUPPLY)"
    echo "   Continuando mesmo assim..."
fi

echo ""
echo "=== Passo 3: Verificar Chave e Saldo ==="
DEPLOYER_ADDRESS=$(cast wallet address --private-key $PRIVATE_KEY)
echo "Endereço do deployer: $DEPLOYER_ADDRESS"
BALANCE=$(cast balance $DEPLOYER_ADDRESS --rpc-url $RPC_URL 2>/dev/null || echo "0")
echo "Saldo ETH: $(cast --to-unit $BALANCE ether) ETH"

if [ "$(cast --to-unit $BALANCE wei)" -lt "100000000000000000" ]; then
    echo "⚠️  AVISO: Saldo baixo! Recomendado pelo menos 0.1 ETH para upgrade e mint"
    echo "   Continuando mesmo assim..."
fi

echo ""
echo "=== Passo 4: Compilar Contratos ==="
cd ~/smart-hyperlane-monorepo/solidity
forge build || {
    echo "❌ Erro na compilação. Tentando instalar dependências..."
    forge install
    forge build
}

echo ""
echo "=== Passo 5: Executar Upgrade e Mint ==="
echo "Executando script de upgrade e mint..."
echo ""

export PRIVATE_KEY
export RPC_URL

# Executar script
forge script script/MintAdditionalSupplyOptimism.s.sol:MintAdditionalSupplyOptimism \
  --rpc-url ${RPC_URL} \
  --broadcast \
  --verify \
  --etherscan-api-key GP69JEAP2W7YFJT9ZJTEPGQT6Y6KMW44ZN \
  --legacy \
  -vvvv

echo ""
echo "✅ Processo concluído!"
echo ""
echo "=== Verificação Final ==="
FINAL_SUPPLY_ON_CHAIN=$(cast call $TOKEN_ADDRESS "totalSupply()(uint256)" --rpc-url $RPC_URL 2>/dev/null || echo "0")
OWNER_BALANCE=$(cast call $TOKEN_ADDRESS "balanceOf(address)(uint256)" $OWNER --rpc-url $RPC_URL 2>/dev/null || echo "0")

echo "Supply final na blockchain: $FINAL_SUPPLY_ON_CHAIN"
echo "Balance do owner: $OWNER_BALANCE"
echo ""

if [ "$FINAL_SUPPLY_ON_CHAIN" = "$FINAL_SUPPLY" ]; then
    echo "✅ Supply aumentado com sucesso!"
    echo "   De $CURRENT_SUPPLY para $FINAL_SUPPLY"
else
    echo "⚠️  AVISO: Supply final ($FINAL_SUPPLY_ON_CHAIN) não corresponde ao esperado ($FINAL_SUPPLY)"
fi

echo ""
echo "🔗 Links úteis:"
echo "   - Token no Explorer: https://optimistic.etherscan.io/token/$TOKEN_ADDRESS"
echo ""
