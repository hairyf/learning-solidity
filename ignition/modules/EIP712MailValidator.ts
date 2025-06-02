import { buildModule } from '@nomicfoundation/hardhat-ignition/modules'

const EIP712MailValidatorModule = buildModule('EIP712MailValidator', (m) => {
  const eip712 = m.contract('EIP712MailValidator', [])
  return { eip712 }
})

export default EIP712MailValidatorModule
