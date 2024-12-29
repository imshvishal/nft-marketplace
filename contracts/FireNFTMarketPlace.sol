//SPDX-License-Identifier: MIT

pragma solidity ^0.8.22;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./FireNFTToken.sol";

import "hardhat/console.sol";
contract FireNFTMarketPlace is Ownable {
    ERC20 private token;
    uint256 public listingPrice = 0.0025 ether;
    uint public commissionPercent;
    uint public royaltyPercent;
    uint256 public itemSold;

    constructor(address erc20token) Ownable(msg.sender) {
        token = ERC20(erc20token);
    }

    struct NFTListing {
        uint256 price;
        string nftURI;
        bool isListed;
    }

    mapping(address => mapping(address => mapping(uint256 => NFTListing)))
        public nftListing;

    function updateListingPrice(uint256 newPrice) public onlyOwner {
        listingPrice = newPrice;
    }

    function updateCommissionPercent(
        uint newCommissionPercent
    ) public onlyOwner {
        commissionPercent = newCommissionPercent;
    }

    function updateRoyaltyPercent(uint newRoyaltyPercent) public onlyOwner {
        royaltyPercent = newRoyaltyPercent;
    }

    function mintNFT(
        address nftContract,
        string memory nftURI
    ) public returns (uint256) {
        FireNFTToken nftToken = FireNFTToken(nftContract);
        uint256 tokenId = nftToken.createNFT(msg.sender, nftURI);
        nftListing[msg.sender][nftContract][tokenId] = NFTListing(
            0 ether,
            nftURI,
            false
        );
        return tokenId;
    }

    function listNFT(
        address nftContract,
        uint256 tokenId,
        uint256 sellingPrice
    ) public payable {
        require(msg.value >= listingPrice, "Insufficient listing fee");
        require(
            nftListing[msg.sender][nftContract][tokenId].isListed == false,
            "NFT is already listed"
        );
        require(
            FireNFTToken(nftContract).ownerOf(tokenId) == msg.sender,
            "You are not the owner of this NFT"
        );
        require(sellingPrice > 0, "Selling Price should be greater than 0");
        nftListing[msg.sender][nftContract][tokenId] = NFTListing(
            sellingPrice,
            FireNFTToken(nftContract).tokenURI(tokenId),
            true
        );
    }

    function unlist(address nftContract, uint256 tokenId) public {
        require(
            ERC721(nftContract).ownerOf(tokenId) == msg.sender,
            "You are not the owner of this NFT"
        );
        require(
            nftListing[msg.sender][nftContract][tokenId].isListed == false,
            "NFT is not listed"
        );
        nftListing[msg.sender][nftContract][tokenId].isListed = false;
    }

    function buyWithNative(
        address nftContractAddr,
        uint256 tokenId
    ) public payable returns (bool) {
        FireNFTToken nftContract = FireNFTToken(nftContractAddr);
        address nftOwner = nftContract.ownerOf(tokenId);
        uint256 sellingPrice = nftListing[nftOwner][nftContractAddr][tokenId]
            .price;
        bool isListed = nftListing[nftOwner][nftContractAddr][tokenId].isListed;
        require(isListed == true, "NFT is not listed");
        require(msg.value >= sellingPrice, "Insufficient funds to buy the nft");
        uint256 commission = (msg.value * commissionPercent) / 100;
        uint256 sellerAmount = msg.value - commission;
        //move to recepeint
        nftListing[msg.sender][nftContractAddr][tokenId] = nftListing[nftOwner][
            nftContractAddr
        ][tokenId];
        delete nftListing[nftOwner][nftContractAddr][tokenId];
        nftListing[msg.sender][nftContractAddr][tokenId].isListed = false;
        payable(nftContract.ownerOf(tokenId)).transfer(sellerAmount);
        nftContract.transferFrom(
            nftContract.ownerOf(tokenId),
            msg.sender,
            tokenId
        );
        return true;
    }
}
