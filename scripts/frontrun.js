require('dotenv').config();
const ethers = require("ethers").ethers
const PRIVATE_KEY = process.env.PRIVATE_KEY
const CONTRACT_ADDRESS = '0x4a6FAAe07dc91B375e60c497901D5BC45659a6e8'
const NFT = '0x6ae94A8acF9d4C94Fe8f1d0777d254C9A9517aA4'
const abi = require('./abi.json')

const one_hour = 60 * 60 * 1000
const price = BigInt(1e18) * BigInt(500)
const sleep = (ms) => {return new Promise(resolve => setTimeout(resolve, ms))}
const wallet = new ethers.Wallet(PRIVATE_KEY, new ethers.providers.JsonRpcProvider(process.env.RPC))
const contract = new ethers.Contract(CONTRACT_ADDRESS, abi, wallet)

const main = async () => {
    console.log('start')
    await listen()
    await sleep(one_hour)
}

// list: 0x949ed5af
// buy: 0x7deb6025
const listen = async () => {
    let wssProvider = new ethers.providers.WebSocketProvider(process.env.WSS_RPC)
    wssProvider.on("pending", (hash) => {
        wssProvider.getTransaction(hash).then((tx) => {
            if (tx && tx.to && tx.to.toLowerCase() === CONTRACT_ADDRESS.toLowerCase()) {
                if (!tx || !tx.data || !tx.data.startsWith('0x7deb6025')) {
                    return
                }

                console.log('someone buy', tx.data)
                // frontrun send update transaction
                let tokenId = tx.data.slice(10, 10 + 64)
                tokenId = parseInt(tokenId, 16)
                console.log(`start frontrun from account ${wallet.address}: Update price for NFT ID: ${tokenId}`)

                contract.updateListingPrice(tokenId, NFT, price, {
                    from: wallet.address,
                    gasPrice: 1e10,
                }).then((tx) => {
                    console.log('new transaction', tx)
                    console.log(new Date(), 'update tx: ', `https://sepolia.etherscan.io/tx/${tx.hash}`)
                }).catch(e => {
                    console.log('error', e)
                })
            }
        })
    })

    wssProvider._websocket.on("open", async () => {
        console.log('Start listening')
    })

    wssProvider._websocket.on("error", async () => {
        console.log(`Unable to connect to, retrying...`)
        await sleep(1000)
        listen()
    })
    wssProvider._websocket.on("close", async (code) => {
        console.log(`Connection lost with code ${code}! Attempting reconnect in 0.02s...`)
        wssProvider._websocket.terminate()

        await sleep(10000)
        listen()
    });
}

main().catch(console.error).finally(() => process.exit())