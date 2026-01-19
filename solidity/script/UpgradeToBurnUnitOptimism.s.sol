// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity >=0.8.0;

import "forge-std/Script.sol";
import {HypERC20} from "../contracts/token/HypERC20.sol";
import {HypERC20BurnUnit} from "../contracts/token/HypERC20BurnUnit.sol";
import {ProxyAdmin} from "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";
import {ITransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

/**
 * @title UpgradeToBurnUnitOptimism
 * @notice Script para fazer upgrade do HypERC20 (queima percentual 0.01%) 
 *         para HypERC20BurnUnit (queima fixa de 0.01 token por transação)
 */
contract UpgradeToBurnUnitOptimism is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);
        
        // Endereço do token deployado (Proxy)
        address tokenProxyAddress = 0x7d637C37828c01ad6241624FfAAd7B48eb3cc516;
        
        // Endereço do ProxyAdmin do contrato
        address proxyAdminAddress = 0x3f7EFCC5069BaC444558CbF8280F2419C84dd847;
        
        vm.startBroadcast(deployerPrivateKey);
        
        HypERC20 oldToken = HypERC20(tokenProxyAddress);
        ProxyAdmin proxyAdmin = ProxyAdmin(proxyAdminAddress);
        
        // Verificar se o caller é o owner do ProxyAdmin (pode fazer upgrade)
        require(proxyAdmin.owner() == deployer, "Apenas o owner do ProxyAdmin pode fazer upgrade");
        
        console.log("=== Informacoes do Token Atual ===");
        console.log("Endereco do token (Proxy):", tokenProxyAddress);
        console.log("Endereco do ProxyAdmin:", proxyAdminAddress);
        console.log("Owner do ProxyAdmin:", proxyAdmin.owner());
        console.log("Owner do token:", oldToken.owner());
        console.log("Nome do token:", oldToken.name());
        console.log("Simbolo do token:", oldToken.symbol());
        console.log("Decimals:", oldToken.decimals());
        console.log("Total supply atual:", oldToken.totalSupply());
        
        // Obter configurações do contrato atual
        address mailbox = address(oldToken.mailbox());
        uint8 decimals = oldToken.decimals();
        
        console.log("\n=== Passo 1: Deploy da Nova Implementation (HypERC20BurnUnit) ===");
        console.log("A nova implementacao tera queima fixa de 0.01 token por transacao");
        console.log("(ao inves de 0.01% percentual)");
        
        // Deploy da nova implementation com queima fixa
        HypERC20BurnUnit newImplementation = new HypERC20BurnUnit(decimals, 1, mailbox);
        console.log("Nova implementation HypERC20BurnUnit deployada em:", address(newImplementation));
        console.log("Burn fee unit (0.01 token):", newImplementation.burnFeeUnit());
        
        console.log("\n=== Passo 2: Upgrade do Proxy ===");
        console.log("Atualizando proxy de HypERC20 para HypERC20BurnUnit...");
        
        ITransparentUpgradeableProxy proxy = ITransparentUpgradeableProxy(tokenProxyAddress);
        proxyAdmin.upgrade(proxy, address(newImplementation));
        console.log("Proxy atualizado com sucesso!");
        
        console.log("\n=== Passo 3: Verificacao do Upgrade ===");
        
        // Verificar que o upgrade foi bem-sucedido
        HypERC20BurnUnit newToken = HypERC20BurnUnit(tokenProxyAddress);
        
        // Verificar que as informações básicas foram preservadas
        require(
            keccak256(bytes(newToken.name())) == keccak256(bytes(oldToken.name())),
            "Nome do token nao corresponde"
        );
        require(
            keccak256(bytes(newToken.symbol())) == keccak256(bytes(oldToken.symbol())),
            "Simbolo do token nao corresponde"
        );
        require(newToken.decimals() == oldToken.decimals(), "Decimals nao correspondem");
        require(newToken.totalSupply() == oldToken.totalSupply(), "Supply nao corresponde");
        require(address(newToken.mailbox()) == mailbox, "Mailbox nao corresponde");
        
        // Verificar que a nova implementação tem a função burnFeeUnit
        uint256 burnFeeUnit = newToken.burnFeeUnit();
        console.log("Burn fee unit verificado:", burnFeeUnit);
        console.log("Para 6 decimals, 0.01 token = 10000 (em wei)");
        
        console.log("\n=== Verificacao Final ===");
        console.log("Nome:", newToken.name());
        console.log("Simbolo:", newToken.symbol());
        console.log("Decimals:", newToken.decimals());
        console.log("Total supply:", newToken.totalSupply());
        console.log("Burn fee unit (0.01 token):", burnFeeUnit);
        console.log("Owner:", newToken.owner());
        
        vm.stopBroadcast();
        
        console.log("\n=== Upgrade Concluido com Sucesso! ===");
        console.log("O contrato agora usa queima fixa de 0.01 token por transacao");
        console.log("(ao inves de 0.01% percentual)");
        console.log("\nIMPORTANTE: Todas as transferencias locais agora queimarao");
        console.log("exatamente 0.01 token, independente do valor transferido.");
    }
}
