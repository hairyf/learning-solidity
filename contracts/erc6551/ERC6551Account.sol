// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/interfaces/IERC1271.sol";
import "@openzeppelin/contracts/utils/cryptography/SignatureChecker.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "./interfaces/IERC6551Account.sol";
import "./library/ERC6551AccountLibrary.sol";

/**
 * @dev Error thrown when a function is called by someone other than the owner
 * @param owner The actual owner address
 */
error NotOwner(address owner);

/**
 * @dev Error thrown when a function is called by an unauthorized address
 */
error NotAuthorized();

/**
 * @dev Error thrown when input parameters are invalid
 */
error InvalidInput();

// TODO Allow sets the implementation address for a given function call
// TODO Locks the account until a certain timestamp

/**
 * @title ERC6551Account
 * @dev Implementation of the ERC6551 token bound account standard
 *
 * This contract implements a smart contract account that is owned by and bound to
 * a specific NFT. It allows the NFT owner to execute transactions from this account
 * and manage permissions for other addresses to interact with the account.
 */
contract ERC6551Account is IERC165, IERC1271, IERC6551Account, Initializable {
  using ECDSA for bytes32;

  /// @notice The current transaction nonce (incremented for each transaction)
  uint public nonce;

  /**
   * @dev Allows the account to receive native tokens
   */
  receive() external payable {}
  
  /**
   * @dev Fallback function to receive calls
   */
  fallback() external payable {}

  /// @notice Mapping from owner => selector => implementation for function overrides
  mapping(address => mapping(bytes4 => address)) public overrides;

  /// @notice Mapping from owner => caller => has permissions for authorized callers
  mapping(address => mapping(address => bool)) public permissions;

  /**
   * @notice Emitted when a function implementation override is updated
   * @param owner The owner who set the override
   * @param selector The function selector being overridden
   * @param implementation The new implementation address
   */
  event OverrideUpdated(address owner, bytes4 selector, address implementation);

  /**
   * @notice Emitted when caller permissions are updated
   * @param owner The owner who set the permission
   * @param caller The address receiving permission
   * @param hasPermission Whether the permission is granted or revoked
   */
  event PermissionUpdated(address owner, address caller, bool hasPermission);
  /**
   * @notice Emitted when a transaction is executed from this account
   * @param target The address the transaction was sent to
   * @param value The amount of native token sent with the transaction
   * @param data The calldata sent with the transaction
   */
  struct Call {
    address target;
    uint256 value;
    bytes data;
  }

  /**
   * @dev Modifier that restricts function access to the account owner
   */
  modifier onlyOwner() {
    address _owner = owner();
    if (msg.sender != _owner) revert NotOwner(_owner);
    _;
  }

  /**
   * @dev Modifier that restricts function access to authorized callers
   */
  modifier onlyAuthorized() {
    if (!isAuthorized(msg.sender)) revert NotAuthorized();
    _;
  }

  /**
   * @dev Initializes the account with a list of permitted callers
   * @param _permissions Array of addresses to grant permissions to
   */
  function initialize(address[] memory _permissions) external initializer {
    address _owner = owner();
    for (uint256 i = 0; i < _permissions.length; i++) {
      permissions[_owner][_permissions[i]] = true;
      emit PermissionUpdated(_owner, _permissions[i], true);
    }
  }

  /**
   * @dev Executes a transaction from this account if caller is authorized
   * @param target The target address for the transaction
   * @param value The amount of native token to send
   * @param data The calldata to send
   * @return result The bytes returned from the transaction execution
   */
  function execute(address target, uint256 value, bytes calldata data) public payable onlyAuthorized returns (bytes memory result) {
    result = _call(target, value, data);

    ++nonce;

    emit TransactionExecuted(target, value, data);
  }

  /**
   * @dev Executes multiple transactions from this account if caller is authorized
   * @param data Array of Call structs containing target, value, and calldata
   * @return results Array of bytes returned from each transaction execution
   */
  function executeBatch(Call[] calldata data) external payable onlyAuthorized returns (bytes[] memory results) {
    results = new bytes[](data.length);

    for (uint256 i = 0; i < data.length; i++) {
      results[i] = _call(data[i].target, data[i].value, data[i].data);

      ++nonce;

      emit TransactionExecuted(data[i].target, data[i].value, data[i].data);
    }
  }

  /**
   * @dev Returns information about the token that owns this account
   * @return chainId The chain ID where the token exists
   * @return tokenContract The address of the token contract
   * @return tokenId The ID of the token
   */
  function token() external view returns (uint256 chainId, address tokenContract, uint256 tokenId) {
    (chainId, tokenContract, tokenId) = ERC6551AccountLibrary.token();
  }

  /**
   * @dev Returns the owner of the token that controls this account
   * @return The address of the token owner
   */
  function owner() public view returns (address) {
    (
      uint256 chainId,
      address tokenContract,
      uint256 tokenId
    ) = ERC6551AccountLibrary.token();

    if (chainId != block.chainid)
      return address(0);

    return IERC721(tokenContract).ownerOf(tokenId);
  }

  /**
   * @dev Grants or revokes execution permissions for multiple callers
   * @param callers Array of caller addresses
   * @param _permissions Array of permission flags (true to grant, false to revoke)
   */
  function setPermissions(address[] calldata callers, bool[] calldata _permissions) external onlyOwner {
    address _owner = owner();

    uint256 length = callers.length;
    if (_permissions.length != length) revert InvalidInput();

    for (uint256 i = 0; i < length; i++) {
      permissions[_owner][callers[i]] = _permissions[i];
      emit PermissionUpdated(_owner, callers[i], _permissions[i]);
    }

    ++nonce;
  }
  
  /**
   * @dev Checks if this contract supports a given interface
   * @param interfaceId The interface identifier to check
   * @return True if the interface is supported
   */
  function supportsInterface(bytes4 interfaceId) public pure returns (bool) {
    return (interfaceId == type(IERC165).interfaceId ||
    interfaceId == type(IERC6551Account).interfaceId);
  }

  /**
   * @dev EIP-1271 signature validation
   * @param hash The hash of the data that was signed
   * @param signature The signature to verify
   * @return magicValue The magic value indicating if the signature is valid
   */
  function isValidSignature(bytes32 hash, bytes memory signature) external view returns (bytes4 magicValue) {
    bool isValid = SignatureChecker.isValidSignatureNow(
      owner(),
      hash,
      signature
    );

    if (isValid)
      return IERC1271.isValidSignature.selector;

    return "";
  }

  /**
   * @dev Checks if an address is authorized to execute transactions
   * @param caller The address to check
   * @return True if the address is authorized
   */
  function isAuthorized(address caller) public view returns (bool) {
    address _owner = owner();

    if (caller == _owner) return true;
    if (permissions[_owner][caller]) return true;
  
    return false;
  }

  /**
   * @dev Internal function to execute a low-level call
   * @param to The target address
   * @param value The amount of native token to send
   * @param data The calldata to send
   * @return result The bytes returned from the call
   */
  function _call(address to, uint256 value, bytes memory data) internal returns (bytes memory result) {
    bool success;
    (success, result) = to.call{value: value}(data);
    if (!success) assembly {
      revert(add(result, 0x20), mload(result))
    }
  }
}
