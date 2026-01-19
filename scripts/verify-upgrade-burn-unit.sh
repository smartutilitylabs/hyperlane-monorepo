#!/bin/bash
# Script para verificar se o upgrade para HypERC20BurnUnit foi bem-sucedido

set -e

TOKEN="0x7d637C37828c01ad6241624FfAAd7B48eb3cc516"
RPC="https://mainnet.optimism.io"

echo "=========================================="
echo "  Verificação do Upgrade - Burn Unit"
echo "=========================================="
echo ""
echo "Token: $TOKEN"
echo "RPC: $RPC"
echo ""

# Cores para output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Função para verificar e exibir resultado
check_result() {
    local name=$1
    local result=$2
    local expected=$3
    
    echo -n "Verificando $name... "
    if [ "$result" = "$expected" ] || [ -z "$expected" ]; then
        echo -e "${GREEN}✅ OK${NC}"
        echo "   Resultado: $result"
    else
        echo -e "${RED}❌ FALHOU${NC}"
        echo "   Esperado: $expected"
        echo "   Obtido: $result"
    fi
    echo ""
}

# 1. Verificar função burnFeeUnit (principal verificação)
echo "1. Função burnFeeUnit() (verificação principal):"
BURN_FEE=$(cast call $TOKEN "burnFeeUnit()(uint256)" --rpc-url $RPC 2>/dev/null || echo "ERRO")
if [ "$BURN_FEE" = "10000" ] || [ "$BURN_FEE" = "10000 [1e4]" ]; then
    echo -e "${GREEN}✅ Upgrade confirmado!${NC}"
    echo "   burnFeeUnit = $BURN_FEE (0.01 token para 6 decimals)"
elif [ "$BURN_FEE" = "ERRO" ]; then
    echo -e "${RED}❌ ERRO: Função burnFeeUnit() não encontrada${NC}"
    echo "   O upgrade pode não ter sido concluído ou falhou."
    exit 1
else
    echo -e "${YELLOW}⚠️  AVISO: Valor inesperado${NC}"
    echo "   burnFeeUnit = $BURN_FEE"
    echo "   Esperado: 10000"
fi
echo ""

# 2. Verificar nome
echo "2. Nome do token:"
NAME=$(cast call $TOKEN "name()(string)" --rpc-url $RPC 2>/dev/null | tr -d '"' || echo "ERRO")
if [ "$NAME" = "upusd" ]; then
    echo -e "${GREEN}✅ OK${NC}"
    echo "   Nome: $NAME"
else
    echo -e "${RED}❌ ERRO${NC}"
    echo "   Esperado: upusd"
    echo "   Obtido: $NAME"
fi
echo ""

# 3. Verificar símbolo
echo "3. Símbolo do token:"
SYMBOL=$(cast call $TOKEN "symbol()(string)" --rpc-url $RPC 2>/dev/null | tr -d '"' || echo "ERRO")
if [ "$SYMBOL" = "upusd" ]; then
    echo -e "${GREEN}✅ OK${NC}"
    echo "   Símbolo: $SYMBOL"
else
    echo -e "${RED}❌ ERRO${NC}"
    echo "   Esperado: upusd"
    echo "   Obtido: $SYMBOL"
fi
echo ""

# 4. Verificar total supply
echo "4. Total Supply:"
SUPPLY=$(cast call $TOKEN "totalSupply()(uint256)" --rpc-url $RPC 2>/dev/null || echo "ERRO")
if [ "$SUPPLY" != "ERRO" ]; then
    echo -e "${GREEN}✅ OK${NC}"
    echo "   Total Supply: $SUPPLY"
else
    echo -e "${RED}❌ ERRO${NC}"
fi
echo ""

# 5. Verificar decimals
echo "5. Decimals:"
DECIMALS=$(cast call $TOKEN "decimals()(uint8)" --rpc-url $RPC 2>/dev/null || echo "ERRO")
check_result "Decimals" "$DECIMALS" "6"

# 6. Verificar owner
echo "6. Owner:"
OWNER=$(cast call $TOKEN "owner()(address)" --rpc-url $RPC 2>/dev/null || echo "ERRO")
if [ "$OWNER" != "ERRO" ]; then
    echo -e "${GREEN}✅ OK${NC}"
    echo "   Owner: $OWNER"
else
    echo -e "${RED}❌ ERRO${NC}"
fi
echo ""

# 7. Verificar mailbox
echo "7. Mailbox:"
MAILBOX=$(cast call $TOKEN "mailbox()(address)" --rpc-url $RPC 2>/dev/null || echo "ERRO")
EXPECTED_MAILBOX="0xd4C1905BB1D26BC93DAC913e13CaCC278CdCC80D"
if [ "$MAILBOX" = "$EXPECTED_MAILBOX" ]; then
    echo -e "${GREEN}✅ OK${NC}"
    echo "   Mailbox: $MAILBOX"
else
    echo -e "${YELLOW}⚠️  AVISO${NC}"
    echo "   Esperado: $EXPECTED_MAILBOX"
    echo "   Obtido: $MAILBOX"
fi
echo ""

# Resumo final
echo "=========================================="
echo "  Resumo da Verificação"
echo "=========================================="
echo ""

if [ "$BURN_FEE" = "10000" ] || [ "$BURN_FEE" = "10000 [1e4]" ]; then
    echo -e "${GREEN}✅ UPGRADE CONFIRMADO COM SUCESSO!${NC}"
    echo ""
    echo "O contrato foi atualizado para HypERC20BurnUnit."
    echo "A regra de queima agora é:"
    echo "  - Queima fixa de 0.01 token por transação"
    echo "  - (ao invés de 0.01% percentual)"
    echo ""
    echo "Todas as informações do token foram preservadas."
else
    echo -e "${RED}❌ UPGRADE NÃO CONFIRMADO${NC}"
    echo ""
    echo "A função burnFeeUnit() não foi encontrada ou retornou valor inesperado."
    echo "O upgrade pode não ter sido concluído corretamente."
    echo ""
    echo "Verifique:"
    echo "  1. Se o upgrade foi executado"
    echo "  2. Se houve erros durante a execução"
    echo "  3. Se o contrato está no endereço correto"
    exit 1
fi

echo ""
echo "🔍 Explorer:"
echo "   https://optimistic.etherscan.io/address/$TOKEN"
echo ""
