#!/bin/bash
# Script para verificar se o contrato tem a funcionalidade de queima

set -e

CONTRACT="0xbc7637a1705ae06dd47a9439c0566273620009f0"
RPC_URL="https://bsc-testnet.publicnode.com"

echo "Verificando se o contrato tem o evento BurnFeeApplied..."
echo ""

# Tentar verificar se o evento existe
# Se o contrato tiver a funcionalidade de queima, ele deve ter o evento BurnFeeApplied
echo "1. Verifique manualmente no BscScan:"
echo "   https://testnet.bscscan.com/address/${CONTRACT}#code"
echo ""
echo "2. Procure por:"
echo "   - Evento 'BurnFeeApplied'"
echo "   - Função 'transfer' que calcula burnAmount"
echo "   - Constante 'BURN_RATE'"
echo ""
echo "3. Se o contrato NÃO tiver a funcionalidade de queima, você precisa:"
echo "   a) Fazer deploy manual do contrato HypERC20.sol modificado"
echo "   b) Ou fazer upgrade do contrato existente (se for upgradeable)"
echo ""

# Verificar eventos na última transação de transfer
echo "4. Verificando eventos na transação de transfer..."
echo "   https://testnet.bscscan.com/tx/0x6348327b98782830987c478bb40643fe43309163d564f2b7a3b8f143f8bd889d#eventlog"
echo ""
echo "   Se não houver evento 'BurnFeeApplied', o contrato não tem a funcionalidade de queima."
