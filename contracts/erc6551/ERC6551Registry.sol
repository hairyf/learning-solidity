// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Create2.sol";

import "./interfaces/IERC6551Registry.sol";
import "./library/ERC6551BytecodeLibrary.sol";

contract ERC6551Registry is IERC6551Registry {

  function createAccount(
    address implementation,
    uint256 chainId,
    address tokenContract,
    uint256 tokenId,
    uint256 salt,
    bytes calldata data
  ) external returns (address) {
    bytes memory code = ERC6551BytecodeLibrary.getCreationCode(
      implementation,
      chainId,
      tokenContract,
      tokenId,
      salt
    );

    address _account = Create2.computeAddress(bytes32(salt), keccak256(code));

    if (_account.code.length != 0) 
      return _account;

    emit AccountCreated(
      _account,
      implementation,
      chainId,
      tokenContract,
      tokenId,
      salt
    );

    _account = Create2.deploy(0, bytes32(salt), code);

    // Call the initialize function on the newly created account
    address[] memory permissions = new address[](1);
    permissions[0] = address(this);

    bytes memory encoded = abi.encodeWithSignature("initialize(address[])",  permissions);
    (bool s, bytes memory r) = _account.call(abi.encodePacked(encoded, msg.sender));
    if (!s) assembly { revert(add(r, 32), mload(r)) }

    if (data.length != 0) {
      (bool success, bytes memory result) = _account.call(
        abi.encodePacked(data, msg.sender)
      );
      if (!success) assembly {
        revert(add(result, 32), mload(result))
      }
    }

    return _account;
  }

  function account(
    address implementation,
    uint256 chainId,
    address tokenContract,
    uint256 tokenId,
    uint256 salt
  ) external view returns (address) {
    return
      Create2.computeAddress(
        bytes32(salt),
        keccak256(
          ERC6551BytecodeLibrary.getCreationCode(
            implementation,
            chainId,
            tokenContract,
            tokenId,
            salt
          )
        )
      );
  }
}