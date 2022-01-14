const { ethers } = require("hardhat");

async function deploy() {
    const customBondAddress = ""

    const CustomBond = await ethers.getContractFactory("CustomBond");
    const customBond = await CustomBond.attach(customBondAddress)
    
    const controlVariable = 6000
    const vestingTerm = 32000
    const minimumPrice = 29040
    const maxPayout = 5
    const maxDebt = 5000000000000000
    const initialDebt = 15833333333333

    await customBond.initializeBond(
        controlVariable,
        vestingTerm,
        minimumPrice,
        maxPayout,
        maxDebt,
        initialDebt,
    )
}

deploy()
.then(() => {})
.catch((error) => {
    console.error(error);
    process.exit(1);
});