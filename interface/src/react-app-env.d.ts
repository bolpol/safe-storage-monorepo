/// <reference types="react-scripts" />
interface Window {
    ethereum?: {
        isMetaMask?: true
        on?: (...args: any[]) => void
        removeListener?: (...args: any[]) => void
    }
    web3?: any
}

interface WindowChain {
    ethereum?: {
        isMetaMask?: true
        request?: (...args: any[]) => void
    }
}
