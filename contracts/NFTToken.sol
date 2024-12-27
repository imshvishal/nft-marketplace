//SPDX-License-Identifier: MIT

pragma solidity ^0.8.22;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract NFTToken is ERC721URIStorage {
    uint256 private _currentTokenId;
    address payable owner;
    constructor(string memory name, string memory symbol) ERC721(name, symbol) {
        owner = payable(msg.sender);
    }

    //user can mint the nft in the cotract without any listing payment but the user will not be able to list them without payment
    function createNFT(string memory tokenURI) public returns (uint256) {
        _safeMint(msg.sender, ++_currentTokenId);
        _setTokenURI(_currentTokenId, tokenURI);
        return _currentTokenId;
    }

    function getCurrentTokenId() public view returns (uint256) {
        return _currentTokenId;
    }

    function getOwner(uint256 tokenId) public view returns (address) {
        return ownerOf(tokenId);
    }

    function deleteNFT(uint256 tokenId) public {
        require(
            ownerOf(tokenId) == msg.sender,
            "You are not the owner of this NFT"
        );
        _burn(tokenId);
    }
}
