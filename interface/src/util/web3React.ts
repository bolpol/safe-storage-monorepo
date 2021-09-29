import {InjectedConnector} from '@web3-react/injected-connector'
import {defaultChainId} from "../config";
import {Web3Provider} from "@ethersproject/providers";
import { BscConnector } from '@binance-chain/bsc-connector'

export enum ConnectorNames {
    Injected = "injected",
    WalletConnect = "walletconnect",
    BSC = "bsc",
}

const injected = new InjectedConnector({ supportedChainIds: [defaultChainId] })

const bscConnector = new BscConnector({ supportedChainIds: [56, 97] })

export const connectorsByName: {[connectorName in ConnectorNames | string]: any} = {
    [ConnectorNames.Injected]: injected,
    [ConnectorNames.BSC]: bscConnector,
}

export const getLibrary = (provider: any): Web3Provider => {
    const library = new Web3Provider(
        provider,
        typeof provider.chainId === 'number'
            ? provider.chainId
            : typeof provider.chainId === 'string'
            ? parseInt(provider.chainId)
            : 'any'
    )
    library.pollingInterval = 15_000
    return library
}