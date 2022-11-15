const { networkConfig } = require("../helper-hardhat-config")

task("trove-count", "Counting all trove owner", async () => {
    const network = hre.network

    const troveManagerAddress = networkConfig[network.config.chainId].troveManager
    console.log(`Address of troveManager: ${troveManagerAddress}`)

    const troveManager = await hre.ethers.getContractAt("ITroveManager", troveManagerAddress)

    const countTroves = await troveManager.getTroveOwnersCount()

    console.log(`The number of troves: ${countTroves}`)
})

module.exports = {}
