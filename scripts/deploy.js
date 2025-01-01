const hre = require("hardhat");
const { expect } = require("chai");
const fs = require("fs");

async function main() {
    const [owner] = await hre.ethers.getSigners();
    console.log(owner);
    const erc20ctr = await hre.ethers.getContractFactory("FireToken");
    const erc721ctr = await hre.ethers.getContractFactory("FireNFTToken");
    const marketctr = await hre.ethers.getContractFactory("FireNFTMarketPlace");
    const fireToken = await erc20ctr.deploy()
    console.log("FireToken deployed to:", fireToken.target);
    const nftToken = await erc721ctr.deploy("5ireChain NFTs", "5IT");
    console.log("FireNFTToken deployed to:", nftToken.target);
    const marketPlace = await marketctr.deploy(fireToken.target)
    console.log("FireNFTMarketPlace deployed to:", marketPlace.target);
    fs.writeFileSync("contractInfo.json", JSON.stringify({
        owner: owner.address,
        fireToken: fireToken.target,
        nftToken: nftToken.target,
        marketPlace: marketPlace.target
    }, null, 2));
}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
})