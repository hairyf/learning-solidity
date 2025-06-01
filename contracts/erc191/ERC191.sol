// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { Strings } from "../library/Strings.sol";
import { ECDSA } from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

/**
 * @title ERC191
 * @dev This contract provides functions to hash and verify messages according to the ERC191 standard.
 * It allows for the recovery of the signer's address from a signed message.
 */
contract ERC191 {
  /**
   * @dev Hashes a message according to the ERC191 standard.
   * @param _message The message to be hashed.
   * @return messageHash The resulting hash of the message.
   */
  function hashMessage(string memory _message) public pure returns (bytes32 messageHash) {
    messageHash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", Strings.uint2str(bytes(_message).length), _message));
  }

  /**
   * @dev Verifies if a given signature corresponds to the signer of a message.
   * @param _signer The address of the expected signer.
   * @param _message The original message that was signed.
   * @param v The recovery id of the signature.
   * @param r The r value of the signature.
   * @param s The s value of the signature.
   * @return valid True if the signature is valid, false otherwise.
   */
  function verify(
    address _signer,
    string memory _message,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) public pure returns (bool valid) {
    valid = recover(_message, v, r, s) == _signer;
  }


  /**
   * @dev Verifies if a given signature corresponds to the signer of a message.
   * @param _singer The address of the expected signer.
   * @param _message The original message that was signed.
   * @param _signature The signature bytes.
   * @return valid True if the signature is valid, false otherwise.
   */
  function verify(
    address _singer,
    string memory _message,
    bytes memory _signature
  ) public pure returns (bool valid) {
    valid = ECDSA.recover(hashMessage(_message), _signature) == _singer;
  }

  /**
   * @dev Recovers the signer's address from a signed message.
   * @param _message The original message that was signed.
   * @param v The recovery id of the signature.
   * @param r The r value of the signature.
   * @param s The s value of the signature.
   * @return signer The address of the signer.
   */
  function recover(
    string memory _message,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) public pure returns (address signer) {
    signer = ecrecover(hashMessage(_message), v, r, s);
  }

  /**
   * @dev Recovers the signer's address from a signed message.
   * @param _message The original message that was signed.
   * @param _signature The signature bytes.
   * @return signer The address of the signer.
   */
  function recover(
    string memory _message,
    bytes memory _signature
  ) public pure returns (address signer) {
    signer = ECDSA.recover(hashMessage(_message), _signature);
  }
}
