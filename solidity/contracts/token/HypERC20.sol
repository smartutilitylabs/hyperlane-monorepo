// SPDX-License-Identifier: Apache-2.0
pragma solidity >=0.8.0;

import {TokenRouter} from "./libs/TokenRouter.sol";
import {Quote} from "../interfaces/ITokenBridge.sol";
import {TokenRouter} from "./libs/TokenRouter.sol";

import {ERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";

/**
 * @title Hyperlane ERC20 Token Router that extends ERC20 with remote transfer functionality.
 * @author Abacus Works
 * @dev Supply on each chain is not constant but the aggregate supply across all chains is.
 */
contract HypERC20 is ERC20Upgradeable, TokenRouter {
    uint8 private immutable _decimals;
    
    // Burn fee of 0.01% (1/10000)
    uint256 private constant BURN_RATE = 10000;
    
    /**
     * @dev Emitted when a burn fee is applied on a local transfer.
     * @param from The address sending the tokens
     * @param to The address receiving the tokens
     * @param totalAmount The total amount being transferred
     * @param burnAmount The amount burned (0.01% of totalAmount)
     * @param transferAmount The amount actually transferred after burn
     */
    event BurnFeeApplied(
        address indexed from,
        address indexed to,
        uint256 totalAmount,
        uint256 burnAmount,
        uint256 transferAmount
    );

    constructor(
        uint8 __decimals,
        uint256 _scale,
        address _mailbox
    ) TokenRouter(_scale, _mailbox) {
        _decimals = __decimals;
    }

    /**
     * @notice Initializes the Hyperlane router, ERC20 metadata, and mints initial supply to deployer.
     * @param _totalSupply The initial supply of the token.
     * @param _name The name of the token.
     * @param _symbol The symbol of the token.
     */
    function initialize(
        uint256 _totalSupply,
        string memory _name,
        string memory _symbol,
        address _hook,
        address _interchainSecurityModule,
        address _owner
    ) public initializer {
        // Initialize ERC20 metadata
        __ERC20_init(_name, _symbol);
        _mint(msg.sender, _totalSupply);
        _MailboxClient_initialize(_hook, _interchainSecurityModule, _owner);
    }

    function decimals() public view override returns (uint8) {
        return _decimals;
    }

    // ============ TokenRouter overrides ============

    /**
     * @inheritdoc TokenRouter
     */
    function token() public view override returns (address) {
        return address(this);
    }

    /**
     * @inheritdoc TokenRouter
     * @dev Overrides to burn `_amount` of token from `msg.sender` balance.
     * @dev Known overrides:
     * - HypERC4626: Converts the amount to shares and burns from the User (via HypERC20 implementation)
     */
    // solhint-disable-next-line hyperlane/no-virtual-override
    function _transferFromSender(uint256 _amount) internal virtual override {
        _burn(msg.sender, _amount);
    }

    /**
     * @inheritdoc TokenRouter
     * @dev Overrides to mint `_amount` of token to `_recipient` balance.
     */
    function _transferTo(
        address _recipient,
        uint256 _amount
    ) internal override {
        _mint(_recipient, _amount);
    }
    
    /**
     * @dev Overrides ERC20 transfer to apply 0.01% burn fee on local transfers.
     * @dev Burn is only applied on local transfers (same blockchain).
     * @dev Cross-chain transfers are not affected as they use _mint via _transferTo.
     */
    function transfer(
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address owner = msg.sender;
        // Calculate burn fee: 0.01% = amount / 10000
        uint256 burnAmount = amount / BURN_RATE;
        uint256 transferAmount = amount - burnAmount;
        
        if (burnAmount > 0) {
            // Burn tokens from sender
            _burn(owner, burnAmount);
            // Transfer remaining amount after burn using base implementation
            super._transfer(owner, to, transferAmount);
            // Emit event informing about burn fee
            emit BurnFeeApplied(owner, to, amount, burnAmount, transferAmount);
        } else {
            // If burnAmount is 0, transfer normally using base implementation
            super._transfer(owner, to, amount);
        }
        
        return true;
    }
    
    /**
     * @dev Overrides ERC20 transferFrom to apply 0.01% burn fee on local transfers.
     * @dev Burn is only applied on local transfers (same blockchain).
     * @dev Cross-chain transfers are not affected as they use _mint via _transferTo.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        // Calculate burn fee: 0.01% = amount / 10000
        uint256 burnAmount = amount / BURN_RATE;
        
        if (burnAmount > 0) {
            address spender = msg.sender;
            // IMPORTANT: Spend allowance of TOTAL (amount), not just transferAmount
            // If we used super.transferFrom(from, to, transferAmount), it would spend wrong allowance
            _spendAllowance(from, spender, amount);
            
            uint256 transferAmount = amount - burnAmount;
            // Burn tokens from sender
            _burn(from, burnAmount);
            // Transfer remaining amount after burn using base implementation
            super._transfer(from, to, transferAmount);
            // Emit event informing about burn fee
            emit BurnFeeApplied(from, to, amount, burnAmount, transferAmount);
        } else {
            // If burnAmount is 0, use default base implementation
            return super.transferFrom(from, to, amount);
        }
        
        return true;
    }
}
