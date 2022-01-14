const { ethers } = require("hardhat");

async function deploy() {
    const factoryAddress = "0xcF32e057602DEB5fcc3246fb9b58857527c7717C" // Fixed
    const daoAddress = "0xD4a7FEbD52efda82d6f8acE24908aE0aa5b4f956" // Fixed
    const payoutTokenAddress = ""
    const principleAddress = ""

    const RomeProFactory = await ethers.getContractFactory("RomeProFactory");
    const romeProFactory = await RomeProFactory.attach(factoryAddress);
    
    const tierCeilings = [1]
    const fees = [0.033 * 10 ** 6]
    const treasuryAndBond = await romeProFactory.createBondAndTreasury(payoutTokenAddress, principleAddress, daoAddress, tierCeilings, fees)
    
    console.log("Treasury address: ", treasuryAndBond[0])
    console.log("Bond address: ", treasuryAndBond[1])
}

deploy()
.then(() => process.exit(0))
.catch((error) => {
    console.error(error);
    process.exit(1);
});