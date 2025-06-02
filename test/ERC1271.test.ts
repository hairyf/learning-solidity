import type { Address, Hex } from 'viem'
import assert from 'node:assert/strict'
import { describe, it } from 'node:test'
import { network } from 'hardhat'
import { encodePacked, getAddress, hashMessage, keccak256, recoverAddress, toPrefixedMessage } from 'viem'
import { generatePrivateKey, privateKeyToAccount, privateKeyToAddress, sign } from 'viem/accounts'

/**
 * EIP-1271 is a standard for verifying signatures on smart contracts, allowing contracts to validate signatures without needing to know the signer's address.
 * The process of verifying an ERC1271 signature involves several steps:
 *
 * 1. Create a mock wallet client using viem
 * 2. Define a message to be signed, which can be any data structure
 * 3. Splice the prefix and message together to create a prefixed message
 * 4. Perform a Keccak-256 hash on the spliced message
 * 5. Sign the message using a verifier's private key
 * 6. Verify the signature by recovering the address from the signature and comparing it with the verifier's address
 * 7. If the recovered address matches the verifier's address, return the ERC1271 magic value for a valid signature
 * This test suite demonstrates how to manually verify an ERC1271 signature using viem.
 * Note: The ERC1271 standard defines a magic value `0x1626BA7E` for valid signatures and `0x00000000` for invalid signatures.
 *
 * This test suite demonstrates how to manually verify an ERC1271 signature using viem.
 */

const { viem } = await network.connect()
const privateKey = generatePrivateKey()
const address = privateKeyToAddress(privateKey)
const account = privateKeyToAccount(privateKey)

function solidityPackedKeccak256(types: string[], values: (string | number)[]) {
  return keccak256(encodePacked(types, values))
}

async function isValidSignature(verifier: Address, hash: Hex, signature: Hex) {
  // When using signMessage with { raw: hash }, the wallet applies the Ethereum Signed Message prefix
  // So we need to apply the same prefix when verifying
  const recoveredAddress = await recoverAddress({ hash: hashMessage(hash), signature })

  if (recoveredAddress === getAddress(verifier))
    return '0x1626BA7E' // ERC1271 magic value for valid signature
  else
    return '0x00000000' // ERC1271 magic value for invalid signature
}

describe('ERC1271', () => {
  it('Manually verify viem a valid ERC1271 signature', async () => {
    // 1. Create a mock wallet client
    const _wallet = await viem.getWalletClient(address, { account })

    // 2. Define a params object to verify
    const messageHash = solidityPackedKeccak256(['string'], ['Hairyf']) // or use keccak256(encodePacked(types, values))

    // 3. Splicing prefix and message together
    const prefixedMessage = toPrefixedMessage(messageHash)
    console.log('Prefixed Message:', prefixedMessage)

    // 4. Perform Keccak-256 hash on the spliced message
    const hash = keccak256(prefixedMessage) // or use hashMessage(messageHash)
    console.log('Message Hash:', hash)

    // 5. sign the message using a verifier private key
    const signature = await sign({ hash, privateKey, to: 'hex' })
    console.log('EIP191 Signature:', signature)

    // 9. Verify the signature
    const magicValue = await isValidSignature(address, messageHash, signature)
    console.log('Magic Value:', magicValue)
    assert.equal(magicValue, '0x1626BA7E', 'Magic value does not match the expected ERC1271 valid signature value')
  })
})
