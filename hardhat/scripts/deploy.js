const { ethers } = require("hardhat")
const { CRYPTO_NFT_CONTRACT_ADDRESS } = require('../constants')

async function main() {
  const FakeNFTMarketplace = await ethers.getContractFactory(
    "FakeNFTMarketplace"
  );
  const fakeNftMarketplace = await FakeNFTMarketplace.deploy();
  // await fakeNftMarketplace;
  console.log("FakeNFTMarketplace deployed to: ", fakeNftMarketplace.target);

  // Now deploy the CryptoDevsDAO contract
  const CryptoDevsDAO = await ethers.getContractFactory("CryptoDevsDAO");
  const cryptoDevsDAO = await CryptoDevsDAO.deploy(
    fakeNftMarketplace.target,
    CRYPTO_NFT_CONTRACT_ADDRESS,
    {
      // This assumes your metamask account has at least 1 ETH in its account
      // Change this value as you want
      value: ethers.utils?.parseEther("0.01"),
    }
  );

  console.log("CryptoDevsDAO deployed to: ", cryptoDevsDAO.target);
}

main().then(() => {
  process.exit(0)
}).catch(err => {
  console.error(err, "--------------");
  process.exit(1)
})