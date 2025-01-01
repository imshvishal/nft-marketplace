//SPDX-License-Identifier: MIT

pragma solidity ^0.8.22;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./FireNFTToken.sol";

contract FireNFTMarketPlace is Ownable {
    using SafeERC20 for IERC20;
    IERC20 private fireToken;
    uint256 public listingPrice = 0.0025 ether;
    uint public commissionPercent;
    uint public royaltyPercent;
    uint256 private _items;

    constructor(address erc20token) Ownable(msg.sender) {
        fireToken = IERC20(erc20token);
    }

    struct NFTData {
        uint256 itemId;
        address payable owner;
        address payable seller;
        address nftContract;
        uint256 tokenId;
        string nftURI;
        uint256 price;
        bool isListed;
        uint256 timestamp;
    }

    mapping(uint256 => NFTData) nftListing;

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

    function addNFTtoMarketPlace(
        address _nftCtrAddr,
        uint256 _tokenId
    ) external returns (uint256) {
        // check whether it exisits or not
        require(
            FireNFTToken(_nftCtrAddr).ownerOf(_tokenId) == msg.sender,
            "You are not the owner of token"
        );
        _items++;
        nftListing[_items] = NFTData(
            _items,
            payable(msg.sender),
            payable(address(0)),
            _nftCtrAddr,
            _tokenId,
            FireNFTToken(_nftCtrAddr).tokenURI(_tokenId),
            0,
            false,
            block.timestamp
        );
        return _items;
    }

    function listNFTWithNative(
        uint256 _itemNo,
        uint256 _sellingPrice
    ) external payable returns (bool) {
        NFTData storage nft = nftListing[_itemNo];
        require(
            FireNFTToken(nft.nftContract).ownerOf(nft.tokenId) == msg.sender,
            "You are not the owner of this NFT"
        );
        require(nftListing[_itemNo].isListed == false, "NFT already listed");
        require(msg.value >= listingPrice, "Insufficient balance");
        require(_sellingPrice > 0, "Selling Price should be greater than 0");
        nft.price = _sellingPrice;
        nft.seller = payable(msg.sender);
        nft.isListed = true;
        nft.timestamp = block.timestamp;
        return true;
    }

    function listNFTWithERC20(
        uint256 _itemNo,
        uint256 _sp
    ) external returns (bool) {
        NFTData storage nft = nftListing[_itemNo];
        require(
            FireNFTToken(nft.nftContract).ownerOf(nft.tokenId) == msg.sender,
            "You are not the owner of this NFT"
        );
        require(nftListing[_itemNo].isListed == false, "NFT already listed");
        require(
            fireToken.allowance(msg.sender, address(this)) >= listingPrice,
            "Not enough funds approved"
        );
        fireToken.safeTransferFrom(msg.sender, address(this), listingPrice);
        nft.price = _sp;
        nft.seller = payable(msg.sender);
        nft.isListed = true;
        nft.timestamp = block.timestamp;
        return true;
    }

    function unlistNFT(uint256 _itemNo) public {
        NFTData storage nft = nftListing[_itemNo];
        require(
            FireNFTToken(nft.nftContract).ownerOf(nft.tokenId) == msg.sender,
            "You are not the owner of this NFT"
        );
        require(nftListing[_itemNo].isListed == true, "NFT not listed");
        nft.seller = payable(address(0));
        nft.price = 0;
        nftListing[_itemNo].isListed = false;
    }

    function buyWithNative(uint256 _itemNo) external payable returns (bool) {
        NFTData storage nft = nftListing[_itemNo];
        FireNFTToken nftContract = FireNFTToken(nft.nftContract);
        require(nft.isListed == true, "NFT not listed");
        require(msg.value >= nft.price, "Insufficient funds to buy the nft");
        require(
            nftContract.getApproved(nft.tokenId) == address(this),
            "NFT is not approved to be transferred"
        );
        uint256 commission = (msg.value * commissionPercent) / 100;
        uint256 sellerAmount = msg.value - commission;
        nft.seller = payable(msg.sender);
        nft.isListed = false;
        nft.price = 0;
        payable(nftContract.ownerOf(nft.tokenId)).transfer(sellerAmount);
        nftContract.safeTransferFrom(
            nftContract.ownerOf(nft.tokenId),
            msg.sender,
            nft.tokenId
        );
        return true;
    }

    function buyWithERC20(uint256 _itemNo) external returns (bool) {
        NFTData storage nft = nftListing[_itemNo];
        FireNFTToken nftContract = FireNFTToken(nft.nftContract);
        address nftOwner = nftContract.ownerOf(nft.tokenId);
        require(nft.isListed == true, "NFT not listed");
        require(
            fireToken.allowance(msg.sender, address(this)) >= nft.price,
            "Funds not approved to be transferred"
        );
        require(
            nftContract.getApproved(nft.tokenId) == address(this),
            "NFT not approved to be transferred"
        );
        uint256 commission = (nft.price * commissionPercent) / 100;
        uint256 sellerAmount = nft.price - commission;
        fireToken.safeTransferFrom(msg.sender, address(this), commission);
        fireToken.safeTransferFrom(msg.sender, nftOwner, sellerAmount);
        nft.seller = payable(msg.sender);
        nft.isListed = false;
        nft.price = 0;
        nftContract.safeTransferFrom(
            nftContract.ownerOf(nft.tokenId),
            msg.sender,
            nft.tokenId
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

    function getNFTCount() external view returns (uint256) {
        return _items;
    }

    function getNFT(uint256 _itemNo) external view returns (NFTData memory) {
        return nftListing[_itemNo];
    }

    function getLatestNFT() external view returns (NFTData memory) {
        return nftListing[_items];
    }

    function getAllListedNFTs() external view returns (NFTData[] memory) {
        uint256 listedCount = 0;
        for (uint256 i = 1; i <= _items; i++) {
            if (nftListing[i].isListed) {
                listedCount++;
            }
        }
        NFTData[] memory nftDatas = new NFTData[](listedCount);
        uint256 index = 0;
        for (uint256 i = 1; i <= _items; i++) {
            if (nftListing[i].isListed) {
                nftDatas[index] = nftListing[i];
                index++;
            }
        }
        return nftDatas;
    }

    function getMyCreatedNFTs() external view returns (NFTData[] memory) {
        uint256 listedCount = 0;
        for (uint256 i = 1; i <= _items; i++) {
            if (nftListing[i].owner == msg.sender) {
                listedCount++;
            }
        }
        NFTData[] memory nftDatas = new NFTData[](listedCount);
        uint256 index = 0;
        for (uint256 i = 1; i <= _items; i++) {
            if (nftListing[i].owner == msg.sender) {
                nftDatas[index] = nftListing[i];
                index++;
            }
        }
        return nftDatas;
    }

    function getMyBoughtNFTs() external view returns (NFTData[] memory) {
        uint256 listedCount = 0;
        for (uint256 i = 1; i <= _items; i++) {
            if (
                nftListing[i].seller == msg.sender &&
                nftListing[i].owner != msg.sender
            ) {
                listedCount++;
            }
        }
        NFTData[] memory nftDatas = new NFTData[](listedCount);
        uint256 index = 0;
        for (uint256 i = 1; i <= _items; i++) {
            if (
                nftListing[i].seller == msg.sender &&
                nftListing[i].owner != msg.sender
            ) {
                nftDatas[index] = nftListing[i];
                index++;
            }
        }
        return nftDatas;
    }

    function getMyListedNFTs() external view returns (NFTData[] memory) {
        uint256 listedCount = 0;
        for (uint256 i = 1; i <= _items; i++) {
            if (nftListing[i].isListed && nftListing[i].seller == msg.sender) {
                listedCount++;
            }
        }
        NFTData[] memory nftDatas = new NFTData[](listedCount);
        uint256 index = 0;
        for (uint256 i = 1; i <= _items; i++) {
            if (nftListing[i].isListed && nftListing[i].seller == msg.sender) {
                nftDatas[index] = nftListing[i];
                index++;
            }
        }
        return nftDatas;
    }
}
