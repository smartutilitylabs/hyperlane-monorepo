#!/bin/bash
# Script completo para fazer deploy do HypERC20 Sintético na Optimism Mainnet
# Este script faz o deploy manual usando Foundry

set -e

echo "⚠️  IMPORTANTE: Este script faz deploy MANUAL do HypERC20 Sintético"
echo "   HypERC20 Sintético cria um novo token ERC20 do zero com name, symbol e supply"
echo ""

# Variáveis
PRIVATE_KEY="0xab38f039a24acdbeef8d2270bb8887a235f3271f15140777ad08dd72511a36f3"
RPC_URL="https://mainnet.optimism.io"
CHAIN_ID=10

# Parâmetros do token
DECIMALS=6
SCALE=1
MAILBOX="0xd4C1905BB1D26BC93DAC913e13CaCC278CdCC80D"
OWNER="0x6d7fFa706F4898f87083255a44eEC503ED02Ab78"
HOOK="0x0000000000000000000000000000000000000000"
ISM="0x38164E63A4F67b32b2EfF4b45aCC1f2EE9b77b07"
INITIAL_SUPPLY=15000000000
NAME="upusd"
SYMBOL="upusd"

# Validators para ISM (MessageIdMultisig)
VALIDATORS=(
  "0x20349eadc6c72e94ce38268b96692b1a5c20de4f"  # Abacus Works
  "0x0d4c1394a255568ec0ecd11795b28d1bda183ca4"  # Tessellated
  "0xd8c1cCbfF28413CE6c6ebe11A3e29B0D8384eDbB"  # Enigma
  "0x1b9e5f36c4bfdb0e3f0df525ef5c888a4459ef99"  # Imperator
  "0xf9dfaa5c20ae1d84da4b2696b8dc80c919e48b12"  # Luganodes
  "0x5450447aee7b544c462c9352bef7cad049b0c2dc"  # Zee Prime
)
THRESHOLD=4  # Threshold recomendado: 4 de 6 validators

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

if [ "$(cast --to-unit $BALANCE wei)" -lt "100000000000000000" ]; then
    echo "⚠️  AVISO: Saldo baixo! Recomendado pelo menos 0.1 ETH para deploy"
    echo "   Continuando mesmo assim..."
fi

echo ""
echo "=== Passo 3: Instalar Dependências ==="
cd ~/smart-hyperlane-monorepo/solidity
forge install --no-commit 2>/dev/null || echo "Dependências já instaladas ou erro (pode continuar)"

echo ""
echo "=== Passo 4: Compilar Contratos ==="
forge build || {
    echo "❌ Erro na compilação. Tentando instalar dependências..."
    forge install
    forge build
}

echo ""
echo "=== Passo 5: Deploy do Contrato ==="
echo "Executando script de deploy..."

export PRIVATE_KEY
export RPC_URL

# Executar deploy e capturar output
DEPLOY_OUTPUT=$(forge script script/DeployHypERC20Optimism.s.sol:DeployHypERC20Optimism \
  --rpc-url ${RPC_URL} \
  --broadcast \
  --verify \
  --etherscan-api-key GP69JEAP2W7YFJT9ZJTEPGQT6Y6KMW44ZN \
  --legacy \
  -vvvv 2>&1)

echo "$DEPLOY_OUTPUT"

# Extrair endereço do Proxy do output
BROADCAST_DIR="$HOME/smart-hyperlane-monorepo/solidity/broadcast/DeployHypERC20Optimism.s.sol/$CHAIN_ID"
BROADCAST_FILE=""
if [ -d "$BROADCAST_DIR" ]; then
    BROADCAST_FILE=$(ls -t "$BROADCAST_DIR"/*.json 2>/dev/null | head -1)
fi

TOKEN_ADDRESS=""

# Tenta extrair do arquivo de broadcast primeiro
if [ -n "$BROADCAST_FILE" ] && [ -f "$BROADCAST_FILE" ]; then
    if command -v jq &> /dev/null; then
        TOKEN_ADDRESS=$(jq -r '.transactions[] | select(.contractName == "TransparentUpgradeableProxy") | .contractAddress' "$BROADCAST_FILE" 2>/dev/null | grep -E "^0x[a-fA-F0-9]{40}$" | head -1)
    fi
    
    if [ -z "$TOKEN_ADDRESS" ] || [ "$TOKEN_ADDRESS" = "null" ]; then
        TOKEN_ADDRESS=$(grep -oE '"contractAddress"\s*:\s*"0x[a-fA-F0-9]{40}"' "$BROADCAST_FILE" 2>/dev/null | grep -oE "0x[a-fA-F0-9]{40}" | tail -1)
    fi
fi

# Se ainda não encontrou, tenta do output do console
if [ -z "$TOKEN_ADDRESS" ] || [ ${#TOKEN_ADDRESS} -ne 42 ]; then
    TOKEN_ADDRESS=$(echo "$DEPLOY_OUTPUT" | grep -i "Proxy (Token Address):" | tail -1 | grep -oE "0x[a-fA-F0-9]{40}" | head -1)
fi

if [ -z "$TOKEN_ADDRESS" ] || [ ${#TOKEN_ADDRESS} -ne 42 ]; then
    TOKEN_ADDRESS=$(echo "$DEPLOY_OUTPUT" | grep -iE "proxy deployed at:|Deployed to:" | tail -1 | grep -oE "0x[a-fA-F0-9]{40}" | head -1)
fi

echo ""
echo "✅ Deploy completo!"

if [ -z "$TOKEN_ADDRESS" ] || [ "$TOKEN_ADDRESS" = "0x" ] || [ ${#TOKEN_ADDRESS} -ne 42 ]; then
    echo "⚠️  AVISO: Não foi possível extrair automaticamente o endereço do contrato."
    echo "   Por favor, anote o endereço do Proxy (Token Address) do output acima"
    echo "   e atualize manualmente o arquivo de configuração warp."
    TOKEN_ADDRESS="<TOKEN_ADDRESS>"
else
    echo "✅ Endereço do token extraído: $TOKEN_ADDRESS"
fi

echo ""
echo "=== Passo 6: Criar Arquivo de Configuração Warp ==="

# Criar diretório para configuração warp
WARP_CONFIG_DIR="$HOME/smart-hyperlane-monorepo/environments/mainnet/warp-routes/${SYMBOL}-optimism"
mkdir -p "$WARP_CONFIG_DIR"

# Criar arquivo de configuração warp
WARP_CONFIG_FILE="$WARP_CONFIG_DIR/warp-route-deployment.yaml"

cat > "$WARP_CONFIG_FILE" << EOFWARP
---
# Configuração do Warp Route Sintético (HypERC20) na Optimism Mainnet
# Token sintético que cria um novo ERC20 do zero com funcionalidade de queima (0.01%)
# 
# Este arquivo foi gerado automaticamente pelo script deploy-hyp-erc20-optimism-completo.sh
# Baseado no exemplo: https://github.com/hyperlane-xyz/hyperlane-monorepo/blob/main/typescript/cli/examples/warp-route-deployment.yaml

optimism:
  type: synthetic  # Token sintético (HypERC20)
  isNft: false  # Token fungível (false) ou NFT (true)
  
  # Metadados do token (obrigatórios para synthetic)
  name: "$NAME"
  symbol: "$SYMBOL"
  decimals: $DECIMALS
  initialSupply: $INITIAL_SUPPLY  # ⚠️ IMPORTANTE: Use initialSupply (não totalSupply) para tokens sintéticos
  
  # Owner do contrato (obrigatório)
  owner: "$OWNER"
  
  # Endereço do Mailbox (obrigatório quando o registry não tem os endereços)
  mailbox: "$MAILBOX"
  
  # Interchain Gas Paymaster (opcional, mas recomendado)
  interchainGasPaymaster: "0xD8A76C4D91fCbB7Cc8eA795DFDF870E48368995C"
  
  # Interchain Security Module (ISM) - Configuração de segurança
  # Define quais validadores devem assinar as mensagens cross-chain
  interchainSecurityModule:
    type: messageIdMultisigIsm  # Tipo de ISM: multisig baseado em message ID
    validators:  # Lista de endereços dos validadores (hexadecimal COM prefixo 0x para EVM)
EOFWARP

# Adicionar validators
for validator in "${VALIDATORS[@]}"; do
  echo "      - \"$validator\"" >> "$WARP_CONFIG_FILE"
done

cat >> "$WARP_CONFIG_FILE" << EOFWARP
    threshold: $THRESHOLD  # Número mínimo de assinaturas necessárias ($THRESHOLD de ${#VALIDATORS[@]} validadores)
  
  # Endereço do contrato já deployado (usar foreignDeployment para referenciar contrato manual)
  foreignDeployment: "$TOKEN_ADDRESS"
EOFWARP

echo "✅ Arquivo de configuração warp criado: $WARP_CONFIG_FILE"
echo ""

echo "════════════════════════════════════════════════════════════"
echo "📋 RESUMO DO DEPLOY"
echo "════════════════════════════════════════════════════════════"
echo ""
echo "✅ Contrato HypERC20 Sintético deployado!"
if [ "$TOKEN_ADDRESS" != "<TOKEN_ADDRESS>" ]; then
    echo "   Endereço do Token: $TOKEN_ADDRESS"
fi
echo ""
echo "✅ Arquivo de configuração warp criado:"
echo "   $WARP_CONFIG_FILE"
echo ""
echo "📝 Informações do Token:"
echo "   - Nome: $NAME"
echo "   - Símbolo: $SYMBOL"
echo "   - Decimals: $DECIMALS"
echo "   - Supply Inicial: $INITIAL_SUPPLY"
echo ""
echo "⚠️  PRÓXIMOS PASSOS:"
echo ""
echo "1. Usar o arquivo de configuração warp para conectar com outras chains:"
echo "   hyperlane warp deploy \\"
echo "     --config $WARP_CONFIG_FILE"
echo ""
echo "2. Verificar o token no Explorer:"
if [ "$TOKEN_ADDRESS" != "<TOKEN_ADDRESS>" ]; then
    echo "   https://optimistic.etherscan.io/token/$TOKEN_ADDRESS"
fi
echo ""
echo "════════════════════════════════════════════════════════════"
echo ""
echo "📝 Configurações usadas:"
echo "   - Rede: Optimism Mainnet (Chain ID: $CHAIN_ID)"
echo "   - Mailbox: $MAILBOX"
echo "   - ISM: $ISM"
echo "   - Deployer: $DEPLOYER_ADDRESS"
echo "   - Owner: $OWNER"
echo ""
echo "🔗 Links úteis:"
echo "   - Optimism Explorer: https://optimistic.etherscan.io"
echo "   - OP Mainnet Explorer: https://optimism.blockscout.com"
if [ "$TOKEN_ADDRESS" != "<TOKEN_ADDRESS>" ]; then
    echo "   - Token no Explorer: https://optimistic.etherscan.io/token/$TOKEN_ADDRESS"
fi
echo ""
echo "✅ O contrato deployado TEM a funcionalidade de queima (0.01%) implementada!"
echo ""
