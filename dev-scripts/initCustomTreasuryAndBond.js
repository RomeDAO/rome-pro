const { ethers } = require("hardhat");

async function deploy() {
    const [deployer, mockDAO] = await ethers.getSigners();

    const PayoutToken = await ethers.getContractFactory("mockWMOVR")
    const payoutToken = await PayoutToken.deploy()
    await payoutToken.deployed()

    console.log("PayoutMovr deployed to: ", payoutToken.address)

    // Deploy Principle
    const PrincipleToken = await ethers.getContractFactory('FRAX');
    const principleToken = await PrincipleToken.deploy(0);
    await principleToken.deployed()

    await principleToken.mint( deployer.address, '1000000000' );

    console.log("PrincipleFrax deployed to:", principleToken.address);

    const factoryAddress = "0xDC11f7E700A4c898AE5CAddB1082cFfa76512aDD"
    const factoryStorageAddress = "0x2E2Ed0Cfd3AD2f1d34481277b3204d807Ca2F8c2"
    const payoutTokenAddress = payoutToken.address
    const principleAddress = principleToken.address
    const daoAddress = mockDAO.address

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