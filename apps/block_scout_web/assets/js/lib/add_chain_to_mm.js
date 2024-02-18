import 'bootstrap'

export async function addChainToMM ({ btn }) {
  try {
    const chainID = await window.ethereum.request({ method: 'eth_chainId' })
    const chainIDFromEnvVar = parseInt(process.env.CHAIN_ID || "10000")
    const chainIDHex = chainIDFromEnvVar && `0x${chainIDFromEnvVar.toString(16)}`
    const blockscoutURL = location.protocol + '//' + location.host + (process.env.NETWORK_PATH || '/')
    if (chainID !== chainIDHex) {
      await window.ethereum.request({
        method: 'wallet_addEthereumChain',
        params: [{
          chainId: chainIDHex,
          chainName: process.env.SUBNETWORK || "SmartBCH",
          nativeCurrency: {
            name: process.env.COIN_NAME || "SmartBCH",
            symbol: process.env.COIN_NAME || "SBCH",
            decimals: 18
          },
          rpcUrls: [process.env.JSON_RPC || "https://smartbch.fountainhead.cash/mainnet"],
          blockExplorerUrls: [blockscoutURL]
        }]
      })
    } else {
      btn.tooltip('dispose')
      btn.tooltip({
        title: `You're already connected to ${process.env.SUBNETWORK || "SmartBCH"}`,
        trigger: 'click',
        placement: 'bottom'
      }).tooltip('show')

      setTimeout(() => {
        btn.tooltip('dispose')
      }, 3000)
    }
  } catch (error) {
    console.error(error)
  }
}
