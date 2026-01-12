#!/bin/bash
# Script completo para fazer deploy do HypERC20 com funcionalidade de queima
# Este script faz o deploy manual usando Foundry

set -e

echo "⚠️  IMPORTANTE: Este script faz deploy MANUAL do HypERC20 com queima"
echo "   O Hyperlane CLI sempre usa a versão oficial (sem queima)"
echo ""

# Variáveis
PRIVATE_KEY="0x819b680e3578eac4f79b8fde643046e88f3f9bb10a3ce1424e3642798ef39b42"
RPC_URL="https://bsc-testnet.publicnode.com"
CHAIN_ID=97

# Parâmetros do token
DECIMALS=6
SCALE=1
MAILBOX="0xF9F6F5646F478d5ab4e20B0F910C92F1CCC9Cc6D"
OWNER="0x8BD456605473ad4727ACfDCA0040a0dBD4be2DEA"
HOOK="0x0000000000000000000000000000000000000000"
ISM="0xe4245cCB6427Ba0DC483461bb72318f5DC34d090"
INITIAL_SUPPLY=15000000000
NAME="upusd"
SYMBOL="upusd"

echo "=== Passo 1: Verificar Foundry ==="
if ! command -v forge &> /dev/null; then
    echo "❌ Foundry não encontrado. Instale com: curl -L https://foundry.paradigm.xyz | bash && foundryup"
    exit 1
fi
echo "✅ Foundry encontrado"

echo ""
echo "=== Passo 2: Instalar Dependências ==="
cd ~/smart-hyperlane-monorepo/solidity
forge install --no-commit 2>/dev/null || echo "Dependências já instaladas ou erro (pode continuar)"

echo ""
echo "=== Passo 3: Compilar Contratos ==="
forge build || {
    echo "❌ Erro na compilação. Tentando instalar dependências..."
    forge install
    forge build
}

echo ""
echo "=== Passo 4: Deploy do Contrato ==="
echo "Executando script de deploy..."

export PRIVATE_KEY
export RPC_URL

forge script script/DeployHypERC20WithBurn.s.sol:DeployHypERC20WithBurn \
  --rpc-url ${RPC_URL} \
  --broadcast \
  --legacy \
  -vvv

echo ""
echo "✅ Deploy completo!"
echo ""
echo "⚠️  PRÓXIMOS PASSOS:"
echo "1. Anotar o endereço do Proxy (Token Address) retornado acima"
echo "2. Usar esse endereço no arquivo de configuração do Hyperlane"
echo "3. Configurar routers remotos usando o Hyperlane CLI"
echo ""
echo "O contrato deployado TEM a funcionalidade de queima (0.01%) implementada!"
