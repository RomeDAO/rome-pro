const { ethers } = require("hardhat");

async function deploy() {
    const [deployer, mockDAO] = await ethers.getSigners();

    // Deploy ROME
    const ROME = await ethers.getContractFactory('RomeERC20Token');
    const rome = await ROME.deploy();
    await rome.deployed()

    // Deploy FRAX
    const Frax = await ethers.getContractFactory('FRAX');
    const frax = await Frax.deploy(0);
    await frax.deployed()

    await frax.mint( deployer.address, '1000000000' );

    // Deploy Treasury
    const Treasury = await ethers.getContractFactory('MockRomeTreasury'); 
    const treasury = await Treasury.deploy( rome.address, frax.address, 0 );
    await treasury.deployed()

    const RomeProFactoryStorage = await ethers.getContractFactory("RomeProFactoryStorage");
    const romeProFactoryStorage = await RomeProFactoryStorage.deploy();
    await romeProFactoryStorage.deployed()

    const RPSubsidyRouter = await ethers.getContractFactory("RPSubsidyRouter");
    const rpSubsidyRouter = await RPSubsidyRouter.deploy();
    await rpSubsidyRouter.deployed()

    const RomeProFactory = await ethers.getContractFactory("RomeProFactory");
    const romeProFactory = await RomeProFactory.deploy(
        treasury.address, //Rome treasury address
        romeProFactoryStorage.address, 
        rpSubsidyRouter.address, 
        mockDAO.address //RomeDao adddress
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