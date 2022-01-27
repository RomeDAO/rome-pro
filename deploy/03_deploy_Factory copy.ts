import { HardhatRuntimeEnvironment } from "hardhat/types"
import { DeployFunction } from "hardhat-deploy/types"

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const { deployments, getNamedAccounts } = hre
  const { deploy, execute, getOrNull, get, log} = deployments
  const { deployer, DAO, OPS } = await getNamedAccounts()

  let storage = await getOrNull("RomeProFactory")
  if (!storage) {
    await deploy("RomeProFactory", {
      args: [
        DAO,
        (await get("RomeProFactoryStorage")).address,
        (await get("RPSubsidyRouter")).address,
        OPS
      ],
      from: deployer,
      log: true,
      skipIfAlreadyDeployed: true,
    })
    
    await execute(
      "RomeProFactoryStorage",
      { from: deployer, log: true },
      "setFactoryAddress",
      (await get("RomeProFactory")).address,
    )
  }
}
export default func
func.tags = ["RomeProFactory"]
func.dependencies = ["RomeProFactoryStorage", "RPSubsidyRouter"]
