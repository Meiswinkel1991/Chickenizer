const { network, ethers, getNamedAccounts, deployments } = require("hardhat")
const { loadFixture } = require("@nomicfoundation/hardhat-network-helpers")
const { networkConfig, developmentChains } = require("../../helper-hardhat-config")

const { utils } = ethers

!developmentChains.includes(network.name)
    ? describe.skip
    : describe("Staking Pool Tests", async function () {
          //set log level to ignore non errors
          ethers.utils.Logger.setLogLevel(ethers.utils.Logger.levels.ERROR)

          // We define a fixture to reuse the same setup in every test.
          // We use loadFixture to run this setup once, snapshot that state,
          // and reset Hardhat Network to that snapshot in every test.
          async function deployAPIConsumerFixture() {
              const [deployer] = await ethers.getSigners()

              const chainId = network.config.chainId

              await deployments.fixture(["all"])

              const stakingPool = await ethers.getContract("CHKNStakingPool", deployer)

              const hintHelpersAddress = networkConfig[chainId].hintHelpers

              const hintHelpers = await ethers.getContractAt("IHintHelpers", hintHelpersAddress)

              return { stakingPool, deployer, hintHelpers }
          }

          describe("#openTrove", async function () {
              it("successfully open a trove", async () => {
                  const { stakingPool, deployer, hintHelpers } = await loadFixture(
                      deployAPIConsumerFixture
                  )

                  console.log(deployer)

                  const tx = await deployer.sendTransaction({
                      to: stakingPool.address,
                      value: ethers.utils.parseEther("4.0"),
                  })

                  await tx.wait()

                  const balance = await ethers.provider.getBalance(stakingPool.address)
                  console.log(`Balance of staking pool: ${utils.formatEther(balance)}`)

                  //   await stakingPool.openTrove(
                  //       utils.parseEther("1"),
                  //       utils.parseEther("2"),
                  //       utils.parseEther("0.05")
                  //   )

                  //   await stakingPool._getHints(23032032300)

                  const test = await hintHelpers.getApproxHint(1234, 123, 42)

                  console.log(test)
              })
          })
      })
