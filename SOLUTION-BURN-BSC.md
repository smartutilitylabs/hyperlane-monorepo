# Solution: Deploy HypERC20 with Burn Functionality on BSC

## ⚠️ Problem Identified

The Hyperlane CLI always deploys the **official** version of HypERC20 from the npm package `@hyperlane-xyz/core`, which **does NOT have** the burn functionality. The local code (`solidity/contracts/token/HypERC20.sol`) has the burn implemented, but the CLI does not use this code.

## ✅ Solution: Manual Deployment with Foundry

### Option 1: Complete Manual Deployment (Recommended)

1. **Install Soldeer dependencies** (Foundry dependency manager):
   ```bash
   cd ~/smart-hyperlane-monorepo/solidity
   forge soldeer install
   ```

2. **Compile contracts**:
   ```bash
   forge build
   ```

3. **Execute deployment script**:
   ```bash
   export PRIVATE_KEY="0x819b680e3578eac4f79b8fde643046e88f3f9bb10a3ce1424e3642798ef39b42"
   
   forge script script/DeployHypERC20WithBurn.s.sol:DeployHypERC20WithBurn \
     --rpc-url https://bsc-testnet.publicnode.com \
     --broadcast \
     --legacy \
     -vvv
   ```

4. **Note the Proxy address** returned (this will be the token address)

5. **Use the deployed contract in Hyperlane**:
   - The contract will already be deployed and initialized
   - You will need to configure remote routers manually
   - Or use the Hyperlane CLI to configure only the routers

### Option 2: Use Automated Script

```bash
cd ~/smart-hyperlane-monorepo
./scripts/deploy-hyp-erc20-burn-completo.sh
```

## 📝 After Manual Deployment

After doing the manual deployment, you will have:
- ✅ HypERC20 contract with burn functionality (0.01%)
- ✅ Initial supply of 15,000,000,000 tokens
- ✅ Contract initialized and ready to use

**Next steps:**
1. Test local transfer to verify burn
2. Configure remote routers using Hyperlane CLI
3. Link with other chains

## 🔍 Verify Burn Functionality

### Step 1: Transfer Tokens to Test

After deployment, test a transfer:

```bash
# Replace <TOKEN_ADDRESS> with your deployed contract address
# Example: 0xC61134c6794043db11120018BbFDD2F4280F2268

TOKEN_ADDRESS="<TOKEN_ADDRESS>"
RECIPIENT="0x867f9CE9F0D7218b016351CB6122406E6D247a5e"
AMOUNT="100000000"  # 100 tokens with 6 decimals

# Make transfer
cast send ${TOKEN_ADDRESS} \
  "transfer(address,uint256)" \
  ${RECIPIENT} \
  ${AMOUNT} \
  --rpc-url https://bsc-testnet.publicnode.com \
  --private-key 0x819b680e3578eac4f79b8fde643046e88f3f9bb10a3ce1424e3642798ef39b42 \
  --legacy
```

### Step 2: Verify Burn on BscScan

1. **Access the transaction on BscScan** using the returned hash:
   ```
   https://testnet.bscscan.com/tx/<TRANSACTION_HASH>
   ```

2. **Look for the `BurnFeeApplied` event**:
   - `totalAmount`: `100000000` (100 tokens sent)
   - `burnAmount`: `10000` (0.01 token burned = 0.01%)
   - `transferAmount`: `99990000` (99.99 tokens received)

3. **Also verify**:
   - Transfer to `0x0000...0000` (zero address) = burned tokens (10000)
   - Transfer to recipient = received tokens (99990000)

### Step 3: Verify Results via CLI

```bash
# Verify total supply (should have decreased by 10000)
cast call ${TOKEN_ADDRESS} \
  "totalSupply()" \
  --rpc-url https://bsc-testnet.publicnode.com

# Verify recipient balance (should have 99990000 = 99.99 tokens)
cast call ${TOKEN_ADDRESS} \
  "balanceOf(address)" \
  ${RECIPIENT} \
  --rpc-url https://bsc-testnet.publicnode.com

# Verify owner balance (should have decreased by 100000000)
cast call ${TOKEN_ADDRESS} \
  "balanceOf(address)" \
  0x8BD456605473ad4727ACfDCA0040a0dBD4be2DEA \
  --rpc-url https://bsc-testnet.publicnode.com
```

### Complete Test Example

```bash
# Variables
TOKEN_ADDRESS="0xC61134c6794043db11120018BbFDD2F4280F2268"
RECIPIENT="0x867f9CE9F0D7218b016351CB6122406E6D247a5e"
AMOUNT="100000000"  # 100 tokens with 6 decimals
PRIVATE_KEY="0x819b680e3578eac4f79b8fde643046e88f3f9bb10a3ce1424e3642798ef39b42"
RPC_URL="https://bsc-testnet.publicnode.com"

# 1. Verify supply before
echo "=== Supply before ==="
cast call ${TOKEN_ADDRESS} "totalSupply()" --rpc-url ${RPC_URL}

# 2. Make transfer
echo ""
echo "=== Making transfer of 100 tokens ==="
cast send ${TOKEN_ADDRESS} \
  "transfer(address,uint256)" \
  ${RECIPIENT} \
  ${AMOUNT} \
  --rpc-url ${RPC_URL} \
  --private-key ${PRIVATE_KEY} \
  --legacy

# 3. Verify supply after (should have decreased by 10000)
echo ""
echo "=== Supply after (should have decreased by 10000) ==="
cast call ${TOKEN_ADDRESS} "totalSupply()" --rpc-url ${RPC_URL}

# 4. Verify recipient balance (should have received 99990000)
echo ""
echo "=== Recipient balance (should have 99990000 = 99.99 tokens) ==="
cast call ${TOKEN_ADDRESS} \
  "balanceOf(address)" \
  ${RECIPIENT} \
  --rpc-url ${RPC_URL}
```

## ⚠️ Limitations

- Manual deployment creates a standalone contract
- You will need to configure remote routers manually
- The Hyperlane CLI does not fully manage manually deployed contracts

## 📚 Files Created

- `solidity/script/DeployHypERC20WithBurn.s.sol` - Deployment script
- `scripts/deploy-hyp-erc20-burn-completo.sh` - Automated script
- `MANUAL-DEPLOY-HYP-ERC20-BURN.md` - Detailed guide
