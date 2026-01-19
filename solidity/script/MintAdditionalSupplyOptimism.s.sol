// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity >=0.8.0;

import "forge-std/Script.sol";
import {HypERC20} from "../contracts/token/HypERC20.sol";
import {HypERC20Mintable} from "../contracts/token/extensions/HypERC20Mintable.sol";
import {ProxyAdmin} from "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";
import {ITransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

contract MintAdditionalSupplyOptimism is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);
        
        // Endereço do token deployado (Proxy) - NOVO CONTRATO
        address tokenProxyAddress = 0x7d637C37828c01ad6241624FfAAd7B48eb3cc516;
        
        // Endereço do ProxyAdmin do novo contrato
        // ProxyAdmin é o contrato que controla upgrades do proxy
        // Ele foi deployado junto com o token e permite fazer upgrades da implementação
        // O owner do ProxyAdmin pode fazer upgrade do contrato para adicionar novas funções
        address proxyAdminAddress = 0x3f7EFCC5069BaC444558CbF8280F2419C84dd847;
        
        // Owner do contrato
        address owner = 0x6d7fFa706F4898f87083255a44eEC503ED02Ab78;
        
        // Quantidade atual: 15,000,000,000 (15 bilhões)
        // Quantidade desejada: 150,000,000,000 (150 bilhões)
        // Quantidade adicional a mintar: 135,000,000,000 (135 bilhões)
        uint256 additionalSupply = 135000000000;
        
        vm.startBroadcast(deployerPrivateKey);
        
        HypERC20 token = HypERC20(tokenProxyAddress);
        
        // Verificar supply atual
        uint256 currentSupply = token.totalSupply();
        console.log("=== Informacoes do Token ===");
        console.log("Supply atual:", currentSupply);
        console.log("Quantidade adicional a mintar:", additionalSupply);
        console.log("Supply final esperado:", currentSupply + additionalSupply);
        
        // Verificar se o caller é o owner do ProxyAdmin (pode fazer upgrade)
        ProxyAdmin proxyAdmin = ProxyAdmin(proxyAdminAddress);
        require(proxyAdmin.owner() == deployer, "Apenas o owner do ProxyAdmin pode fazer upgrade");
        
        address contractOwner = token.owner();
        console.log("Owner do token:", contractOwner);
        console.log("Caller:", deployer);
        
        console.log("=== Passo 1: Deploy da Nova Implementation (com funcao mint) ===");
        
        // Obter configurações do contrato atual
        address mailbox = address(token.mailbox());
        uint8 decimals = token.decimals();
        
        // Deploy da nova implementation com função de mint
        HypERC20Mintable newImplementation = new HypERC20Mintable(decimals, 1, mailbox);
        console.log("Nova implementation deployada em:", address(newImplementation));
        
        console.log("=== Passo 2: Upgrade do Proxy ===");
        ITransparentUpgradeableProxy proxy = ITransparentUpgradeableProxy(tokenProxyAddress);
        proxyAdmin.upgrade(proxy, address(newImplementation));
        console.log("Proxy atualizado");
        
        console.log("=== Passo 3: Mint de Tokens Adicionais ===");
        HypERC20Mintable mintableToken = HypERC20Mintable(tokenProxyAddress);
        
        if (contractOwner == deployer) {
            mintableToken.mint(owner, additionalSupply);
            console.log("Tokens mintados");
        } else {
            console.log("AVISO: Deployer nao e owner do token");
            console.log("Owner:", contractOwner);
            revert("Mint precisa ser feito pelo owner");
        }
        
        console.log("Tokens mintados com sucesso!");
        
        // Verificar novo supply
        uint256 newSupply = mintableToken.totalSupply();
        uint256 ownerBalance = mintableToken.balanceOf(owner);
        
        console.log("=== Verificacao Final ===");
        console.log("Novo supply total:", newSupply);
        console.log("Balance do owner:", ownerBalance);
        require(newSupply == currentSupply + additionalSupply, "Supply nao corresponde ao esperado");
        
        vm.stopBroadcast();
        
        console.log("Processo concluido com sucesso!");
        console.log("Supply aumentado de", currentSupply, "para", newSupply);
    }
}
