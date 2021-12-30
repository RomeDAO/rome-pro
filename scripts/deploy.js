const { ethers } = require("hardhat");

async function deploy() {
    const RomeProFactoryStorage = await ethers.getContractFactory("RomeProFactoryStorage");
    const romeProFactoryStorage = await RomeProFactoryStorage.deploy();
    await romeProFactoryStorage.deployed()

    const RPSubsidyRouter = await ethers.getContractFactory("RPSubsidyRouter");
    const rpSubsidyRouter = await RPSubsidyRouter.deploy();
    await rpSubsidyRouter.deployed()

    const RomeProFactory = await ethers.getContractFactory("RomeProFactory");
    const romeProFactory = await RomeProFactory.deploy(
        "", //Rome treasury address
        romeProFactoryStorage.address, 
        rpSubsidyRouter.address, 
        "" //RomeDao adddress
    );
    await romeProFactory.deployed();

    console.log("RomeProFactory deployed to:", romeProFactory.address);
}

deploy()
.then(() => process.exit(0))
.catch((error) => {
    console.error(error);
    process.exit(1);
});