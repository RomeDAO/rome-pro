import { HardhatRuntimeEnvironment } from "hardhat/types"
import { DeployFunction } from "hardhat-deploy/types"

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const { deployments, getNamedAccounts } = hre
  const { deploy, execute, getOrNull, get, log} = deployments
  const { deployer, DAO, OPS } = await getNamedAccounts()

  const treasury = '0x8fC24f27DA82701Fdc90460d74cB2E3dC4617f0e';
  const payout = '0x10010078a54396F62c96dF8532dc2B4847d47ED3';
  const principle = '0xdF1d4C921Fe6a04eF086b4191E8742eCfbDAa355';
  const romeTreasury = '0xD4a7FEbD52efda82d6f8acE24908aE0aa5b4f956';
  const romeSubsidy = '0x65101AfADE7fE6503E33a895973c954A1F64B49C';
  const initOwner = '0xBf3bD01bd5fB28d2381d41A8eF779E6aa6f0a811';
  const romeDao = '0x2c05531aF9b0Aaf8B61fc676D9eC9CFCce0eE2A2';
  const tierCeilings = '[100000000000000000000000000]';
  const fees = '[33300]';

  await hre.run("verify", {
    address: '0xc991872013f7530346b1CDb071a2932e94dFba56',
    constructorArgs: [treasury,payout,principle,romeTreasury,romeSubsidy,initOwner,romeDao,tierCeilings,fees]
  })

}
export default func
func.tags = ["verifyBond"]