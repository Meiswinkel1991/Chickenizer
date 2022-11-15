const { networkConfig } = require("../helper-hardhat-config")
const { network } = require("hardhat")

module.exports = async ({ getNamedAccounts, deployments }) => {
    const { deploy, log } = deployments
    const { deployer } = await getNamedAccounts()

    const config = networkConfig[network.config.chainId]

    console.log(deployer)
    const args = [
        config.borrowerOperations,
        config.troveManager,
        config.hintHelpers,
        config.sortedTroves,
    ]

    await deploy("CHKNStakingPool", {
        from: deployer,
        args: args,
        log: true,
    })
}

module.exports.tags = ["staking", "all"]
