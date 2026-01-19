// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity >=0.8.0;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import {HypNative} from "../contracts/token/HypNative.sol";
import {ProxyAdmin} from "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";
import {TransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

contract DeployHypNativeOptimism is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);
        
        // Optimism Mainnet Configuration
        uint256 scale = 1; // Scale factor (1:1 ratio)
        address mailbox = 0xd4C1905BB1D26BC93DAC913e13CaCC278CdCC80D; // Optimism Mailbox
        address owner = 0x6d7fFa706F4898f87083255a44eEC503ED02Ab78; // Owner from config
        address hook = address(0); // Post-dispatch hook (set to zero for now)
        address ism = address(0); // ISM will be set after deployment (0x38164E63A4F67b32b2EfF4b45aCC1f2EE9b77b07)
        
        vm.startBroadcast(deployerPrivateKey);
        
        console.log("=== Deploying HypNative on Optimism ===");
        console.log("Deployer:", deployer);
        console.log("Mailbox:", mailbox);
        console.log("Scale:", scale);
        console.log("Owner:", owner);
        
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
            ism, // Can be set later via setInterchainSecurityModule
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
        // Verify token() returns address(0) for native tokens
        address tokenAddr = hypNative.token();
        address mailboxAddr = address(hypNative.mailbox());
        require(tokenAddr == address(0), "Token address should be address(0) for native");
        require(mailboxAddr == mailbox, "Mailbox mismatch");
        console.log("Verification passed: token is native (address(0)), mailbox matches");
        
        vm.stopBroadcast();
        
        console.log("\n=== Deployment Summary ===");
        console.log("ProxyAdmin:", address(proxyAdmin));
        console.log("Implementation:", address(implementation));
        console.log("Proxy (HypNative Address):", address(proxy));
        console.log("Owner:", owner);
        console.log("Mailbox:", mailbox);
        console.log("\n[SUCCESS] Deployment complete!");
        console.log("\n[NEXT STEPS]:");
        console.log("1. Set ISM using: setInterchainSecurityModule(address)");
        console.log("2. Configure remote routers using Hyperlane CLI");
        console.log("3. Deposit native ETH using: deposit(address receiver) payable");
    }
}
