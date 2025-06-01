// @ts-check
import antfu from '@antfu/eslint-config'

export default antfu(
  {
    type: 'lib',
    pnpm: true,
  },
  {
    rules: {
      'test/no-import-node-test': 'off',
      'no-console': 'off',
    },
  },
)
