/// <reference types="etherlib-generator/hardhat-network" />

import type { HardhatUserConfig } from 'hardhat/types/config'
import hardhatEthersPlugin from '@nomicfoundation/hardhat-ethers'
import hardhatIgnitionViewPlugin from '@nomicfoundation/hardhat-ignition-viem'
import hardhatToolboxViemPlugin from '@nomicfoundation/hardhat-toolbox-viem'

const config = {
  plugins: [
    hardhatIgnitionViewPlugin,
    hardhatToolboxViemPlugin,
    hardhatEthersPlugin,
  ],
  solidity: {
    profiles: {
      default: { version: '0.8.28' },
      production: {
        settings: {
          evmVersion: 'shanghai',
          optimizer: {
            enabled: true,
            runs: 200,
          },
        },
        version: '0.8.28',
      },
    },
    remappings: ['forge-std/=npm/forge-std@1.9.4/src/'],
  },
} as const satisfies HardhatUserConfig

export default config
