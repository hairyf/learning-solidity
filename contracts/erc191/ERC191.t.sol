// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { Test } from "forge-std/Test.sol";
import { ERC191 } from "./ERC191.sol";
import { ECDSA } from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import { Strings } from "../library/Strings.sol";

/**
 * EIP-191 is a standard for signing messages in Ethereum, which allows users to sign arbitrary messages and verify the signature later.
 * The process of verifying an EIP-191 signature involves several steps:
 * 
 * 1. Define a message to sign
 * 2. Splicing a prefix and the message together
 * 3. Perform a Keccak-256 hash on the spliced message
 * 4. Sign the message using a private key
 * 5. Recover the address from the raw message and signature
 * 6. Compare the recovered address with the address that needs to be verified
 * 7. If they match, the signature is valid, indicating reliable information
 * 
 * This test suite demonstrates how to verify an ERC191 signature using Solidity.
 */
contract ERC191Test is Test {
    ERC191 public erc191;
    
    // Test private key and its corresponding address
    uint256 private constant PRIVATE_KEY = 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80; // First anvil default private key
    address private constant SIGNER_ADDRESS = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266; // Address corresponding to the private key
    
    function setUp() public {
        erc191 = new ERC191();
    }
    
    /**
     * Test a valid ERC191 signature verification
     * This test demonstrates the complete flow of message signing and verification
     */
    function testValidSignature() public {
        // 1. Define a message to sign
        string memory message = "Hello, world!";
        
        // 2 & 3. Get the message hash (the contract handles prefixing and hashing)
        bytes32 messageHash = erc191.hashMessage(message);
        
        // 4. Sign the message using the private key
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(PRIVATE_KEY, messageHash);
        
        // 5 & 6. Verify the signature
        address recoveredAddress = erc191.recover(message, v, r, s);
        
        // Log information for debugging
        emit log_string("Message: ");
        emit log_string(message);
        emit log_string("Message Hash: ");
        emit log_bytes32(messageHash);
        emit log_string("Signer Address: ");
        emit log_address(SIGNER_ADDRESS);
        emit log_string("Recovered Address: ");
        emit log_address(recoveredAddress);
        
        // 7. Assert that the recovered address matches the expected signer address
        assertTrue(erc191.verify(SIGNER_ADDRESS, message, v, r, s), "Signature verification failed");
        assertEq(recoveredAddress, SIGNER_ADDRESS, "Recovered address does not match the signer address");
    }
    
    /**
     * Test an invalid signature verification
     * This test demonstrates that the verification fails when using an incorrect signer address
     */
    function testInvalidSignerAddress() public {
        // 1. Define a message to sign
        string memory message = "Hello, world!";
        
        // 2 & 3. Get the message hash
        bytes32 messageHash = erc191.hashMessage(message);
        
        // 4. Sign the message using the private key
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(PRIVATE_KEY, messageHash);
        
        // Create a different address to test invalid verification
        address wrongAddress = address(0x1234567890123456789012345678901234567890);
        
        // 5, 6 & 7. Verify the signature with the wrong address
        bool isValid = erc191.verify(wrongAddress, message, v, r, s);
        
        // Assert that the verification fails
        assertFalse(isValid, "Signature verification should fail with incorrect address");
    }
    
    /**
     * Test the message hash generation
     * This test verifies that the contract correctly generates the prefixed message hash
     */
    function testMessageHashGeneration() public {
        string memory message = "Hello, world!";
        
        // Calculate the expected hash manually using the same method as the contract
        uint256 messageLength = bytes(message).length;
        string memory lengthString = Strings.uint2str(messageLength);
        bytes memory prefix = abi.encodePacked("\x19Ethereum Signed Message:\n", lengthString);
        bytes memory fullMessage = abi.encodePacked(prefix, message);
        bytes32 expectedHash = keccak256(fullMessage);
        
        // Get the hash from the contract
        bytes32 contractHash = erc191.hashMessage(message);
        
        // Log information for debugging
        emit log_string("Expected Hash: ");
        emit log_bytes32(expectedHash);
        emit log_string("Contract Hash: ");
        emit log_bytes32(contractHash);
        
        // Assert that the hashes match
        assertEq(contractHash, expectedHash, "Message hash generation is incorrect");
    }
    
    /**
     * Test signature components manipulation
     * This test demonstrates that changing any component of the signature invalidates it
     */
    function testSignatureComponentsManipulation() public {
        string memory message = "Hello, world!";
        bytes32 messageHash = erc191.hashMessage(message);
        
        // Get the original signature
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(PRIVATE_KEY, messageHash);
        
        // Test with modified v value
        uint8 modifiedV = v == 27 ? 28 : 27;
        bool isValidWithModifiedV = erc191.verify(SIGNER_ADDRESS, message, modifiedV, r, s);
        assertFalse(isValidWithModifiedV, "Signature should be invalid with modified v");
        
        // Test with modified r value
        bytes32 modifiedR = bytes32(uint256(r) + 1);
        bool isValidWithModifiedR = erc191.verify(SIGNER_ADDRESS, message, v, modifiedR, s);
        assertFalse(isValidWithModifiedR, "Signature should be invalid with modified r");
        
        // Test with modified s value
        bytes32 modifiedS = bytes32(uint256(s) + 1);
        bool isValidWithModifiedS = erc191.verify(SIGNER_ADDRESS, message, v, r, modifiedS);
        assertFalse(isValidWithModifiedS, "Signature should be invalid with modified s");
    }
    
    /**
     * Test different message lengths
     * This test verifies that the contract correctly handles messages of different lengths
     */
    function testDifferentMessageLengths() public {
        // Test with an empty message
        testMessageWithLength("");
        
        // Test with a short message
        testMessageWithLength("Hi");
        
        // Test with a longer message
        testMessageWithLength("This is a longer message to test the ERC191 signature verification with varying lengths");
    }
    
    /**
     * Helper function to test message signing and verification with a specific message
     */
    function testMessageWithLength(string memory message) internal {
        bytes32 messageHash = erc191.hashMessage(message);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(PRIVATE_KEY, messageHash);
        
        emit log_string("Testing message: ");
        emit log_string(message);
        emit log_string("Message length: ");
        emit log_uint(bytes(message).length);
        
        bool isValid = erc191.verify(SIGNER_ADDRESS, message, v, r, s);
        assertTrue(isValid, "Signature verification failed for message");
    }

    /**
     * Test signature verification using bytes signature format
     * This test demonstrates the use of the overloaded verify function that accepts a bytes signature
     */
    function testBytesSignatureVerification() public {
        // 1. Define a message to sign
        string memory message = "Hello, world!";
        
        // 2 & 3. Get the message hash
        bytes32 messageHash = erc191.hashMessage(message);
        
        // 4. Sign the message using the private key
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(PRIVATE_KEY, messageHash);
        
        // Convert v, r, s to bytes signature format
        bytes memory signature = abi.encodePacked(r, s, v);
        
        // 5 & 6. Verify the signature using bytes format
        address recoveredAddress = erc191.recover(message, signature);
        
        // Log information for debugging
        emit log_string("Message: ");
        emit log_string(message);
        emit log_string("Bytes Signature: ");
        emit log_bytes(signature);
        emit log_string("Signer Address: ");
        emit log_address(SIGNER_ADDRESS);
        emit log_string("Recovered Address: ");
        emit log_address(recoveredAddress);
        
        // 7. Assert that the recovered address matches the expected signer address
        assertTrue(erc191.verify(SIGNER_ADDRESS, message, signature), "Bytes signature verification failed");
        assertEq(recoveredAddress, SIGNER_ADDRESS, "Recovered address from bytes signature does not match the signer address");
    }

    /**
     * Test ECDSA signature format conversion
     * This test verifies that the ECDSA library correctly converts between different signature formats
     */
    function testECDSASignatureFormat() public {
        string memory message = "Hello, world!";
        bytes32 messageHash = erc191.hashMessage(message);
        
        // Sign using vm.sign which returns v, r, s
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(PRIVATE_KEY, messageHash);
        
        // Convert to ECDSA signature format (65 bytes)
        bytes memory signature = abi.encodePacked(r, s, v);
        
        // Verify both signature formats produce the same result
        address recoveredFromVRS = erc191.recover(message, v, r, s);
        address recoveredFromBytes = erc191.recover(message, signature);
        
        emit log_string("Recovered from VRS: ");
        emit log_address(recoveredFromVRS);
        emit log_string("Recovered from bytes: ");
        emit log_address(recoveredFromBytes);
        
        assertEq(recoveredFromVRS, recoveredFromBytes, "Different signature formats should recover the same address");
        assertEq(recoveredFromVRS, SIGNER_ADDRESS, "Recovered address does not match the signer address");
    }
}