const { ethers } = require("hardhat");

async function deploy() {
    const [deployer, mockDAO] = await ethers.getSigners();

    // Deploy ROME
    const Rome = await ethers.getContractFactory('RomeERC20Token');
    const rome = await Rome.deploy();
    await rome.deployed()

    console.log("MockRome deployed to:", rome.address);

    // Deploy FRAX
    const Frax = await ethers.getContractFactory('FRAX');
    const frax = await Frax.deploy(0);
    await frax.deployed()

    await frax.mint( deployer.address, '1000000000' );

    console.log("MockFrax deployed to:", frax.address);

    // Deploy Treasury
    const Treasury = await ethers.getContractFactory('MockRomeTreasury'); 
    const treasury = await Treasury.deploy( rome.address, frax.address, 0 );
    await treasury.deployed()

    console.log("MockRomeTreasury deployed to:", treasury.address);

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
        treasury.address, //Rome treasury address
        romeProFactoryStorage.address, 
        rpSubsidyRouter.address, 
        mockDAO.address //RomeDao adddress
    );
    await romeProFactory.deployed();

    console.log("RomeProFactory deployed to:", romeProFactory.address);

    const PayoutToken = await ethers.getContractFactory("mockWMOVR")
    const payoutToken = await PayoutToken.deploy()
    await payoutToken.deployed()

    console.log("PayoutToken deployed to: ", payoutToken.address)

    await romeProFactoryStorage.setFactoryAddress(romeProFactory.address)

    const tierCeilings = [BigInt(1000 * 10 ** 18), BigInt(2000 * 10 ** 18)]
    const fees = [0.033 * 10 ** 6, 0.066 * 10 ** 6]
    await romeProFactory.createBondAndTreasury(payoutToken.address, frax.address, mockDAO.address, tierCeilings, fees)
}

deploy()
.then(() => process.exit(0))
.catch((error) => {
    console.error(error);
    process.exit(1);
});