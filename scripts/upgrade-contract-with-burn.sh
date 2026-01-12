#!/bin/bash
# Script para fazer upgrade do contrato HypERC20 existente para versão com queima
# 
# ⚠️ IMPORTANTE: Este script requer que você seja o owner do ProxyAdmin

set -e

# Variáveis
PROXY_ADDRESS="0x4D1F75656A001b9e5b0aaAd6C0DA389D1c437cEb"  # Contrato atual
PRIVATE_KEY="0x819b680e3578eac4f79b8fde643046e88f3f9bb10a3ce1424e3642798ef39b42"
RPC_URL="https://bsc-testnet.publicnode.com"

echo "⚠️  ATENÇÃO: Para fazer upgrade, você precisa:"
echo "   1. Ser o owner do ProxyAdmin"
echo "   2. Ter a nova implementação compilada"
echo ""
echo "O contrato atual é um proxy. Para adicionar a funcionalidade de queima,"
echo "você precisa fazer upgrade da implementação."
echo ""
echo "Opções:"
echo "1. Fazer upgrade do contrato existente (requer ser owner do ProxyAdmin)"
echo "2. Fazer novo deploy completo usando Foundry"
echo ""
echo "Como o Hyperlane CLI sempre usa a versão oficial, a melhor solução é:"
echo "- Fazer deploy manual usando Foundry do contrato HypERC20.sol local"
echo "- Ou modificar o processo de build do Hyperlane CLI para usar os contratos locais"
echo ""
echo "Para fazer deploy manual completo, execute:"
echo "  cd ~/smart-hyperlane-monorepo/solidity"
echo "  forge install"  # Instalar dependências
echo "  forge build"
echo "  forge script script/DeployHypERC20WithBurn.s.sol:DeployHypERC20WithBurn \\"
echo "    --rpc-url ${RPC_URL} \\"
echo "    --broadcast \\"
echo "    --legacy \\"
echo "    -vvvv"
