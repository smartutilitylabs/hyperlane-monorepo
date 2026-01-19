// SPDX-License-Identifier: Apache-2.0
pragma solidity >=0.8.0;

import {TokenRouter} from "./libs/TokenRouter.sol";
import {Quote} from "../interfaces/ITokenBridge.sol";
import {TokenRouter} from "./libs/TokenRouter.sol";

import {ERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";

/**
 * @title Hyperlane ERC20 Token Router with Fixed Unit Burn Fee
 * @author Abacus Works
 * @dev Supply on each chain is not constant but the aggregate supply across all chains is.
 * @dev This version applies a fixed burn fee of 0.01 token per transaction (not percentage-based).
 */
contract HypERC20BurnUnit is ERC20Upgradeable, TokenRouter {
    uint8 private immutable _decimals;
    
    // Fixed burn fee of 0.01 token per transaction
    // For 6 decimals: 0.01 * 10^6 = 10000
    // For 18 decimals: 0.01 * 10^18 = 10000000000000000
    uint256 private immutable BURN_FEE_UNIT;
    
    /**
     * @dev Emitted when a burn fee is applied on a local transfer.
     * @param from The address sending the tokens
     * @param to The address receiving the tokens
     * @param totalAmount The total amount being transferred
     * @param burnAmount The amount burned (fixed 0.01 token)
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
        // Calculate fixed burn fee: 0.01 token = 0.01 * 10^decimals
        // Formula: 0.01 = 1/100 = 10^-2, so 0.01 * 10^decimals = 10^(decimals-2)
        // Example: for 6 decimals, 10^(6-2) = 10^4 = 10000
        // Example: for 18 decimals, 10^(18-2) = 10^16 = 10000000000000000
        BURN_FEE_UNIT = 10 ** (__decimals - 2); // 0.01 token in wei
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

    /**
     * @notice Returns the fixed burn fee amount (0.01 token).
     * @return The burn fee amount in token units.
     */
    function burnFeeUnit() public view returns (uint256) {
        return BURN_FEE_UNIT;
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
     * @dev Overrides ERC20 transfer to apply fixed 0.01 token burn fee on local transfers.
     * @dev Burn is only applied on local transfers (same blockchain).
     * @dev Cross-chain transfers are not affected as they use _mint via _transferTo.
     * @dev The burn fee is fixed at 0.01 token per transaction, regardless of transfer amount.
     */
    function transfer(
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address owner = msg.sender;
        
        // Apply fixed burn fee of 0.01 token
        // Only burn if amount is greater than burn fee
        if (amount > BURN_FEE_UNIT) {
            uint256 transferAmount = amount - BURN_FEE_UNIT;
            
            // Burn fixed amount from sender
            _burn(owner, BURN_FEE_UNIT);
            // Transfer remaining amount after burn using base implementation
            super._transfer(owner, to, transferAmount);
            // Emit event informing about burn fee
            emit BurnFeeApplied(owner, to, amount, BURN_FEE_UNIT, transferAmount);
        } else {
            // If amount is less than or equal to burn fee, transfer normally without burn
            // This prevents burning more than the transfer amount
            super._transfer(owner, to, amount);
        }
        
        return true;
    }
    
    /**
     * @dev Overrides ERC20 transferFrom to apply fixed 0.01 token burn fee on local transfers.
     * @dev Burn is only applied on local transfers (same blockchain).
     * @dev Cross-chain transfers are not affected as they use _mint via _transferTo.
     * @dev The burn fee is fixed at 0.01 token per transaction, regardless of transfer amount.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        
        // Apply fixed burn fee of 0.01 token
        // Only burn if amount is greater than burn fee
        if (amount > BURN_FEE_UNIT) {
            address spender = msg.sender;
            // IMPORTANT: Spend allowance of TOTAL (amount), not just transferAmount
            // If we used super.transferFrom(from, to, transferAmount), it would spend wrong allowance
            _spendAllowance(from, spender, amount);
            
            uint256 transferAmount = amount - BURN_FEE_UNIT;
            // Burn fixed amount from sender
            _burn(from, BURN_FEE_UNIT);
            // Transfer remaining amount after burn using base implementation
            super._transfer(from, to, transferAmount);
            // Emit event informing about burn fee
            emit BurnFeeApplied(from, to, amount, BURN_FEE_UNIT, transferAmount);
        } else {
            // If amount is less than or equal to burn fee, transfer normally without burn
            // This prevents burning more than the transfer amount
            return super.transferFrom(from, to, amount);
        }
        
        return true;
    }
}
