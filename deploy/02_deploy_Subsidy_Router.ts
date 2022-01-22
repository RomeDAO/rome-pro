import { HardhatRuntimeEnvironment } from "hardhat/types"
import { DeployFunction } from "hardhat-deploy/types"

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const { deployments, getNamedAccounts } = hre
  const { deploy, getOrNull } = deployments
  const { deployer } = await getNamedAccounts()

  let storage = await getOrNull("RPSubsidyRouter")
  if (!storage) {
    await deploy("RPSubsidyRouter", {
      from: deployer,
      log: true,
      skipIfAlreadyDeployed: true,
    })
  }
}
export default func
func.tags = ["RPSubsidyRouter"]
