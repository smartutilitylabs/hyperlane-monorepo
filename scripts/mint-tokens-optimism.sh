#!/bin/bash
# Script para fazer mint de tokens adicionais após o upgrade
# Este script deve ser executado pelo OWNER do token

set -e

echo "⚠️  IMPORTANTE: Este script faz mint de tokens adicionais"
echo "   Deve ser executado pelo OWNER do token"
echo ""

# Variáveis
PRIVATE_KEY="0xab38f039a24acdbeef8d2270bb8887a235f3271f15140777ad08dd72511a36f3"  # ⚠️ Use a chave do OWNER
RPC_URL="https://mainnet.optimism.io"

# Endereços
TOKEN_ADDRESS="0x56f220237c8b26401AA72EDCF9e5B4CC7E96B4a0"
OWNER="0x6d7fFa706F4898f87083255a44eEC503ED02Ab78"

# Quantidade adicional a mintar: 135,000,000,000 (135 bilhões)
ADDITIONAL_SUPPLY=150000000000

echo "=== Verificações ==="
DEPLOYER_ADDRESS=$(cast wallet address --private-key $PRIVATE_KEY)
echo "Endereço do caller: $DEPLOYER_ADDRESS"
echo "Owner esperado: $OWNER"

if [ "$DEPLOYER_ADDRESS" != "$OWNER" ]; then
    echo "❌ ERRO: O caller não é o owner do token!"
    echo "   Use a chave privada do owner: $OWNER"
    exit 1
fi

echo "✅ Caller é o owner do token"
echo ""

echo "=== Verificar Supply Atual ==="
CURRENT_SUPPLY=$(cast call $TOKEN_ADDRESS "totalSupply()(uint256)" --rpc-url $RPC_URL)
echo "Supply atual: $CURRENT_SUPPLY"
echo "Quantidade a mintar: $ADDITIONAL_SUPPLY"
echo "Supply final esperado: $((CURRENT_SUPPLY + ADDITIONAL_SUPPLY))"
echo ""

echo "=== Executar Mint ==="
cast send $TOKEN_ADDRESS \
  "mint(address,uint256)" \
  $OWNER \
  $ADDITIONAL_SUPPLY \
  --rpc-url $RPC_URL \
  --private-key $PRIVATE_KEY \
  --legacy

echo ""
echo "✅ Mint executado com sucesso!"
echo ""

echo "=== Verificação Final ==="
FINAL_SUPPLY=$(cast call $TOKEN_ADDRESS "totalSupply()(uint256)" --rpc-url $RPC_URL)
OWNER_BALANCE=$(cast call $TOKEN_ADDRESS "balanceOf(address)(uint256)" $OWNER --rpc-url $RPC_URL)

echo "Supply final: $FINAL_SUPPLY"
echo "Balance do owner: $OWNER_BALANCE"
echo ""

if [ "$FINAL_SUPPLY" = "$((CURRENT_SUPPLY + ADDITIONAL_SUPPLY))" ]; then
    echo "✅ Supply aumentado com sucesso!"
    echo "   De $CURRENT_SUPPLY para $FINAL_SUPPLY"
else
    echo "⚠️  AVISO: Supply final não corresponde ao esperado"
fi

echo ""
echo "🔗 Token no Explorer: https://optimistic.etherscan.io/token/$TOKEN_ADDRESS"
echo ""
