const { ethers } = require("hardhat");

async function deploy() {

    // Deploy Generic Bonding Calculator
    const GenericBondingCalculator = await ethers.getContractFactory('GenericBondingCalculator');
    const genericBondingCalculator = await GenericBondingCalculator.deploy();
    await genericBondingCalculator.deployed()

    console.log("GenericBondingCalculator deployed to:", genericBondingCalculator.address);

    const RomeProFactoryStorage = await ethers.getContractFactory("RomeProFactoryStorage");
    const romeProFactoryStorage = await RomeProFactoryStorage.deploy();
    await romeProFactoryStorage.deployed()

    console.log("RomeProFactoryStorage deployed to:", romeProFactoryStorage.address);

    const RPSubsidyRouter = await ethers.getContractFactory("RPSubsidyRouter");
    const rpSubsidyRouter = await RPSubsidyRouter.deploy();
    await rpSubsidyRouter.deployed()

    console.log("RPSubsidyRouter deployed to:", rpSubsidyRouter.address);

    const RomeProFactory = await ethers.getContractFactory("RomeProFactory");
    const romeProFactory = await RomeProFactory.deploy(
        "0xfbAD41e4Dd040BC80c89FcC6E90d152A746139aF", //Rome treasury address
        romeProFactoryStorage.address, 
        rpSubsidyRouter.address, 
        "0xD4a7FEbD52efda82d6f8acE24908aE0aa5b4f956" //RomeDao adddress
    );
    await romeProFactory.deployed();

    await romeProFactoryStorage.setFactoryAddress(romeProFactory.address);

    console.log("RomeProFactory deployed to:", romeProFactory.address);
}

deploy()
.then(() => process.exit(0))
.catch((error) => {
    console.error(error);
    process.exit(1);
});