// contracts/MyContractDomain.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { ECDSA } from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import { EIP712 } from "@openzeppelin/contracts/utils/cryptography/EIP712.sol";

/// @dev Unsafe contract to demonstrate the use of EIP712 and ECDSA.
contract EIP712MailValidator is EIP712 {
  bytes32 public MAIL_TYPE_HASH = keccak256("Mail(address from,address to,string contents)");

  struct Mail {
    address from;
    address to;
    string contents;
  }

  constructor() EIP712("Mail", "1") {}
  
  /**
   * @dev Hashes a Mail struct according to the EIP712 standard.
   * @param mail The Mail struct containing the details of the message.
   * @return hash The resulting hash of the Mail struct.
   */
  function hashStruct(Mail memory mail) view internal returns (bytes32 hash) {
    hash = keccak256(
      abi.encode(
        MAIL_TYPE_HASH,
        mail.from,
        mail.to,
        keccak256(bytes(mail.contents))
      )
    );
  }

  /**
   * @dev Verifies if a given signature corresponds to the signer of a Mail struct.
   * @param singer The address of the expected signer.
   * @param mail The Mail struct containing the details of the message.
   * @param signature The signature bytes to verify.
   * @return valid True if the signature is valid, false otherwise.
   */
  function verify(address singer, Mail memory mail, bytes memory signature) public view returns (bool valid) {
    valid = recover(mail, signature) == singer;
  }

  /**
   * @dev Recovers the address of the signer from the given mail and signature.
   * @param mail The Mail struct containing the details of the message.
   * @param signature The signature bytes to verify.
   * @return The address of the signer.
   */
  function recover(Mail memory mail, bytes memory signature) internal view returns (address) {
    bytes32 digest = _hashTypedDataV4(hashStruct(mail));
    return ECDSA.recover(digest, signature);
  }
}
