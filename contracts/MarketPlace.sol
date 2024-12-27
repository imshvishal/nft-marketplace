//SPDX-License-Identifier: MIT

pragma solidity ^0.8.22;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./NFTToken.sol";

contract FireNFTMarketPlace {
    ERC20 private token;
    address payable owner;
    uint256 public listingPrice = 0.0025 ether;
    uint public commissionPercent;
    uint256 public itemSold;

    constructor(
        address erc20token,
        uint256 _listingPrice,
        uint _commissionPercent
    ) {
        listingPrice = _listingPrice;
        commissionPercent = _commissionPercent;
        owner = payable(msg.sender);
        token = ERC20(erc20token);
    }

    struct NFTListing {
        address payable seller;
        address contractAddress;
        uint256 tokenId;
        uint256 price;
        string nftURI;
        bool isListed;
    }

    mapping(address => mapping(uint256 => NFTListing)) public nftListing;

    modifier isOwner() {
        require(msg.sender == owner, "You are not the owner of this contract");
        _;
    }

    function updateListingPrice(uint256 newPrice) public isOwner {
        listingPrice = newPrice;
    }

    function mintNFT(
        address nftContract,
        string memory nftURI
    ) public returns (uint256) {
        NFTToken nftToken = NFTToken(nftContract);
        uint256 tokenId = nftToken.createNFT(nftURI);
        nftListing[nftContract][tokenId] = NFTListing(
            payable(msg.sender),
            nftContract,
            tokenId,
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
            nftListing[nftContract][tokenId].isListed == false,
            "NFT is already listed"
        );
        require(
            NFTToken(nftContract).getOwner(tokenId) == msg.sender,
            "You are not the owner of this NFT"
        );
        require(sellingPrice > 0, "Selling Price should be greater than 0");
        nftListing[nftContract][tokenId] = NFTListing(
            payable(msg.sender),
            nftContract,
            tokenId,
            sellingPrice,
            NFTToken(nftContract).tokenURI(tokenId),
            true
        );
    }

    function unlist(address nftContract, uint256 tokenId) public {
        require(
            nftListing[nftContract][tokenId].seller == msg.sender,
            "You are not the seller of this NFT"
        );
        require(
            nftListing[nftContract][tokenId].isListed == false,
            "NFT is not listed"
        );
        nftListing[nftContract][tokenId].isListed = false;
    }

    function buyNft(address nftContractAddr, uint256 tokenId) public payable {
        uint256 sellingPrice = nftListing[nftContractAddr][tokenId].price;
        address seller = nftListing[nftContractAddr][tokenId].seller;
        bool isListed = nftListing[nftContractAddr][tokenId].isListed;

        require(isListed == true, "NFT is not listed");
        require(msg.value >= sellingPrice, "Insufficient funds to buy the nft");
        uint256 commission = (msg.value * commissionPercent) / 100;
        uint256 sellerAmount = msg.value - commission;
        nftListing[nftContractAddr][tokenId].isListed = false;
        nftListing[nftContractAddr][tokenId].seller = payable(msg.sender);
        NFTToken nftContract = NFTToken(nftContractAddr);
        payable(seller).transfer(sellerAmount);
        nftContract.safeTransferFrom(
            nftListing[nftContractAddr][tokenId].seller,
            msg.sender,
            tokenId
        );
    }
}
