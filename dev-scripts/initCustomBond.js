const { ethers } = require("hardhat");

async function deploy() {
    await ethers.getContract("RomeProFactory")
}

deploy()
.then(() => process.exit(0))
.catch((error) => {
    console.error(error);
    process.exit(1);
});