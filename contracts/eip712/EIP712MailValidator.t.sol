// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { Test } from "forge-std/Test.sol";
import { EIP712MailValidator } from "./EIP712MailValidator.sol";
import { ECDSA } from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

/**
 * EIP-712 is a standard in Ethereum for signing structured data, allowing users to sign structured data and verify signatures later.
 * The process of verifying an EIP-712 signature includes the following steps:
 * 
 * 1. Define the structured data to be signed (such as the Mail struct)
 * 2. Hash the structured data according to the EIP-712 standard
 * 3. Sign the hash using a private key
 * 4. Recover the signer's address from the signature and original data
 * 5. Compare the recovered address with the address to be verified
 * 6. If they match, the signature is valid, indicating the message is authentic
 * 
 * This test suite demonstrates how to verify EIP712MailValidator signatures using Solidity.
 */
contract EIP712MailValidatorTest is Test {
  EIP712MailValidator public validator;
  
  // Test private key and its corresponding address
  uint256 private constant PRIVATE_KEY = 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80; // First default anvil private key
  address private constant SIGNER_ADDRESS = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266; // Address corresponding to the private key
  
  // Mail struct for testing
  EIP712MailValidator.Mail mail;
  
  function setUp() public {
    validator = new EIP712MailValidator();
    
    // Initialize default Mail struct
    mail = EIP712MailValidator.Mail({
      from: SIGNER_ADDRESS,
      to: address(0x1234567890123456789012345678901234567890),
      contents: "Hello, EIP-712!"
    });
  }
    
  /**
   * Test valid EIP-712 signature verification
   * This test demonstrates the complete flow of message signing and verification
   */
  function testValidSignature() public {
    // 1. Get the hash of the message to be signed
    bytes32 structHash = validator.hashStruct(mail);
    bytes32 digestHash = validator.hashDigest(structHash);

    // 2. Sign the message using the private key
    (uint8 v, bytes32 r, bytes32 s) = vm.sign(PRIVATE_KEY, digestHash);
    bytes memory signature = abi.encodePacked(r, s, v);
    
    // 3. Verify the signature
    bool isValid = validator.verify(SIGNER_ADDRESS, mail, signature);
    
    // Log debug information
    emit log_string("Mail From: ");
    emit log_address(mail.from);
    emit log_string("Mail To: ");
    emit log_address(mail.to);
    emit log_string("Mail Contents: ");
    emit log_string(mail.contents);
    emit log_string("Digest: ");
    emit log_bytes32(digestHash);
    emit log_string("Signature: ");
    emit log_bytes(signature);
    
    // 4. Assert that signature verification succeeded
    assertTrue(isValid, "Signature verification failed");
  }
  
  /**
   * Test invalid signature verification
   * This test demonstrates verification failure when using an incorrect signer address
   */
  function testInvalidSignerAddress() public view {
    // 1. Get the hash of the message to be signed
    bytes32 structHash = validator.hashStruct(mail);
    bytes32 digestHash = validator.hashDigest(structHash);
    
    // 2. Sign the message using the private key
    (uint8 v, bytes32 r, bytes32 s) = vm.sign(PRIVATE_KEY, digestHash);
    bytes memory signature = abi.encodePacked(r, s, v);
    
    // Create a different address to test invalid verification
    address wrongAddress = address(0x1234567890123456789012345678901234567890);
    
    // 3. Verify the signature with the wrong address
    bool isValid = validator.verify(wrongAddress, mail, signature);
    
    // Assert verification fails
    assertFalse(isValid, "Signature verification should fail with incorrect address");
  }
  
  /**
   * Test different mail contents
   * This test verifies that the contract correctly handles mails with different contents
   */
  function testDifferentMailContents() public {
    // Test empty content
    testMailWithContent("");
    
    // Test short content
    testMailWithContent("Hi");
    
    // Test long content
    testMailWithContent("This is a longer message to test the EIP-712 signature verification with varying lengths");
  }
  
  /**
   * Helper function to test mail signature and verification with specific content
   */
  function testMailWithContent(string memory content) internal {
    // Create mail with specific content
    EIP712MailValidator.Mail memory testMail = EIP712MailValidator.Mail({
      from: SIGNER_ADDRESS,
      to: address(0x1234567890123456789012345678901234567890),
      contents: content
    });
    
    // Get message hash and sign it
    bytes32 structHash = validator.hashStruct(testMail);
    bytes32 digestHash = validator.hashDigest(structHash);
    (uint8 v, bytes32 r, bytes32 s) = vm.sign(PRIVATE_KEY, digestHash);
    bytes memory signature = abi.encodePacked(r, s, v);
    
    // Log test information
    emit log_string("Testing mail content: ");
    emit log_string(content);
    emit log_string("Content length: ");
    emit log_uint(bytes(content).length);
    
    // Verify signature
    bool isValid = validator.verify(SIGNER_ADDRESS, testMail, signature);
    assertTrue(isValid, "Mail signature verification failed");
  }
  
  /**
   * Test signature component manipulation
   * This test demonstrates that changing any component of the signature makes it invalid
   */
  function testSignatureComponentsManipulation() public view {
    // Get message hash and sign it
    bytes32 structHash = validator.hashStruct(mail);
    bytes32 digestHash = validator.hashDigest(structHash);
    (uint8 v, bytes32 r, bytes32 s) = vm.sign(PRIVATE_KEY, digestHash);
    
    // Test modifying v value
    uint8 modifiedV = v == 27 ? 28 : 27;
    bytes memory signatureWithModifiedV = abi.encodePacked(r, s, modifiedV);
    bool isValidWithModifiedV = validator.verify(SIGNER_ADDRESS, mail, signatureWithModifiedV);
    assertFalse(isValidWithModifiedV, "Signature should be invalid with modified v");
    
    // Test modifying r value
    bytes32 modifiedR = bytes32(uint256(r) + 1);
    bytes memory signatureWithModifiedR = abi.encodePacked(modifiedR, s, v);
    bool isValidWithModifiedR = validator.verify(SIGNER_ADDRESS, mail, signatureWithModifiedR);
    assertFalse(isValidWithModifiedR, "Signature should be invalid with modified r");
    
    // Test modifying s value
    bytes32 modifiedS = bytes32(uint256(s) + 1);
    bytes memory signatureWithModifiedS = abi.encodePacked(r, modifiedS, v);
    bool isValidWithModifiedS = validator.verify(SIGNER_ADDRESS, mail, signatureWithModifiedS);
    assertFalse(isValidWithModifiedS, "Signature should be invalid with modified s");
  }
  
  /**
   * Test different mail fields
   * This test verifies that changing any field of the mail makes the signature invalid
   */
  function testDifferentMailFields() public view {
    // Get signature for original mail
    bytes32 structHash = validator.hashStruct(mail);
    bytes32 digestHash = validator.hashDigest(structHash);
    (uint8 v, bytes32 r, bytes32 s) = vm.sign(PRIVATE_KEY, digestHash);
    bytes memory signature = abi.encodePacked(r, s, v);
    
    // Test modifying from field
    EIP712MailValidator.Mail memory mailWithDifferentFrom = EIP712MailValidator.Mail({
      from: address(0x2222222222222222222222222222222222222222),
      to: mail.to,
      contents: mail.contents
    });
    bool isValidWithDifferentFrom = validator.verify(SIGNER_ADDRESS, mailWithDifferentFrom, signature);
    assertFalse(isValidWithDifferentFrom, "Signature should be invalid with modified from field");
    
    // Test modifying to field
    EIP712MailValidator.Mail memory mailWithDifferentTo = EIP712MailValidator.Mail({
      from: mail.from,
      to: address(0x3333333333333333333333333333333333333333),
      contents: mail.contents
    });
    bool isValidWithDifferentTo = validator.verify(SIGNER_ADDRESS, mailWithDifferentTo, signature);
    assertFalse(isValidWithDifferentTo, "Signature should be invalid with modified to field");
    
    // Test modifying contents field
    EIP712MailValidator.Mail memory mailWithDifferentContents = EIP712MailValidator.Mail({
      from: mail.from,
      to: mail.to,
      contents: "Different content"
    });
    bool isValidWithDifferentContents = validator.verify(SIGNER_ADDRESS, mailWithDifferentContents, signature);
    assertFalse(isValidWithDifferentContents, "Signature should be invalid with modified contents field");
  }
  
  /**
   * Test hashStruct function
   * This test verifies that the contract correctly generates struct hashes
   */
  function testHashStruct() public {
    // Get hash from contract
    bytes32 contractHash = validator.hashStruct(mail);
    
    // Manually calculate expected hash
    bytes32 expectedHash = keccak256(
      abi.encode(
        validator.MAIL_TYPE_HASH(),
        mail.from,
        mail.to,
        keccak256(bytes(mail.contents))
      )
    );
    
    // Log debug information
    emit log_string("Expected Hash: ");
    emit log_bytes32(expectedHash);
    emit log_string("Contract Hash: ");
    emit log_bytes32(contractHash);
    
    // Assert hashes match
    assertEq(contractHash, expectedHash, "Struct hash generation is incorrect");
  }
}
