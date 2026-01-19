// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity >=0.8.0;

import "forge-std/Script.sol";
import {HypERC20BurnUnit} from "../contracts/token/HypERC20BurnUnit.sol";
import {ProxyAdmin} from "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";
import {TransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

contract DeployHypERC20OptimismBurnUnit is Script {
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
        
        // 2. Deploy HypERC20BurnUnit Implementation (com funcionalidade de queima fixa de 0.01 token)
        console.log("Deploying HypERC20BurnUnit implementation with fixed unit burn (0.01 token per transaction)...");
        HypERC20BurnUnit implementation = new HypERC20BurnUnit(decimals, scale, mailbox);
        console.log("HypERC20BurnUnit implementation deployed at:", address(implementation));
        
        // 3. Preparar dados de inicialização
        bytes memory initData = abi.encodeWithSelector(
            HypERC20BurnUnit.initialize.selector,
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
        HypERC20BurnUnit token = HypERC20BurnUnit(address(proxy));
        console.log("Token name:", token.name());
        console.log("Token symbol:", token.symbol());
        console.log("Token decimals:", token.decimals());
        console.log("Total supply:", token.totalSupply());
        console.log("Owner balance:", token.balanceOf(owner));
        console.log("Burn fee unit (0.01 token):", token.burnFeeUnit());
        
        vm.stopBroadcast();
        
        console.log("\n=== Deployment Summary ===");
        console.log("ProxyAdmin:", address(proxyAdmin));
        console.log("Implementation:", address(implementation));
        console.log("Proxy (Token Address):", address(proxy));
        console.log("Owner:", owner);
        console.log("Initial Supply:", initialSupply);
        console.log("Burn Fee: Fixed 0.01 token per transaction (not percentage)");
        console.log("\nDeployment complete!");
        console.log("IMPORTANTE: Este contrato tem funcionalidade de queima fixa de 0.01 token por transacao!");
    }
}
