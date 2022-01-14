const { ethers } = require("hardhat");

async function deploy() {
    const factoryStorageAddress = "0x1c945cd9F3627fCa6A9c17Da0a4246dD6f5C1845" // Fixed
    const factoryAddress = "0xcF32e057602DEB5fcc3246fb9b58857527c7717C" // Fixed
    const daoAddress = "0xD4a7FEbD52efda82d6f8acE24908aE0aa5b4f956" // Fixed
    const payoutTokenAddress = ""
    const principleAddress = ""

    const FactoryStorage = await ethers.getContractFactory("RomeProFactoryStorage");
    const factoryStorage = await FactoryStorage.attach(factoryStorageAddress)

    const RomeProFactory = await ethers.getContractFactory("RomeProFactory");
    const romeProFactory = await RomeProFactory.attach(factoryAddress);
    
    const tierCeilings = [1]
    const fees = [0.033 * 10 ** 6]
    await romeProFactory.createBondAndTreasury(payoutTokenAddress, principleAddress, daoAddress, tierCeilings, fees)
    
    factoryStorage.on("BondCreation", (treasury, bond, initialOwner) => {
        console.log("Custom treasury created at: ", treasury)
        console.log("Custom bond created at: ", bond)
        console.log("Initial owner: ", initialOwner)
    });
}

deploy()
.then(() => {})
.catch((error) => {
    console.error(error);
    process.exit(1);
});