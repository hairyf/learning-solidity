// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title IERC6551Registry
 * @dev Interface for the ERC6551 Registry contract
 *
 * This interface defines the standard functions for creating and computing
 * the addresses of token bound accounts according to the ERC6551 standard.
 * ERC6551 allows for NFTs to own assets and interact with protocols through
 * associated smart contract accounts.
 */
interface IERC6551Registry {
    /**
     * @dev Emitted when a new account is created
     * @param account The address of the created account
     * @param implementation The implementation contract address
     * @param chainId The chain ID where the token exists
     * @param tokenContract The address of the token contract
     * @param tokenId The ID of the token
     * @param salt A unique value to ensure unique account addresses
     */
    event AccountCreated(
        address account,
        address implementation,
        uint256 chainId,
        address tokenContract,
        uint256 tokenId,
        uint256 salt
    );

    /**
     * @dev Creates a new ERC6551 account
     * @param implementation The implementation contract address
     * @param chainId The chain ID where the token exists
     * @param tokenContract The address of the token contract
     * @param tokenId The ID of the token
     * @param seed A unique value to ensure unique account addresses
     * @param initData Initialization data for the new account
     * @return The address of the created account
     */
    function createAccount(
        address implementation,
        uint256 chainId,
        address tokenContract,
        uint256 tokenId,
        uint256 seed,
        bytes calldata initData
    ) external returns (address);

    /**
     * @dev Computes the address of an ERC6551 account
     * @param implementation The implementation contract address
     * @param chainId The chain ID where the token exists
     * @param tokenContract The address of the token contract
     * @param tokenId The ID of the token
     * @param salt A unique value to ensure unique account addresses
     * @return The address of the account (created or not)
     */
    function account(
        address implementation,
        uint256 chainId,
        address tokenContract,
        uint256 tokenId,
        uint256 salt
    ) external view returns (address);
}