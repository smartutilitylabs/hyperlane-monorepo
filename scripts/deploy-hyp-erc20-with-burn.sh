#!/bin/bash
# Script para fazer deploy manual do HypERC20 com funcionalidade de queima
# Este script compila e faz deploy do contrato HypERC20 modificado com queima

set -e

# Variáveis
CONTRACT_ADDRESS="0xbc7637a1705ae06dd47a9439c0566273620009f0"  # Contrato atual (será substituído)
TOKEN_NAME="upusd"
TOKEN_SYMBOL="upusd"
TOKEN_DECIMALS=6
INITIAL_SUPPLY=15000000000
OWNER="0x8BD456605473ad4727ACfDCA0040a0dBD4be2DEA"
MAILBOX="0xF9F6F5646F478d5ab4e20B0F910C92F1CCC9Cc6D"
IGP="0x0dD20e410bdB95404f71c5a4e7Fa67B892A5f949"
ISM="0xe4245cCB6427Ba0DC483461bb72318f5DC34d090"
PRIVATE_KEY="0x819b680e3578eac4f79b8fde643046e88f3f9bb10a3ce1424e3642798ef39b42"
RPC_URL="https://bsc-testnet.publicnode.com"

echo "⚠️  IMPORTANTE: Este script requer:"
echo "   1. Foundry instalado (forge, cast)"
echo "   2. Contrato HypERC20.sol com funcionalidade de queima no diretório solidity/"
echo ""
echo "O contrato HypERC20.sol já tem a funcionalidade de queima implementada."
echo "Você precisa fazer o deploy manual usando Foundry ou Hardhat."
echo ""
echo "Opções:"
echo "1. Usar Foundry (forge) para compilar e fazer deploy"
echo "2. Usar Hardhat para compilar e fazer deploy"
echo "3. Verificar se o contrato atual tem a funcionalidade de queima"
