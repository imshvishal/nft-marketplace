const { expect } = require("chai");
const hre = require("hardhat")

describe("NFTMarketPlace", function () {
  let owner, user1, user2, fireToken, fireNFTToken, marketPlaceCtr;
  this.beforeAll(async function () {
    [owner, user1, user2] = await hre.ethers.getSigners();
    fireToken = await hre.ethers.getContractFactory("FireToken");
    fireToken = await fireToken.deploy()
    fireNFTToken = await hre.ethers.getContractFactory("FireNFTToken");
    fireNFTToken = await fireNFTToken.deploy("5ireNFT", "5IT");
    marketPlaceCtr = await hre.ethers.getContractFactory("FireNFTMarketPlace");
    marketPlaceCtr = await marketPlaceCtr.deploy(fireToken.target);

  })

  describe("ERC20 Token contract", function () {
    it("Deployment and tokens minted to the owner", async function () {
      const ownerBalance = await fireToken.balanceOf(owner.address);
      expect(await fireToken.totalSupply()).to.equal(ownerBalance);
    });
    it("Checking name", async function () {
      expect(await fireToken.name()).to.equal("FireToken");
    })
    it("Checking symbol", async function () {
      expect(await fireToken.symbol()).to.equal("FIRE");
    })
    it("Transferring balance", async function () {
      await fireToken.transfer(user1, 2000000000)
      expect(await fireToken.balanceOf(user1)).to.equal(2000000000)
    })
    it("Checking allowance", async function () {
      await fireToken.approve(marketPlaceCtr.target, 5000000)
      expect(await fireToken.allowance(owner, marketPlaceCtr.target)).to.equal(5000000)
    })
  });

  describe("ERC721 Token Contract", function () {
    it("Deployed", async () => {
      expect(await fireNFTToken.owner()).to.equal(owner)
    })
    it("Check token name", async () => {
      expect(await fireNFTToken.name()).to.equal("5ireNFT");
    })
    it("Check token symbol", async () => {
      expect(await fireNFTToken.symbol()).to.equal("5IT");
    })
    it("Minting NFT", async () => {
      await fireNFTToken.createNFT("https://krvishal.xyz/static/vishal.png")
      expect(await fireNFTToken.getCurrentTokenId()).to.equal(1)
    })
    it("Checking owner of NFT", async () => {
      expect(await fireNFTToken.ownerOf(1)).to.equal(owner)
    })
    it("Approving NFT for opeartor", async () => {
      await fireNFTToken.approve(marketPlaceCtr.target, 1)
      expect(await fireNFTToken.getApproved(1)).to.equal(marketPlaceCtr.target)
    })
  })

  describe("MarketPlace Contract", function () {
    it("Deployed", async () => {
      expect(await marketPlaceCtr.owner()).to.equal(owner)
    })
    it("Adding NFT to marketplace", async () => {
      await marketPlaceCtr.addNFTtoMarketPlace(fireNFTToken.target, await fireNFTToken.getCurrentTokenId())
      expect(await marketPlaceCtr.getNFTCount()).to.equal(1)
    })
    it("Checking nft info", async () => {
      let nft = (await marketPlaceCtr.getNFT(1));
      expect(nft.isListed).to.equal(false)
      expect(nft.owner).to.equal(owner)
      expect(nft.price).to.equal(0)
      expect(nft.seller).to.equal(hre.ethers.ZeroAddress)
    })
    it("Deny listing without balance (erc20)", async () => {
      await expect(marketPlaceCtr.listNFTWithERC20(1, 2000000)).to.be.revertedWith("Not enough funds approved");
    })
    it("Deny listing balance (native)", async () => {
      await expect(marketPlaceCtr.listNFTWithNative(1, 2000000)).to.be.revertedWith("Insufficient balance")
    })
    it("Deny Buying NFT without Listing", async () => {
      await expect(marketPlaceCtr.connect(user1).buyWithNative(1, { value: hre.ethers.parseEther("0.0025") })).to.be.revertedWith("NFT not listed")
    })
    it("Listing NFT with ERC20", async () => {
      await fireToken.approve(marketPlaceCtr.target, hre.ethers.parseEther("0.0025"))
      await marketPlaceCtr.listNFTWithERC20(1, 2000000)
      let nft = (await marketPlaceCtr.getNFT(1));
      expect(nft.isListed).to.equal(true)
      expect(nft.owner).to.equal(owner)
      expect(nft.price).to.equal(2000000)
      expect(nft.seller).to.equal(owner)
    })
    it("Unlisting NFT", async () => {
      await marketPlaceCtr.unlistNFT(1)
      let nft = (await marketPlaceCtr.getNFT(1));
      expect(nft.isListed).to.equal(false)
      expect(nft.owner).to.equal(owner)
      expect(nft.price).to.equal(0)
      expect(nft.seller).to.equal(hre.ethers.ZeroAddress)
    })
    it("Listing NFT with Native", async () => {
      await marketPlaceCtr.listNFTWithNative(1, 2000000, { value: hre.ethers.parseEther("0.0025") })
      let nft = (await marketPlaceCtr.getNFT(1));
      expect(nft.isListed).to.equal(true)
      expect(nft.owner).to.equal(owner)
      expect(nft.price).to.equal(2000000)
      expect(nft.seller).to.equal(owner)
    })
    it("Setting commission", async () => {
      await marketPlaceCtr.updateCommissionPercent(10)
      expect(await marketPlaceCtr.commissionPercent()).to.equal(10)
    })
    it("Checking native balance in marketplace after listing", async () => {
      expect(await hre.ethers.provider.getBalance(marketPlaceCtr.target)).to.equal(hre.ethers.parseEther("0.0025"))
    })
    it("Checking erc20 balance in marketplace after listing", async () => {
      expect(await fireToken.balanceOf(marketPlaceCtr.target)).to.equal(hre.ethers.parseEther("0.0025"))
    })
    it("Buying NFT with Native", async () => {
      await fireNFTToken.approve(marketPlaceCtr.target, 1)
      await marketPlaceCtr.connect(user1).buyWithNative(1, { value: hre.ethers.parseEther("0.0025") })
      let nft = (await marketPlaceCtr.getNFT(1));
      expect(nft.isListed).to.equal(false)
      expect(nft.owner).to.equal(owner)
      expect(nft.price).to.equal(0)
      expect(nft.seller).to.equal(user1)
    })
    it("Checking native balance in marketplace after buying", async () => {
      expect(await hre.ethers.provider.getBalance(marketPlaceCtr.target)).to.equal(0)
    })
  })
})