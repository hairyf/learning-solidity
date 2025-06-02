import assert from 'node:assert/strict'
import { describe, it } from 'node:test'
import { network } from 'hardhat'
import { hashTypedData, recoverAddress } from 'viem'
import { generatePrivateKey, privateKeyToAccount, privateKeyToAddress } from 'viem/accounts'
import EIP712MailValidatorModule from '../ignition/modules/EIP712MailValidator'

/**
 * EIP-712 is a standard for typed structured data signing in Ethereum, which allows users to sign complex data structures and verify the signature later.
 * The process of verifying an EIP-712 signature involves several steps:
 *
 * 1. Define a typed data object with domain, types, primaryType, and message
 * 2. Sign the typed data using the wallet client
 * 3. Recover the address from the signature using the hash of the typed data
 * 4. Compare the recovered address with the wallet address that needs to be verified
 * 5. If they match, the signature is valid, indicating reliable information
 *
 * This test suite demonstrates how to manually verify an EIP712 signature using both viem and a deployed EIP712 contract.
 */

const { viem, ignition } = await network.connect()
const privateKey = generatePrivateKey()
const address = privateKeyToAddress(privateKey)
const account = privateKeyToAccount(privateKey)

describe('EIP712', () => {
  it('Manually verify viem a valid EIP712 signature', async () => {
    // 1. Create a mock wallet client
    const wallet = await viem.getWalletClient(address, { account })

    // 2. Create a typed data object
    const typedData = {
      domain: {
        name: 'Ether Mail',
        version: '1',
        chainId: 1,
        verifyingContract: '0xCcCCccccCCCCcCCCCCCcCcCccCcCCCcCcccccccC',
      },
      types: {
        Mail: [
          { name: 'from', type: 'address' },
          { name: 'to', type: 'address' },
          { name: 'contents', type: 'string' },
        ],
      },
      primaryType: 'Mail',
      message: {
        from: '0xCD2a3d9F938E13CD947Ec05AbC7FE734Df8DD826',
        to: '0xbBbBBBBbbBBBbbbBbbBbbbbBBbBbbbbBbBbbBBbB',
        contents: 'Hello, Bob!',
      },
    } as const

    // 3. Sign the typed data
    const signature = await wallet.signTypedData(typedData)

    // 4 Recover the address from the signature
    const recoveredAddress = await recoverAddress({ hash: hashTypedData(typedData), signature })
    // or use recoverTypedDataAddress({ ...typedData, signature })

    // 5. Verify the recovered address matches the wallet address
    assert.equal(address, recoveredAddress, 'Recovered address does not match the wallet address')
  })

  it('Match verification signature with EIP712 contract', async () => {
    const { eip712 } = await ignition.deploy(EIP712MailValidatorModule)
    const wallet = await viem.getWalletClient(address, { account })

    const [
      _fields,
      name,
      version,
      chainId,
      verifyingContract,
      _salt,
      _extensions,
    ] = await eip712.read.eip712Domain()

    // 2. Create a typed data object with the contract's domain
    const typedData = {
      domain: {
        name,
        version,
        chainId,
        verifyingContract,
      },
      types: {
        Mail: [
          { name: 'from', type: 'address' },
          { name: 'to', type: 'address' },
          { name: 'contents', type: 'string' },
        ],
      },
      primaryType: 'Mail',
      message: {
        from: '0xCD2a3d9F938E13CD947Ec05AbC7FE734Df8DD826',
        to: '0xbBbBBBBbbBBBbbbBbbBbbbbBBbBbbbbBbBbbBBbB',
        contents: 'Hello, Bob!',
      },
    } as const

    // 3. Sign the typed data using the contract's eip712Sign function
    const signature = await wallet.signTypedData(typedData)

    // 4. Verify the signature using the EIP712 contract
    // Note: As this project is a learning project, so verifier has not been saved in the contract
    // In a production contract, would typically save the verifier address in the contract
    const valid = await eip712.read.verify([
      address,
      typedData.message,
      signature,
    ])
    assert.equal(valid, true, 'EIP712 signature verification failed')
  })
})
