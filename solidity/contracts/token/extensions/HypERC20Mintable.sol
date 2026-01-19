// SPDX-License-Identifier: Apache-2.0
pragma solidity >=0.8.0;

import {HypERC20} from "../HypERC20.sol";

/**
 * @title HypERC20Mintable
 * @dev Extensão do HypERC20 que adiciona função pública de mint
 * @notice Permite ao owner fazer mint de tokens adicionais
 * @dev Este contrato pode ser usado como upgrade do HypERC20 existente
 */
contract HypERC20Mintable is HypERC20 {
    constructor(
        uint8 __decimals,
        uint256 _scale,
        address _mailbox
    ) HypERC20(__decimals, _scale, _mailbox) {}
    
    /**
     * @notice Minta tokens adicionais para um endereço
     * @dev Apenas o owner pode chamar esta função (herdado de MailboxClient -> OwnableUpgradeable)
     * @param _to Endereço que receberá os tokens
     * @param _amount Quantidade de tokens a mintar
     */
    function mint(address _to, uint256 _amount) external onlyOwner {
        _mint(_to, _amount);
    }
}
