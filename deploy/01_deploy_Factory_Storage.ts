import { HardhatRuntimeEnvironment } from "hardhat/types"
import { DeployFunction } from "hardhat-deploy/types"

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const { deployments, getNamedAccounts } = hre
  const { deploy, getOrNull } = deployments
  const { deployer } = await getNamedAccounts()

  let storage = await getOrNull("RomeProFactoryStorage")
  if (!storage) {
    await deploy("RomeProFactoryStorage", {
      from: deployer,
      log: true,
      skipIfAlreadyDeployed: true,
    })
  }
}
export default func
func.tags = ["RomeProFactoryStorage"]
