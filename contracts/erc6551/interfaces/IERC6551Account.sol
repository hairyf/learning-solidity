// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title IERC6551AccountProxy
 * @dev Interface for the ERC6551 Account Proxy
 *
 * This interface defines the function to get the implementation address
 * of a proxy contract used in the ERC6551 token bound accounts system.
 */
interface IERC6551AccountProxy {
    /**
     * @dev Returns the implementation address for this proxy
     * @return The address of the implementation contract
     */
    function implementation() external view returns (address);
}

/**
 * @title IERC6551Account
 * @dev Interface for ERC6551 token bound accounts
 *
 * This interface defines the standard functions that any ERC6551 compliant
 * account must implement. ERC6551 accounts are smart contract accounts that
 * are owned by and bound to specific NFTs.
 */
/// @dev the ERC-165 identifier for this interface is `0xeff4d378`
interface IERC6551Account {
    /**
     * @dev Emitted when a transaction is executed through this account
     * @param target The address the transaction was sent to
     * @param value The amount of native token sent with the transaction
     * @param data The calldata sent with the transaction
     */
    event TransactionExecuted(
        address indexed target,
        uint256 indexed value,
        bytes data
    );

    /**
     * @dev Executes a transaction from this account
     * @param to The target address for the transaction
     * @param value The amount of native token to send
     * @param data The calldata to send
     * @return The bytes returned from the transaction execution
     */
    function execute(address to, uint256 value, bytes calldata data) external payable returns (bytes memory);

    /**
     * @dev Returns information about the token that owns this account
     * @return chainId The chain ID where the token exists
     * @return tokenContract The address of the token contract
     * @return tokenId The ID of the token
     */
    function token() external view returns (uint256 chainId, address tokenContract, uint256 tokenId);

    /**
     * @dev Returns the owner of the token that controls this account
     * @return The address of the token owner
     */
    function owner() external view returns (address);

    /**
     * @dev Returns the current nonce of the account
     * @return The current nonce value
     */
    function nonce() external view returns (uint256);
}