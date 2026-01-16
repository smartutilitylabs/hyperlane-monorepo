# Guide: Manual Deployment of HypERC20 with Burn Functionality on Optimism

This guide explains how to manually deploy the HypERC20 contract with burn functionality (0.01%) on Optimism using Foundry, since the Hyperlane CLI deploys the official version without this functionality.

## ⚠️ Problem Identified

The Hyperlane CLI always deploys the **official** version of HypERC20 from the Hyperlane repository, which **does NOT have** the burn functionality. The local code has the burn, but the CLI does not use this code.

## Solution: Manual Deployment with Foundry

### Prerequisites

1. **Foundry installed**:
   ```bash
   curl -L https://foundry.paradigm.xyz | bash
   foundryup
   ```

2. **Environment variables**:
   ```bash
   export PRIVATE_KEY="0xYOUR_PRIVATE_KEY"
   export RPC_URL="https://mainnet.optimism.io"
   ```

### Optimism Network Configuration

**Chain Details:**
- **Chain ID**: 10
- **Domain ID**: 10
- **Network Name**: Optimism (OP Mainnet)
- **Native Token**: ETH (18 decimals)
- **RPC URLs**:
  - Primary: `https://mainnet.optimism.io`
  - Backup: `https://optimism.drpc.org`
  - Backup: `https://optimism-rpc.publicnode.com`
  - Backup: `https://op-pokt.nodies.app`

**Hyperlane Addresses:**
- **Mailbox**: `0xd4C1905BB1D26BC93DAC913e13CaCC278CdCC80D`

**Validators (MessageIdMultisig ISM):**
- Abacus Works: `0x20349eadc6c72e94ce38268b96692b1a5c20de4f`
- Tessellated: `0x0d4c1394a255568ec0ecd11795b28d1bda183ca4`
- Enigma: `0xd8c1cCbfF28413CE6c6ebe11A3e29B0D8384eDbB`
- Imperator: `0x1b9e5f36c4bfdb0e3f0df525ef5c888a4459ef99`
- Luganodes: `0xf9dfaa5c20ae1d84da4b2696b8dc80c919e48b12`
- Zee Prime: `0x5450447aee7b544c462c9352bef7cad049b0c2dc`

### Step 1: Compile the Contract

```bash
cd ~/smart-hyperlane-monorepo/solidity

# Compile contracts
forge build
```

### Step 2: Create Deployment Script (if needed)

If you don't have a deployment script yet, create one similar to `DeployHypERC20WithBurn.s.sol`:

```solidity
// SPDX-License-Identifier: Apache-2.0
pragma solidity >=0.8.0;

import {Script} from "forge-std/Script.sol";
import {HypERC20} from "../contracts/token/HypERC20.sol";

contract DeployHypERC20WithBurn is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        // Optimism Mailbox address
        address mailbox = 0xd4C1905BB1D26BC93DAC913e13CaCC278CdCC80D;
        
        // Deploy HypERC20 with burn (0.01%)
        // Constructor parameters: decimals, scale, mailbox
        uint8 decimals = 18; // Adjust based on your token
        uint256 scale = 1;   // Adjust based on your token
        HypERC20 token = new HypERC20(decimals, scale, mailbox);

        console.log("HypERC20 deployed at:", address(token));
        console.log("Mailbox:", mailbox);
        console.log("Decimals:", decimals);

        vm.stopBroadcast();
    }
}
```

### Step 3: Execute Deployment Script

```bash
# Execute deployment script on Optimism
forge script script/DeployHypERC20WithBurn.s.sol:DeployHypERC20WithBurn \
  --rpc-url $RPC_URL \
  --broadcast \
  --verify \
  --etherscan-api-key GP69JEAP2W7YFJT9ZJTEPGQT6Y6KMW44ZN \
  -vvvv
```

**Note**: Make sure you have:
- Sufficient ETH on Optimism for gas fees
- Etherscan API key for verification (optional but recommended)
- Correct RPC URL pointing to Optimism mainnet

### Step 4: Configure in Hyperlane

After deployment, you need to:

1. **Register the contract in the Hyperlane registry**
2. **Configure remote routers**
3. **Configure the ISM**

#### Configure ISM (Interchain Security Module)

For Optimism, use MessageIdMultisig ISM with the validators above:

```yaml
optimism:
  type: synthetic
  name: "YOUR_TOKEN_NAME"
  symbol: "YOUR_SYMBOL"
  decimals: 18
  initialSupply: 1000000000000000000000000  # Adjust based on your needs
  owner: "0xYOUR_OWNER_ADDRESS"
  mailbox: "0xd4C1905BB1D26BC93DAC913e13CaCC278CdCC80D"
  interchainSecurityModule:
    type: messageIdMultisigIsm
    validators:
      - "0x20349eadc6c72e94ce38268b96692b1a5c20de4f"  # Abacus Works
      - "0x0d4c1394a255568ec0ecd11795b28d1bda183ca4"  # Tessellated
      - "0xd8c1cCbfF28413CE6c6ebe11A3e29B0D8384eDbB"  # Enigma
      - "0x1b9e5f36c4bfdb0e3f0df525ef5c888a4459ef99"  # Imperator
      - "0xf9dfaa5c20ae1d84da4b2696b8dc80c919e48b12"  # Luganodes
      - "0x5450447aee7b544c462c9352bef7cad049b0c2dc"  # Zee Prime
    threshold: 4  # At least 4 out of 6 validators must sign
```

**Recommended Threshold**: For 6 validators, use threshold 4 (majority) for security.

### Step 5: Verify Deployment

1. **Check contract on Optimism Explorer**:
   ```
   https://optimistic.etherscan.io/address/YOUR_CONTRACT_ADDRESS
   ```

2. **Verify the contract code**:
   ```bash
   forge verify-contract \
     YOUR_CONTRACT_ADDRESS \
     contracts/token/HypERC20.sol:HypERC20 \
     --chain-id 10 \
     --etherscan-api-key GP69JEAP2W7YFJT9ZJTEPGQT6Y6KMW44ZN \
     --constructor-args $(cast abi-encode "constructor(uint8,uint256,address)" 18 1 0xd4C1905BB1D26BC93DAC913e13CaCC278CdCC80D)
   ```

3. **Test burn functionality**:
   - Make a local transfer
   - Verify 0.01% was burned
   - Check the burn event was emitted

## Alternative: Use Manually Deployed Contract

If you have already done the manual deployment, you can use the contract address in the configuration file:

```yaml
optimism:
  type: synthetic
  # Use foreignDeployment to reference an already deployed contract
  foreignDeployment: "0xYOUR_MANUAL_DEPLOYED_CONTRACT"
  name: "YOUR_TOKEN_NAME"
  symbol: "YOUR_SYMBOL"
  decimals: 18
  initialSupply: 1000000000000000000000000
  owner: "0xYOUR_OWNER_ADDRESS"
  mailbox: "0xd4C1905BB1D26BC93DAC913e13CaCC278CdCC80D"
  interchainSecurityModule:
    type: messageIdMultisigIsm
    validators:
      - "0x20349eadc6c72e94ce38268b96692b1a5c20de4f"
      - "0x0d4c1394a255568ec0ecd11795b28d1bda183ca4"
      - "0xd8c1cCbfF28413CE6c6ebe11A3e29B0D8384eDbB"
      - "0x1b9e5f36c4bfdb0e3f0df525ef5c888a4459ef99"
      - "0xf9dfaa5c20ae1d84da4b2696b8dc80c919e48b12"
      - "0x5450447aee7b544c462c9352bef7cad049b0c2dc"
    threshold: 4
```

## ⚠️ IMPORTANT

Manual deployment creates a standalone contract, but to work completely with Hyperlane, you still need to:

1. **Configure remote routers** - Connect to other chains in your warp route
2. **Configure the ISM** - Set up security module with validators
3. **Register in the registry** - Register the contract with Hyperlane
4. **Set destination gas** - Configure gas for cross-chain messages
5. **Enroll remote routers** - Connect to routers on destination chains

The manual deployment script creates the contract, but you will need to do the additional configuration manually or use the Hyperlane CLI to configure the routers.

## Troubleshooting

### Common Issues

1. **Insufficient Gas**: Optimism gas fees are typically lower than Ethereum, but ensure you have enough ETH
2. **RPC Connection**: If the primary RPC fails, try the backup URLs listed above
3. **Verification Issues**: Make sure your Etherscan API key has access to Optimism network
4. **Contract Verification**: Use `--constructor-args` with the correct parameters for verification

### Useful Commands

```bash
# Check balance on Optimism
cast balance YOUR_ADDRESS --rpc-url https://mainnet.optimism.io

# Check contract code
cast code YOUR_CONTRACT_ADDRESS --rpc-url https://mainnet.optimism.io

# Send transaction (example)
cast send --rpc-url https://mainnet.optimism.io --private-key $PRIVATE_KEY \
  YOUR_CONTRACT_ADDRESS \
  "function_name(uint256)" 1000000
```

## Resources

- **Optimism Explorer**: https://optimistic.etherscan.io
- **OP Mainnet Explorer**: https://optimism.blockscout.com
- **Hyperlane Docs**: https://docs.hyperlane.xyz
- **Optimism Docs**: https://docs.optimism.io
