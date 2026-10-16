import { createAppKit } from '@reown/appkit/react'
import { WagmiAdapter } from '@reown/appkit-adapter-wagmi'
import { sepolia } from '@reown/appkit/networks'

const projectId = import.meta.env.VITE_REOWN_PROJECT_ID

if (!projectId) {
  throw new Error('Reown Project ID is missing. Check your frontend/.env file.')
}

const networks = [sepolia]

const metadata = {
  name: 'TrustLance',
  description: 'TrustLance Web3 Freelance Marketplace',
  url: 'http://localhost:5173',
  icons: [],
}

export const wagmiAdapter = new WagmiAdapter({
  networks,
  projectId,
})

export const appKit = createAppKit({
  adapters: [wagmiAdapter],
  networks,
  projectId,
  metadata,
  features: {
    analytics: false,
  },
  themeMode: 'dark',
})