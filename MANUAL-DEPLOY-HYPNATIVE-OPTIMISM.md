# Guide: Manual Deployment of HypNative (Native Token Router) on Optimism

This guide explains how to manually deploy the HypNative contract on Optimism using Foundry. HypNative allows you to wrap the native ETH token and enable cross-chain transfers via Hyperlane.

## 📋 What is HypNative?

**HypNative** is a Hyperlane token router that wraps the native blockchain token (ETH on Optimism) and enables cross-chain transfers. Unlike synthetic tokens (HypERC20), HypNative uses the actual native token as collateral, allowing users to:

- Deposit native ETH to receive wrapped tokens
- Transfer wrapped tokens across chains
- Withdraw native ETH from the wrapped tokens

## ⚠️ Key Differences from HypERC20

- **HypERC20**: Creates synthetic tokens (mintable/burnable)
- **HypNative**: Wraps existing native tokens (ETH) as collateral
- **HypERC20Collateral**: Wraps existing ERC20 tokens as collateral

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

3. **Sufficient ETH balance**: You need ETH for:
   - Gas fees for deployment
   - Initial collateral deposit (optional but recommended)

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

### Step 2: Create Deployment Script

Create a deployment script `script/DeployHypNative.s.sol`:

```solidity
// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity >=0.8.0;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import {HypNative} from "../contracts/token/HypNative.sol";
import {ProxyAdmin} from "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";
import {TransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

contract DeployHypNative is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);
        
        // Optimism Mainnet Configuration
        uint256 scale = 1; // Scale factor (usually 1 for 1:1 ratio)
        address mailbox = 0xd4C1905BB1D26BC93DAC913e13CaCC278CdCC80D; // Optimism Mailbox
        address owner = deployer; // Or set to your desired owner address
        address hook = address(0); // Post-dispatch hook (usually address(0))
        address ism = address(0); // ISM address (will be set during initialization)
        
        vm.startBroadcast(deployerPrivateKey);
        
        console.log("=== Deploying HypNative on Optimism ===");
        console.log("Deployer:", deployer);
        console.log("Mailbox:", mailbox);
        console.log("Scale:", scale);
        
        // 1. Deploy ProxyAdmin
        console.log("\n1. Deploying ProxyAdmin...");
        ProxyAdmin proxyAdmin = new ProxyAdmin();
        console.log("ProxyAdmin deployed at:", address(proxyAdmin));
        
        // 2. Deploy HypNative Implementation
        console.log("\n2. Deploying HypNative implementation...");
        HypNative implementation = new HypNative(scale, mailbox);
        console.log("HypNative implementation deployed at:", address(implementation));
        
        // 3. Prepare initialization data
        // HypNative.initialize(hook, interchainSecurityModule, owner)
        bytes memory initData = abi.encodeWithSelector(
            HypNative.initialize.selector,
            hook,
            ism, // Can be set later via updateInterchainSecurityModule
            owner
        );
        
        // 4. Deploy TransparentUpgradeableProxy
        console.log("\n3. Deploying TransparentUpgradeableProxy...");
        TransparentUpgradeableProxy proxy = new TransparentUpgradeableProxy(
            address(implementation),
            address(proxyAdmin),
            initData
        );
        console.log("Proxy deployed at:", address(proxy));
        
        // 5. Verify deployment
        HypNative hypNative = HypNative(payable(address(proxy)));
        console.log("\n4. Verifying deployment...");
        console.log("Contract token address (should be address(0) for native):", hypNative.token());
        console.log("Mailbox:", hypNative.mailbox());
        
        vm.stopBroadcast();
        
        console.log("\n=== Deployment Summary ===");
        console.log("ProxyAdmin:", address(proxyAdmin));
        console.log("Implementation:", address(implementation));
        console.log("Proxy (HypNative Address):", address(proxy));
        console.log("Owner:", owner);
        console.log("Mailbox:", mailbox);
        console.log("\n✅ Deployment complete!");
        console.log("\n⚠️  NEXT STEPS:");
        console.log("1. Set ISM using: setInterchainSecurityModule(address)");
        console.log("2. Configure remote routers using Hyperlane CLI");
        console.log("3. Deposit native ETH using: deposit(address receiver)");
    }
}
```

### Step 3: Execute Deployment Script

```bash
# Deploy HypNative on Optimism
forge script script/DeployHypNative.s.sol:DeployHypNative \
  --rpc-url $RPC_URL \
  --broadcast \
  --verify \
  --etherscan-api-key GP69JEAP2W7YFJT9ZJTEPGQT6Y6KMW44ZN \
  --legacy \
  -vvvv
```

**Note**: Make sure you have:
- Sufficient ETH on Optimism for gas fees (recommended: at least 0.1 ETH)
- Etherscan API key for verification (optional but recommended)
- Correct RPC URL pointing to Optimism mainnet

### Step 4: Configure Interchain Security Module (ISM)

After deployment, you need to set the ISM. You can do this using Foundry cast or a script:

```solidity
// Set ISM script (add to your deployment script or create separate)
HypNative hypNative = HypNative(payable(YOUR_DEPLOYED_ADDRESS));

// Build ISM configuration (MessageIdMultisig ISM)
// Note: You'll need to deploy or find the ISM address first
address ismAddress = 0x...; // Your ISM address

hypNative.setInterchainSecurityModule(ismAddress);
```

Or using cast:

```bash
cast send YOUR_HYPNATIVE_ADDRESS \
  "setInterchainSecurityModule(address)" \
  0xYOUR_ISM_ADDRESS \
  --rpc-url https://mainnet.optimism.io \
  --private-key $PRIVATE_KEY
```

### Step 5: Configure in Hyperlane

After deployment, configure the warp route:

#### Configuration File (warp-route-deployment.yaml)

```yaml
optimism:
  type: native
  name: "Wrapped Optimism ETH"
  symbol: "wETH-OP"
  decimals: 18
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
  foreignDeployment: "0xYOUR_DEPLOYED_HYPNATIVE_ADDRESS"  # Use your deployed contract
```

**Recommended Threshold**: For 6 validators, use threshold 4 (majority) for security.

### Step 6: Initial Deposit (Optional but Recommended)

To make the token usable, deposit some native ETH:

```bash
# Deposit ETH to HypNative
cast send YOUR_HYPNATIVE_ADDRESS \
  "deposit(address)" \
  YOUR_RECEIVER_ADDRESS \
  --value 1ether \
  --rpc-url https://mainnet.optimism.io \
  --private-key $PRIVATE_KEY
```

Or using a script:

```solidity
HypNative hypNative = HypNative(payable(YOUR_HYPNATIVE_ADDRESS));
hypNative.deposit{value: 1 ether}(YOUR_RECEIVER_ADDRESS);
```

### Step 7: Verify Deployment

1. **Check contract on Optimism Explorer**:
   ```
   https://optimistic.etherscan.io/address/YOUR_HYPNATIVE_ADDRESS
   ```

2. **Verify the contract code**:
   ```bash
   forge verify-contract \
     YOUR_HYPNATIVE_ADDRESS \
     contracts/token/HypNative.sol:HypNative \
     --chain-id 10 \
     --etherscan-api-key GP69JEAP2W7YFJT9ZJTEPGQT6Y6KMW44ZN \
     --constructor-args $(cast abi-encode "constructor(uint256,address)" 1 0xd4C1905BB1D26BC93DAC913e13CaCC278CdCC80D)
   ```

3. **Verify token() returns address(0)**:
   ```bash
   cast call YOUR_HYPNATIVE_ADDRESS \
     "token()" \
     --rpc-url https://mainnet.optimism.io
   ```
   Should return: `0x0000000000000000000000000000000000000000`

4. **Check mailbox**:
   ```bash
   cast call YOUR_HYPNATIVE_ADDRESS \
     "mailbox()" \
     --rpc-url https://mainnet.optimism.io
   ```
   Should return the Optimism mailbox address.

### Step 8: Connect to Other Chains

After deployment, you need to:

1. **Register the contract in the Hyperlane registry**
2. **Configure remote routers** - Connect to other chains in your warp route
3. **Enroll remote routers** - Connect to routers on destination chains
4. **Set destination gas** - Configure gas for cross-chain messages

## Usage Examples

### Deposit Native ETH

```solidity
// Deposit 1 ETH and receive wrapped tokens
HypNative hypNative = HypNative(payable(YOUR_HYPNATIVE_ADDRESS));
uint256 shares = hypNative.deposit{value: 1 ether}(msg.sender);
```

### Transfer Cross-Chain

```solidity
// Transfer wrapped tokens to another chain
uint32 destinationDomain = 1; // Ethereum mainnet domain ID
bytes32 recipient = addressToBytes32(0x...); // Recipient address on destination

hypNative.transferRemote(destinationDomain, recipient, amount);
```

### Withdraw Native ETH

```solidity
// Withdraw native ETH by redeeming wrapped tokens
hypNative.redeem(shares, msg.sender, msg.sender);
```

## ⚠️ IMPORTANT

1. **Collateral Management**: HypNative uses native ETH as collateral. Ensure sufficient ETH is available for cross-chain transfers.

2. **Rebalancing**: You may need to rebalance collateral across chains to ensure sufficient funds for withdrawals.

3. **Security**: Always verify the ISM configuration before enabling cross-chain transfers.

4. **Gas Configuration**: Set appropriate destination gas amounts for each chain you connect to.

5. **Proxy Admin**: Keep the ProxyAdmin private key secure - it controls upgrades to the contract.

## Troubleshooting

### Common Issues

1. **Insufficient ETH for Gas**: Ensure you have enough ETH on Optimism for deployment and operations
2. **RPC Connection**: If the primary RPC fails, try the backup URLs listed above
3. **Verification Issues**: Make sure your Etherscan API key has access to Optimism network
4. **ISM Not Set**: You must set the ISM before the contract can process cross-chain messages
5. **No Collateral**: Deposit native ETH before attempting transfers

### Useful Commands

```bash
# Check balance on Optimism
cast balance YOUR_ADDRESS --rpc-url https://mainnet.optimism.io

# Check contract code
cast code YOUR_HYPNATIVE_ADDRESS --rpc-url https://mainnet.optimism.io

# Check contract balance (native ETH in contract)
cast balance YOUR_HYPNATIVE_ADDRESS --rpc-url https://mainnet.optimism.io

# Get total assets (total ETH collateral)
cast call YOUR_HYPNATIVE_ADDRESS \
  "totalAssets()" \
  --rpc-url https://mainnet.optimism.io

# Get total supply (wrapped tokens)
cast call YOUR_HYPNATIVE_ADDRESS \
  "totalSupply()" \
  --rpc-url https://mainnet.optimism.io

# Deposit ETH (example)
cast send YOUR_HYPNATIVE_ADDRESS \
  "deposit(address)" \
  YOUR_RECEIVER_ADDRESS \
  --value 1ether \
  --rpc-url https://mainnet.optimism.io \
  --private-key $PRIVATE_KEY
```

## Key Contract Methods

### HypNative Contract Interface

- `deposit(address receiver) payable` - Deposit native ETH and receive wrapped tokens
- `redeem(uint256 shares, address receiver, address owner)` - Redeem wrapped tokens for native ETH
- `transferRemote(uint32 destination, bytes32 recipient, uint256 amount)` - Transfer cross-chain
- `setInterchainSecurityModule(address)` - Set the ISM address
- `enrollRemoteRouter(uint32 domain, bytes32 router)` - Enroll a remote router
- `setDestinationGas(uint32 destination, uint256 gas)` - Set gas for destination chain
- `token()` - Returns address(0) for native tokens

## Resources

- **Optimism Explorer**: https://optimistic.etherscan.io
- **OP Mainnet Explorer**: https://optimism.blockscout.com
- **Hyperlane Docs**: https://docs.hyperlane.xyz
- **Optimism Docs**: https://docs.optimism.io
- **Foundry Book**: https://book.getfoundry.sh

## Notes

- HypNative is an ERC4626 vault, meaning it follows the vault standard for tokenized deposits
- The `scale` parameter is usually `1` for a 1:1 ratio between native ETH and wrapped tokens
- Native token transfers on Optimism are very fast and cheap compared to Ethereum mainnet
- Always test on testnet first before deploying to mainnet
