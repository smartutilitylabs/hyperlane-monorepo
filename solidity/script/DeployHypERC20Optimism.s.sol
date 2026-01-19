// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity >=0.8.0;

import "forge-std/Script.sol";
import {HypERC20} from "../contracts/token/HypERC20.sol";
import {ProxyAdmin} from "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";
import {TransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

contract DeployHypERC20Optimism is Script {
    function run() external {
        // Configurações da Optimism Mainnet
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);
        
        // Parâmetros do token
        uint8 decimals = 6;
        uint256 scale = 1;
        address mailbox = 0xd4C1905BB1D26BC93DAC913e13CaCC278CdCC80D; // Optimism Mainnet Mailbox
        address owner = 0x6d7fFa706F4898f87083255a44eEC503ED02Ab78;
        address hook = address(0); // Config Hook vazio
        address ism = 0x38164E63A4F67b32b2EfF4b45aCC1f2EE9b77b07; // Optimism Mainnet ISM padrão
        uint256 initialSupply = 15000000000;
        string memory name = "upusd";
        string memory symbol = "upusd";
        
        vm.startBroadcast(deployerPrivateKey);
        
        // 1. Deploy ProxyAdmin
        console.log("Deploying ProxyAdmin...");
        ProxyAdmin proxyAdmin = new ProxyAdmin();
        console.log("ProxyAdmin deployed at:", address(proxyAdmin));
        
        // 2. Deploy HypERC20 Implementation (com funcionalidade de queima)
        console.log("Deploying HypERC20 implementation with burn functionality...");
        HypERC20 implementation = new HypERC20(decimals, scale, mailbox);
        console.log("HypERC20 implementation deployed at:", address(implementation));
        
        // 3. Preparar dados de inicialização
        bytes memory initData = abi.encodeWithSelector(
            HypERC20.initialize.selector,
            initialSupply,
            name,
            symbol,
            hook,
            ism,
            owner
        );
        
        // 4. Deploy TransparentUpgradeableProxy
        console.log("Deploying TransparentUpgradeableProxy...");
        TransparentUpgradeableProxy proxy = new TransparentUpgradeableProxy(
            address(implementation),
            address(proxyAdmin),
            initData
        );
        console.log("Proxy deployed at:", address(proxy));
        
        // 5. Verificar inicialização
        HypERC20 token = HypERC20(address(proxy));
        console.log("Token name:", token.name());
        console.log("Token symbol:", token.symbol());
        console.log("Token decimals:", token.decimals());
        console.log("Total supply:", token.totalSupply());
        console.log("Owner balance:", token.balanceOf(owner));
        
        vm.stopBroadcast();
        
        console.log("\n=== Deployment Summary ===");
        console.log("ProxyAdmin:", address(proxyAdmin));
        console.log("Implementation:", address(implementation));
        console.log("Proxy (Token Address):", address(proxy));
        console.log("Owner:", owner);
        console.log("Initial Supply:", initialSupply);
        console.log("\nDeployment complete!");
        console.log("IMPORTANTE: Este contrato tem funcionalidade de queima (0.01%) implementada!");
    }
}
