import assert from 'node:assert/strict'
import { describe, it } from 'node:test'
import { network } from 'hardhat'
import { getAddress, hashMessage, keccak256, recoverAddress, toBytes, toHex, toPrefixedMessage } from 'viem'
import { generatePrivateKey, privateKeyToAccount, privateKeyToAddress, sign } from 'viem/accounts'

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
 * This test suite demonstrates how to manually verify an EIP191 signature using both viem and ethers.js libraries.
 */

const { viem, ethers } = await network.connect()
const privateKey = generatePrivateKey()

describe('EIP191', () => {
  it('Manually verify viem a valid EIP191 signature', async () => {
    // 1. Create a mock wallet client
    const wallet = await viem.getWalletClient(privateKeyToAddress(privateKey), { account: privateKeyToAccount(privateKey) })

    // 2. Define a message to sign
    const message = 'Hello, world!'

    // 3 Splicing prefix and message together
    const prefixedMessage = toPrefixedMessage(message)
    console.log('Prefixed Message:', prefixedMessage)

    // 4. Perform Keccak-256 hash on the spliced message
    const hash = keccak256(prefixedMessage) // or use hashMessage(message)
    console.log('Message Hash:', hash)

    // 5. Sign the message using a private key
    const signature = await sign({ hash, privateKey, to: 'hex' }) // or use wallet.signMessage(message)
    console.log('EIP191 Signature:', signature)

    // 6. Verify the signature
    const address = getAddress(wallet.account.address)
    const recoveredAddress = await recoverAddress({ hash: hashMessage(message), signature }) // or use recoverMessageAddress({ message, signature })
    console.log('Sign Address:', address)
    console.log('Recovered Address:', recoveredAddress)

    assert.equal(address, recoveredAddress, 'Recovered address does not match the wallet address')
  })

  it('Manually verify ethers an invalid EIP191 signature', async () => {
    const client = ethers.getDefaultProvider()
    // 1. Create a mock wallet client
    const wallet = new ethers.Wallet(privateKey, client)

    // 2. Define a message to sign
    const message = 'Hello, world!'

    // 3 Splicing prefix and message together
    const prefixedMessage = `\x19Ethereum Signed Message:\n${toBytes(message).length}${message}`
    console.log('Prefixed Message:', prefixedMessage)

    // 4. Perform Keccak-256 hash on the spliced message
    const hash = keccak256(toBytes(prefixedMessage))
    console.log('Message Hash:', hash)

    // 5. Sign the message using a private key
    const signature = await wallet.signMessage(message)
    console.log('EIP191 Signature:', signature)

    // 6. Verify the signature
    const recoveredAddress = ethers.verifyMessage(message, signature)
    console.log('Sign Address:', wallet.address)
    console.log('Recovered Address:', recoveredAddress)
    assert.equal(wallet.address, recoveredAddress, 'Recovered address does not match the wallet address')

    // Manual signature
    const signatureKey = new ethers.SigningKey(privateKey)
    const signatureObject = signatureKey.sign(hash)
    const signatured = ethers.Signature.from(signatureObject)

    console.log('Manual Signature:', signatured)
    console.log('Manual Recovered:', signatured.serialized === signature)

    console.log('r: ', signatured.r)
    console.log('s: ', signatured.s)
    console.log('v: ', signatured.v)

    console.log('r (hex): ', toHex(signatured.r))
    console.log('s (hex): ', toHex(signatured.s))
    console.log('v (hex): ', signatured.v.toString(16))
  })
})
