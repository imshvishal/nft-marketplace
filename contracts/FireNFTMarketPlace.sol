//SPDX-License-Identifier: MIT

pragma solidity ^0.8.22;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "./FireNFTToken.sol";

contract FireNFTMarketPlace is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;
    IERC20 private fireToken;
    uint256 public listingPrice = 0.0025 ether;
    uint public commissionPercent;
    uint public royaltyPercent;
    uint256 public itemSold;

    constructor(address erc20token) Ownable(msg.sender) {
        fireToken = IERC20(erc20token);
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
    ) public nonReentrant returns (uint256) {
        FireNFTToken nftToken = FireNFTToken(nftContract);
        uint256 tokenId = nftToken.createNFT(msg.sender, nftURI);
        nftListing[msg.sender][nftContract][tokenId] = NFTListing(
            0 ether,
            nftURI,
            false
        );
        return tokenId;
    }

    function listNFTWithNative(
        address nftContract,
        uint256 tokenId,
        uint256 sellingPrice
    ) external payable returns (bool){
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
        return true;
    }

    function listNFTWithERC20(address nftCtrAddr, uint256 tokenId, uint256 sp) external returns (bool){
        require(fireToken.allowance(msg.sender, address(this)) >= listingPrice, "Not enough funds approved");
        require(
            nftListing[msg.sender][nftCtrAddr][tokenId].isListed == false,
            "NFT is already listed"
        );
        require(
            FireNFTToken(nftCtrAddr).ownerOf(tokenId) == msg.sender,
            "You are not the owner of this NFT"
        );
        fireToken.safeTransferFrom(msg.sender, address(this), listingPrice);
        nftListing[msg.sender][nftCtrAddr][tokenId] = NFTListing(
            sp,
            FireNFTToken(nftCtrAddr).tokenURI(tokenId),
            true
        );
        return true;
    }

    function unlist(address nftContract, uint256 tokenId) public {
        require(
            ERC721(nftContract).ownerOf(tokenId) == msg.sender,
            "You are not the owner of this NFT"
        );
        require(
            nftListing[msg.sender][nftContract][tokenId].isListed == true,
            "NFT is not listed"
        );
        nftListing[msg.sender][nftContract][tokenId].isListed = false;
    }

    function buyWithNative(
        address nftContractAddr,
        uint256 tokenId
    ) external payable returns (bool) {
        FireNFTToken nftContract = FireNFTToken(nftContractAddr);
        address nftOwner = nftContract.ownerOf(tokenId);
        uint256 sellingPrice = nftListing[nftOwner][nftContractAddr][tokenId]
            .price;
        bool isListed = nftListing[nftOwner][nftContractAddr][tokenId].isListed;
        require(isListed == true, "NFT is not listed");
        require(msg.value >= sellingPrice, "Insufficient funds to buy the nft");
        require(nftContract.getApproved(tokenId) == address(this), "NFT is not approved to transfer");
        uint256 commission = (msg.value * commissionPercent) / 100;
        uint256 sellerAmount = msg.value - commission;
        //move to recepeint
        nftListing[msg.sender][nftContractAddr][tokenId] = nftListing[nftOwner][
            nftContractAddr
        ][tokenId];
        delete nftListing[nftOwner][nftContractAddr][tokenId];
        nftListing[msg.sender][nftContractAddr][tokenId].isListed = false;
        payable(nftContract.ownerOf(tokenId)).transfer(sellerAmount);
        nftContract.safeTransferFrom(
            nftContract.ownerOf(tokenId),
            msg.sender,
            tokenId
        );
        return true;
    }

    function buyWithERC20(
        address nftCtrAddr,
        uint256 tokenId
    ) external returns (bool) {
        FireNFTToken nftContract = FireNFTToken(nftCtrAddr);
        address nftOwner = nftContract.ownerOf(tokenId);
        uint256 sellingPrice = nftListing[nftOwner][nftCtrAddr][tokenId].price;
        bool isListed = nftListing[nftOwner][nftCtrAddr][tokenId].isListed;
        require(isListed == true, "NFT is not listed");
        require(
            fireToken.allowance(msg.sender, address(this)) >= sellingPrice,
            "Funds not approved to be transferred"
        );
        uint256 commission = (sellingPrice * commissionPercent) / 100;
        uint256 sellerAmount = sellingPrice - commission;
        fireToken.safeTransferFrom(msg.sender, address(this), commission);
        fireToken.safeTransferFrom(msg.sender, nftOwner, sellerAmount);
        nftListing[msg.sender][nftCtrAddr][tokenId] = nftListing[nftOwner][
            nftCtrAddr
        ][tokenId];
        delete nftListing[nftOwner][nftCtrAddr][tokenId];
        nftListing[msg.sender][nftCtrAddr][tokenId].isListed = false;
        nftContract.safeTransferFrom(
            nftContract.ownerOf(tokenId),
            msg.sender,
            tokenId
        );
        return true;
    }

    function withdrawERCFunds(address addr) external onlyOwner returns (bool) {
        require(
            fireToken.balanceOf(address(this)) > 0,
            "Insufficient funds to withdraw"
        );
        fireToken.safeTransfer(addr, fireToken.balanceOf(address(this)));
        return true;
    }
}
