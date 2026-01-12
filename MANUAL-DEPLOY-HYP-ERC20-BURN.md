# Guide: Manual Deployment of HypERC20 with Burn Functionality

This guide explains how to manually deploy the HypERC20 contract with burn functionality (0.01%) using Foundry, since the Hyperlane CLI deploys the official version without this functionality.

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
   export PRIVATE_KEY="0x819b680e3578eac4f79b8fde643046e88f3f9bb10a3ce1424e3642798ef39b42"
   export RPC_URL="https://bsc-testnet.publicnode.com"
   ```

### Step 1: Compile the Contract

```bash
cd ~/smart-hyperlane-monorepo/solidity

# Compile contracts
forge build
```

### Step 2: Execute Deployment Script

```bash
# Execute deployment script
forge script script/DeployHypERC20WithBurn.s.sol:DeployHypERC20WithBurn \
  --rpc-url $RPC_URL \
  --broadcast \
  --verify \
  --legacy \
  -vvvv
```

### Step 3: Configure in Hyperlane

After deployment, you need to:

1. **Register the contract in the Hyperlane registry**
2. **Configure remote routers**
3. **Configure the ISM**

## Alternative: Use Manually Deployed Contract

If you have already done the manual deployment, you can use the contract address in the configuration file:

```yaml
bsctestnet:
  type: synthetic
  # Use foreignDeployment to reference an already deployed contract
  foreignDeployment: "0xYOUR_MANUAL_DEPLOYED_CONTRACT"
  name: "upusd"
  symbol: "upusd"
  decimals: 6
  initialSupply: 15000000000
  owner: "0x8BD456605473ad4727ACfDCA0040a0dBD4be2DEA"
  mailbox: "0xF9F6F5646F478d5ab4e20B0F910C92F1CCC9Cc6D"
  interchainSecurityModule:
    type: messageIdMultisigIsm
    validators:
      - "0x242d8a855a8c932dec51f7999ae7d1e48b10c95e"
      - "0xf620f5e3d25a3ae848fec74bccae5de3edcd8796"
      - "0x1f030345963c54ff8229720dd3a711c15c554aeb"
    threshold: 2
```

## ⚠️ IMPORTANT

Manual deployment creates a standalone contract, but to work completely with Hyperlane, you still need to:

1. Configure remote routers
2. Configure the ISM
3. Register in the registry

The manual deployment script creates the contract, but you will need to do the additional configuration manually or use the Hyperlane CLI to configure the routers.
