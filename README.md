### Compile
npx hardhat compile

### Start a local node
npx hardhat node

### Deploy to a local node
npx hardhat run --network localhost dev-scripts/deploy.js
npx hardhat run --network localhost dev-scripts/initCustomTreasuryAndBond.js

### Deploy to Moonbeam Alpha
npx hardhat run --network moonbeam dev-scripts/deploy.js

### Deploy to Moonriver
npx hardhat run --network moonriver scripts/deploy.js

### Create treasury & bond
npx hardhat run --network moonriver scripts/initCustomTreasuryAndBond.js

### Create bond
npx hardhat run --network moonriver scripts/initCustomBond.js

### Set bond terms
npx hardhat run --network moonriver scripts/initCustomBondTerms.js