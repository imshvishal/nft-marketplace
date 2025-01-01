const { fireToken, nftToken, marketPlace } = require("../contractInfo.json")
const hre = require("hardhat");

async function main() {
    const [owner, user1] = await hre.ethers.getSigners();
    console.log("OWNER: ", owner.address);
    console.log("USER1: ", user1.address);
    const fireTokenCtr = await hre.ethers.getContractAt("FireToken", fireToken);
    const fireNFTTokenCtr = await hre.ethers.getContractAt("FireNFTToken", nftToken);
    const fireNFTMarketPlaceCtr = await hre.ethers.getContractAt("FireNFTMarketPlace", marketPlace);
    console.log("FireToken Contract: ", fireTokenCtr.target);
    console.log("FireNFTToken Contract: ", fireNFTTokenCtr.target);
    console.log("FireNFTMarketPlace Contract: ", fireNFTMarketPlaceCtr.target);
    const tokenId = await fireNFTTokenCtr.createNFT("https://krvishal.xyz/static/vishal.png");
    console.log(tokenId);
    console.log("Latest Token: ", await fireNFTTokenCtr.getCurrentTokenId());

}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
})