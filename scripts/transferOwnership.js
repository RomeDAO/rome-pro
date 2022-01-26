const { ethers } = require("hardhat");

async function deploy() {
    const factoryStorageAddress = "0x1c945cd9F3627fCa6A9c17Da0a4246dD6f5C1845" // Fixed
    const factoryAddress = "0xcF32e057602DEB5fcc3246fb9b58857527c7717C" // Fixed
    const subsidyAddress = "0xf934C7d48eB2029cfAaDFE7F7a9e26086cE70375" // Fixed
    const daoAddress = "0xD4a7FEbD52efda82d6f8acE24908aE0aa5b4f956" // Fixed
    
    const FactoryStorage = await ethers.getContractFactory("RomeProFactoryStorage");
    const factoryStorage = await FactoryStorage.attach(factoryStorageAddress)

    const RomeProFactory = await ethers.getContractFactory("RomeProFactory");
    const romeProFactory = await RomeProFactory.attach(factoryAddress);

    const SubsidyRouter = await ethers.getContractFactory("RPSubsidyRouter");
    const subsityRouter = await SubsidyRouter.attach(subsidyAddress)

    await factoryStorage.transferManagment(daoAddress)
    await romeProFactory.transferManagment(daoAddress)
    await subsityRouter.transferManagment(daoAddress)

    console.log("Transferred management to: ", daoAddress)
}

deploy()
.then(() => {})
.catch((error) => {
    console.error(error);
    process.exit(1);
});