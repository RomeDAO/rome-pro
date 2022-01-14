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

    const factoryAddress = ""
    const payoutTokenAddress = payoutToken.address
    const principleAddress = frax.address
    const daoAddress = mockDAO

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