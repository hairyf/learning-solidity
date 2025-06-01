// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

/**
 * @title ERC6551 Test Suite
 * @dev Test suite for ERC6551 token bound accounts implementation
 *
 * This file contains tests for the ERC6551 implementation, including:
 * - Basic account creation and verification
 * - Account initialization and permissions
 * - Security tests to verify proper authorization
 * - Tests for executing operations during account creation
 */

import { Test, console } from "forge-std/Test.sol";
import { ERC6551Account } from "./ERC6551Account.sol";
import { ERC6551Registry } from "./ERC6551Registry.sol";
import { ERC721 } from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { IERC6551Account } from "./interfaces/IERC6551Account.sol";
/**
 * @title ERC721Mock
 * @dev Simple ERC721 implementation for testing purposes
 */
contract ERC721Mock is ERC721 {
  constructor(string memory name, string memory symbol) ERC721(name, symbol) {}

  function mint(address to, uint256 tokenId) public {
    _mint(to, tokenId);
  }

  function burn(uint256 tokenId) public {
    _burn(tokenId);
  }
}

/**
 * @title ERC20Mock
 * @dev Simple ERC20 implementation for testing purposes
 */
contract ERC20Mock is ERC20 {
  constructor(string memory name, string memory symbol) ERC20(name, symbol) {}

  function mint(address to, uint256 amount) public {
    _mint(to, amount);
  }
}

/**
 * @title ERC6551Test
 * @dev Test contract for ERC6551 implementation
 *
 * This contract tests various aspects of the ERC6551 implementation:
 * - Account creation and verification
 * - Token binding and ownership
 * - Permission management
 * - Security features
 */
contract ERC6551Test is Test {
  ERC6551Account public account;
  ERC6551Registry public registry;

  /**
   * @dev Setup function executed before each test
   * Creates new instances of the registry and account implementation
   */
  function setUp() public {
    registry = new ERC6551Registry();
    account = new ERC6551Account();
  }

  /**
   * @dev Tests basic account creation and verification
   *
   * This test verifies:
   * - Account creation succeeds
   * - Token ownership is correctly established
   * - Account owner matches the token owner
   * - Token binding information is correctly stored
   */
  function testCreateAccount() public {
    ERC721Mock token = new ERC721Mock("TestToken", "TTK");
    token.mint(address(this), 1);
   
    address user = registry.createAccount(
      address(account),
      block.chainid,
      address(token),
      1,
      0,
      ""
    );

    assertTrue(user != address(0), "Account creation failed");
    assertEq(token.ownerOf(1), address(this), "Token owner should be this contract");
    assertEq(IERC6551Account(user).owner(), address(this), "Account owner should be this contract");

    (uint256 chainId, address tokenContract, uint256 tokenId) = IERC6551Account(user).token();

    assertEq(chainId, block.chainid, "Chain ID should match");
    assertEq(tokenContract, address(token), "Token contract should match");
    assertEq(tokenId, 1, "Token ID should match");
  }
  /**
   * @dev Tests account creation with immediate ERC20 approval
   *
   * This test verifies that an account can execute an ERC20 approve operation
   * during its creation process, demonstrating the ability to perform
   * operations in the same transaction as account creation.
   *
   * @param spender The address to approve for token spending
   */
  function testCreateAccountWithInitializeErc20Approve(address spender) public {
    vm.assume(spender != address(0));
    ERC20Mock token = new ERC20Mock("TestToken", "TTK");
    ERC721Mock nft = new ERC721Mock("TestNFT", "TNFT");
    token.mint(address(this), 1000 * 10 ** 18);
    nft.mint(address(this), 1);

    // Execute approve operation during account creation
    bytes memory approveEncoded = abi.encodeWithSignature(
      "approve(address,uint256)",
      spender,
      100
    );
    bytes memory executeEncoded = abi.encodeWithSignature(
      "execute(address,uint256,bytes)",
      address(token),
      0,
      approveEncoded
    );
    
    address payable user = payable(registry.createAccount(
      address(account),
      block.chainid,
      address(nft),
      1,
      0,
      executeEncoded
    ));

    // Verify approve operation was successful
    assertEq(token.allowance(user, spender), 100, "Allowance should be set to 100");
  }

  /**
   * @dev Tests the security of account initialization
   *
   * This test verifies that:
   * 1. Accounts are automatically initialized during creation
   * 2. The Registry is properly authorized during initialization
   * 3. Attackers cannot call initialize again (it can only be called once)
   * 4. Unauthorized addresses cannot execute operations on the account
   * 5. Account assets are protected from unauthorized access
   */
  function testCreateAccountInitializeSecurity() public {
    // Create test addresses
    address attacker = address(0xBEEF);
    
    // Create NFT and account
    ERC721Mock nft = new ERC721Mock("TestNFT", "TNFT");
    nft.mint(address(this), 1);
    
    // Create account - initialize is now automatically called
    address payable user = payable(registry.createAccount(
      address(account),
      block.chainid,
      address(nft),
      1,
      0,
      ""
    ));
    
    // Verify account creation was successful
    assertTrue(user != address(0), "Account creation failed");
    assertEq(IERC6551Account(user).owner(), address(this), "Account owner should be this contract");
    
    // Verify Registry has been authorized
    assertTrue(
      ERC6551Account(user).permissions(address(this), address(registry)),
      "Registry should be authorized after initialization"
    );
    
    // Attacker attempts to call initialize to authorize themselves - should fail
    address[] memory permissions = new address[](1);
    permissions[0] = attacker;
    
    vm.prank(attacker); // Simulate attacker

    // Verify initialize call failed as expected
    vm.expectRevert(bytes4(keccak256("InvalidInitialization()")));
    ERC6551Account(user).initialize(permissions);
    
    // Verify attacker did not gain authorization
    assertFalse(
      ERC6551Account(user).permissions(address(this), attacker),
      "Attacker should not be authorized"
    );
    
    // Create tokens and attempt transfer
    ERC20Mock token = new ERC20Mock("TestToken", "TTK");
    token.mint(user, 1000);
    
    // Attacker attempts to execute operation - should fail
    vm.prank(attacker);

    // Execute should fail when called by unauthorized address
    vm.expectRevert(bytes4(keccak256("NotAuthorized()")));
    IERC6551Account(user).execute(address(token), 0, abi.encodeWithSignature("transfer(address,uint256)", attacker, 1000));
    
    // Verify tokens were not transferred
    assertEq(token.balanceOf(attacker), 0, "Attacker should not be able to transfer tokens");
    assertEq(token.balanceOf(user), 1000, "Tokens should remain in the account");
  }

 /**
   * @dev Tests account creation with multicall approve operations
   *
   * This test verifies that an account can execute multiple ERC20 approve operations
   * in a single transaction during its creation process, using the Multicall contract.
   * It demonstrates the ability to batch multiple operations efficiently.
   *
   * @param spenders Array of addresses to approve for token spending
   */
  function testCreateAccountWithInitializeMulticallApprove(address[] memory spenders) public {
    vm.assume(spenders.length > 0);
    vm.assume(spenders.length <= 20);
    for (uint256 i = 0; i < spenders.length; i++) {
      vm.assume(spenders[i] != address(0)); // Ensure no zero addresses
      // Ensure no duplicate addresses
      for (uint256 j = 0; j < i; j++)
        vm.assume(spenders[i] != spenders[j]);
    }

    // Create test tokens
    ERC20Mock token = new ERC20Mock("TestToken", "TTK");
    ERC721Mock nft = new ERC721Mock("TestNFT", "TNFT");
    token.mint(address(this), 1000 * 10 ** 18);
    nft.mint(address(this), 1);

    // Prepare multicall data for approving multiple spenders
    ERC6551Account.Call[] memory calls = new ERC6551Account.Call[](spenders.length);

    for (uint256 i = 0; i < spenders.length; i++) {
      // Create approve call data for each spender
      // Different amount for each spender for verification
      bytes memory approveEncoded = abi.encodeWithSignature(
        "approve(address,uint256)",
        spenders[i],
        100 * (i + 1) 
      );
      // Add to calls array
      calls[i] = ERC6551Account.Call(address(token), 0, approveEncoded);
    }

    // Encode execute operation that will call multicall
    bytes memory executeBatchEncoded = abi.encodeWithSignature("executeBatch((address,uint256,bytes)[])", calls);

    // Create account with execute operation
    address payable user = payable(registry.createAccount(
      address(account),
      block.chainid,
      address(nft),
      1,
      0,
      executeBatchEncoded
    ));


    // Verify all approve operations were successful
    for (uint256 i = 0; i < spenders.length; i++) {
      uint256 expectedAllowance = 100 * (i + 1);
      assertEq(token.allowance(user, spenders[i]), expectedAllowance, "Allowance for spender is incorrect");
    }
  }
}