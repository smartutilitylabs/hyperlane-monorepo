#!/bin/bash
# Script completo para fazer deploy do HypNative (Token Nativo) na Optimism
# Este script faz o deploy manual usando Foundry

set -e

echo "⚠️  IMPORTANTE: Este script faz deploy MANUAL do HypNative (Token Nativo)"
echo "   HypNative permite wrap do ETH nativo e transferências cross-chain via Hyperlane"
echo ""

# Variáveis de ambiente
PRIVATE_KEY="0xab38f039a24acdbeef8d2270bb8887a235f3271f15140777ad08dd72511a36f3"
RPC_URL="https://mainnet.optimism.io"
CHAIN_ID=10

# Configurações oficiais da Optimism Mainnet
MAILBOX="0xd4C1905BB1D26BC93DAC913e13CaCC278CdCC80D"
INTERCHAIN_SECURITY_MODULE="0x38164E63A4F67b32b2EfF4b45aCC1f2EE9b77b07"
INTERCHAIN_GAS_PAYMASTER="0xD8A76C4D91fCbB7Cc8eA795DFDF870E48368995C"
PROXY_ADMIN="0xE047cb95FB3b7117989e911c6afb34771183fC35"
VALIDATOR_ANNOUNCE="0x30f5b08e01808643221528BB2f7953bf2830Ef38"
HOOK="0x0000000000000000000000000000000000000000" # Configurar hook depois se necessário

# Endereços adicionais da Optimism (referência)
AGGREGATION_HOOK="0xb959001ec9706d56fC7787e126caC2Ad3a7158a7"
CCIP_HOOK_BASE="0xadC2aaE7affb4a7D4E362715D1b99E65DcEcDa0c"
CCIP_HOOK_MODE="0x039E1AdD839f78A1B8567DCDeE7F058187d426bd"
CCIP_ISM_BASE="0x9E14846655d56fd8Bd08ac977e489AbDe2297aAB"
CCIP_ISM_MODE="0x859295c13ED98785715a177539db2B040866E909"
DOMAIN_ROUTING_ISM="0xDFfFCA9320E2c7530c61c4946B4c2376A1901dF2"
DOMAIN_ROUTING_ISM_FACTORY="0xD2e905108c5e44dADA680274740f896Ea96Cf2Fb"
FALLBACK_ROUTING_HOOK="0xD4b132C6d4AA93A4247F1A91e1ED929c0572a43d"
INTERCHAIN_ACCOUNT_ROUTER="0x3E343D07D024E657ECF1f8Ae8bb7a12f08652E75"
MERKLE_TREE_HOOK="0x68eE9bec9B4dbB61f69D9D293Ae26a5AACb2e28f"
PAUSABLE_HOOK="0xf753CA2269c8A7693ce1808b5709Fbf36a65D47A"
PAUSABLE_ISM="0xD84D8114cCfa5c2403E56aBf754da529430704F0"
PROTOCOL_FEE="0xD71Ff941120e8f935b8b1E2C1eD72F5d140FF458"
STATIC_AGGREGATION_HOOK_FACTORY="0xb0464AE267dbD8b0c611D7768Cd658d4c39b54d6"
STATIC_AGGREGATION_ISM="0xdF6316DF574974110DCC94BB4E520B09Fe3CbEf9"
STATIC_AGGREGATION_ISM_FACTORY="0x7491843F3A5Ba24E0f17a22645bDa04A1Ae2c584"
STATIC_MERKLE_ROOT_MULTISIG_ISM_FACTORY="0xCA6Cb9Bc3cfF9E11003A06617cF934B684Bc78BC"
STATIC_MERKLE_ROOT_WEIGHTED_MULTISIG_ISM_FACTORY="0x313b18228236bf89fc67cca152c62f1896eEa362"
STATIC_MESSAGE_ID_MULTISIG_ISM_FACTORY="0xAa4Be20E9957fE21602c74d7C3cF5CB1112EA9Ef"
STATIC_MESSAGE_ID_WEIGHTED_MULTISIG_ISM_FACTORY="0x3A2e96403d076e9f953166A9E4c61bcD9D164CFe"
STORAGE_GAS_ORACLE="0x27e88AeB8EA4B159d81df06355Ea3d20bEB1de38"

# Parâmetros do token (baseado em MANUAL-DEPLOY-HYP-ERC20-BURN.md linhas 62-68)
# Nota: HypNative é um token nativo (ETH), então name/symbol são para metadados
# HypNative não tem initialSupply pois usa ETH nativo como collateral
NAME="upusd"
SYMBOL="upusd"
DECIMALS=6
SCALE=1  # Escala 1:1 entre ETH nativo e wrapped token

# Owner do contrato (baseado em MANUAL-DEPLOY-HYP-ERC20-BURN.md)
OWNER="0x6d7fFa706F4898f87083255a44eEC503ED02Ab78"

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
echo "=== Passo 5: Usar Script de Deploy Existente ==="
SCRIPT_DIR="$HOME/smart-hyperlane-monorepo/solidity/script"
SCRIPT_FILE="$SCRIPT_DIR/DeployHypNativeOptimism.s.sol"

if [ ! -f "$SCRIPT_FILE" ]; then
    echo "❌ Script não encontrado em $SCRIPT_FILE"
    echo "   Por favor, certifique-se de que o arquivo existe antes de executar o deploy"
    exit 1
fi

echo "✅ Script de deploy encontrado: $SCRIPT_FILE"

echo ""
echo "=== Passo 6: Deploy do Contrato ==="
echo "Executando script de deploy..."
echo ""

export PRIVATE_KEY
export RPC_URL

# Executar deploy e capturar output
DEPLOY_OUTPUT=$(forge script script/DeployHypNativeOptimism.s.sol:DeployHypNativeOptimism \
  --rpc-url ${RPC_URL} \
  --broadcast \
  --verify \
  --etherscan-api-key GP69JEAP2W7YFJT9ZJTEPGQT6Y6KMW44ZN \
  --legacy \
  -vvvv 2>&1)

echo "$DEPLOY_OUTPUT"

# Extrair endereço do Proxy do output
# Primeiro, tenta buscar no arquivo de broadcast (mais confiável)
BROADCAST_DIR="$HOME/smart-hyperlane-monorepo/solidity/broadcast/DeployHypNativeOptimism.s.sol/$CHAIN_ID"
BROADCAST_FILE=""
if [ -d "$BROADCAST_DIR" ]; then
    # Encontra o arquivo mais recente
    BROADCAST_FILE=$(ls -t "$BROADCAST_DIR"/*.json 2>/dev/null | head -1)
fi

HYPNATIVE_ADDRESS=""

# Tenta extrair do arquivo de broadcast primeiro
if [ -n "$BROADCAST_FILE" ] && [ -f "$BROADCAST_FILE" ]; then
    # Procura por TransparentUpgradeableProxy no arquivo de broadcast
    if command -v jq &> /dev/null; then
        HYPNATIVE_ADDRESS=$(jq -r '.transactions[] | select(.contractName == "TransparentUpgradeableProxy") | .contractAddress' "$BROADCAST_FILE" 2>/dev/null | grep -E "^0x[a-fA-F0-9]{40}$" | head -1)
    fi
    
    # Se não encontrou com jq, tenta grep
    if [ -z "$HYPNATIVE_ADDRESS" ] || [ "$HYPNATIVE_ADDRESS" = "null" ]; then
        HYPNATIVE_ADDRESS=$(grep -oE '"contractAddress"\s*:\s*"0x[a-fA-F0-9]{40}"' "$BROADCAST_FILE" 2>/dev/null | grep -oE "0x[a-fA-F0-9]{40}" | tail -1)
    fi
fi

# Se ainda não encontrou, tenta do output do console
if [ -z "$HYPNATIVE_ADDRESS" ] || [ ${#HYPNATIVE_ADDRESS} -ne 42 ]; then
    # Procura por "Proxy (HypNative Address):" no output
    HYPNATIVE_ADDRESS=$(echo "$DEPLOY_OUTPUT" | grep -i "Proxy (HypNative Address):" | tail -1 | grep -oE "0x[a-fA-F0-9]{40}" | head -1)
fi

# Se ainda não encontrou, tenta outros padrões
if [ -z "$HYPNATIVE_ADDRESS" ] || [ ${#HYPNATIVE_ADDRESS} -ne 42 ]; then
    HYPNATIVE_ADDRESS=$(echo "$DEPLOY_OUTPUT" | grep -iE "proxy deployed at:|Deployed to:" | tail -1 | grep -oE "0x[a-fA-F0-9]{40}" | head -1)
fi

echo ""
echo "✅ Deploy completo!"

if [ -z "$HYPNATIVE_ADDRESS" ] || [ "$HYPNATIVE_ADDRESS" = "0x" ] || [ ${#HYPNATIVE_ADDRESS} -ne 42 ]; then
    echo "⚠️  AVISO: Não foi possível extrair automaticamente o endereço do contrato."
    echo "   Por favor, anote o endereço do Proxy (HypNative Address) do output acima"
    echo "   e atualize manualmente o arquivo de configuração warp."
    HYPNATIVE_ADDRESS="<HYPNATIVE_ADDRESS>"
else
    echo "✅ Endereço do HypNative extraído: $HYPNATIVE_ADDRESS"
fi

echo ""
echo "=== Passo 7: Criar Arquivo de Configuração Warp ==="

# Criar diretório para configuração warp
# Nota: Usando mainnet pois estamos deployando na Optimism Mainnet
WARP_CONFIG_DIR="$HOME/smart-hyperlane-monorepo/environments/mainnet/warp-routes/${SYMBOL}-optimism"
mkdir -p "$WARP_CONFIG_DIR"

# Criar arquivo de configuração warp
WARP_CONFIG_FILE="$WARP_CONFIG_DIR/warp-route-deployment.yaml"

cat > "$WARP_CONFIG_FILE" << EOFWARP
---
# Configuração do Warp Route Nativo (HypNative) na Optimism Mainnet
# Token nativo que permite wrap do ETH e transferências cross-chain via Hyperlane
# 
# Este arquivo foi gerado automaticamente pelo script deploy-hypnative-optimism-completo.sh
# Baseado no exemplo: https://github.com/hyperlane-xyz/hyperlane-monorepo/blob/main/typescript/cli/examples/warp-route-deployment.yaml

optimism:
  type: native  # Token nativo (HypNative)
  isNft: false  # Token fungível (false) ou NFT (true)
  
  # Metadados do token
  name: "$NAME"
  symbol: "$SYMBOL"
  decimals: $DECIMALS
  
  # Owner do contrato
  owner: "$OWNER"
  
  # Endereço do Mailbox (obrigatório)
  mailbox: "$MAILBOX"
  
  # Interchain Gas Paymaster (opcional, mas recomendado)
  interchainGasPaymaster: "$INTERCHAIN_GAS_PAYMASTER"
  
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
  foreignDeployment: "$HYPNATIVE_ADDRESS"
EOFWARP

echo "✅ Arquivo de configuração warp criado: $WARP_CONFIG_FILE"
echo ""

echo "════════════════════════════════════════════════════════════"
echo "📋 RESUMO DO DEPLOY"
echo "════════════════════════════════════════════════════════════"
echo ""
echo "✅ Contrato HypNative deployado!"
if [ "$HYPNATIVE_ADDRESS" != "<HYPNATIVE_ADDRESS>" ]; then
    echo "   Endereço: $HYPNATIVE_ADDRESS"
fi
echo ""
echo "✅ Arquivo de configuração warp criado:"
echo "   $WARP_CONFIG_FILE"
echo ""
echo "⚠️  PRÓXIMOS PASSOS OBRIGATÓRIOS:"
echo ""
echo "1. Configurar ISM (Interchain Security Module):"
if [ "$HYPNATIVE_ADDRESS" != "<HYPNATIVE_ADDRESS>" ]; then
    echo "   cast send $HYPNATIVE_ADDRESS \\"
else
    echo "   cast send <HYPNATIVE_ADDRESS> \\"
fi
echo "     \"setInterchainSecurityModule(address)\" \\"
echo "     $INTERCHAIN_SECURITY_MODULE \\"
echo "     --rpc-url $RPC_URL \\"
echo "     --private-key $PRIVATE_KEY"
echo ""
echo "2. Usar o arquivo de configuração warp para conectar com outras chains:"
echo "   hyperlane warp deploy \\"
echo "     --config $WARP_CONFIG_FILE"
echo ""
echo "3. Depositar ETH nativo (opcional mas recomendado):"
if [ "$HYPNATIVE_ADDRESS" != "<HYPNATIVE_ADDRESS>" ]; then
    echo "   cast send $HYPNATIVE_ADDRESS \\"
else
    echo "   cast send <HYPNATIVE_ADDRESS> \\"
fi
echo "     \"deposit(address)\" \\"
echo "     $OWNER \\"
echo "     --value 1ether \\"
echo "     --rpc-url $RPC_URL \\"
echo "     --private-key $PRIVATE_KEY"
echo ""
echo "════════════════════════════════════════════════════════════"
echo ""
echo "📝 Configurações usadas:"
echo "   - Rede: Optimism Mainnet (Chain ID: $CHAIN_ID)"
echo "   - Mailbox: $MAILBOX"
echo "   - Deployer: $DEPLOYER_ADDRESS"
echo "   - Owner: $OWNER"
echo "   - Scale: $SCALE (1:1 ratio)"
if [ "$HYPNATIVE_ADDRESS" != "<HYPNATIVE_ADDRESS>" ]; then
    echo "   - HypNative Address: $HYPNATIVE_ADDRESS"
fi
echo ""
echo "🔗 Links úteis:"
echo "   - Optimism Explorer: https://optimistic.etherscan.io"
echo "   - OP Mainnet Explorer: https://optimism.blockscout.com"
if [ "$HYPNATIVE_ADDRESS" != "<HYPNATIVE_ADDRESS>" ]; then
    echo "   - Contrato no Explorer: https://optimistic.etherscan.io/address/$HYPNATIVE_ADDRESS"
fi
echo ""
