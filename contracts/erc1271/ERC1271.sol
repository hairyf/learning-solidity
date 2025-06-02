// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { EIP712 } from "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import { ECDSA } from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import { MessageHashUtils } from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

contract ERC1271 is EIP712, Ownable {
  /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
  /*                         CONSTANTS                          */
  /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/
  bytes32 internal constant PERSONAL_SIGN_TYPEHASH = keccak256("PersonalSign(bytes prefixed)");

  constructor() EIP712("ERC1271", "1") Ownable(msg.sender) {}

  /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
  /*                     ERC1271 OPERATIONS                     */
  /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

  /**
   * @dev Checks if the signature is valid for the given hash.
   * @param hash The hash of the message to verify.
   * @param signature The signature bytes to verify.
   * @return magicValue The magic value indicating whether the signature is valid.
   */
  function isValidSignature(bytes32 hash, bytes memory signature) external view virtual returns (bytes4 magicValue) {
    // Return the magic value if the signer is valid
    if (verify(hash, signature)) {
      return 0x1626ba7e; // ERC1271_MAGICVALUE
    } else {
      return 0xffffffff; // Invalid signature
    }
  }

  /**
   * @dev Verifies if the signature corresponds to the owner of the contract.
   * @param hash The hash of the message to verify.
   * @param signature The signature bytes to verify.
   * @return True if the signature is valid, false otherwise.
   */
  function verify(bytes32 hash, bytes memory signature) view public returns (bool) {
    return recover(hash, signature) == owner();
  }

  /**
   * @dev Recovers the address of the signer from the given hash and signature.
   * @param hash The hash of the message to recover the signer from.
   * @param signature The signature bytes to recover the signer from.
   * @return signer The address of the signer.
   */
  function recover(bytes32 hash, bytes memory signature) pure internal returns (address signer) {
    bytes32 personalSignHash = MessageHashUtils.toEthSignedMessageHash(hash);
    signer = ECDSA.recover(personalSignHash, signature);
  }
}