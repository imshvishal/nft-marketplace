const hre = require("hardhat");
const { expect } = require("chai");

async function main() {
    const [owner, user1] = await hre.ethers.getSigners();
    console.log(owner.address, user1.address);

    const erc20ctr = await hre.ethers.getContractFactory("FireToken");
    const erc721ctr = await hre.ethers.getContractFactory("FireNFTToken");
    const marketctr = await hre.ethers.getContractFactory("FireNFTMarketPlace");
    const fireToken = await erc20ctr.deploy()
    console.log("FireToken deployed to:", fireToken.target);
    const nftToken = await erc721ctr.deploy("Vishal", "VIS")
    console.log("FireNFTToken deployed to:", nftToken.target);
    const marketPlace = await marketctr.deploy(fireToken.target)
    console.log("FireNFTMarketPlace deployed to:", marketPlace.target);
    await nftToken.setApprovalForAll(marketPlace.target, true);
    let val = await marketPlace.mintNFT(nftToken.target, "https://krvishal.xyz/static/vishal.png")
    await val.wait()
    val = await marketPlace.listNFT(nftToken.target, 1, 1000000, { value: 2500000000000000 })
    await val.wait()
    val = await marketPlace.nftListing(owner, nftToken.target, 1)
    console.log("OWNER: ", await nftToken.ownerOf(1));
    // console.log("BALANCE: ", await marketPlace();
    await marketPlace.connect(user1).buyWithNative(nftToken.target, 1, { value: val.price, })
    console.log("OWNER: ", await nftToken.ownerOf(1));
}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
})