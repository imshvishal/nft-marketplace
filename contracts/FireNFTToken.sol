//SPDX-License-Identifier: MIT

pragma solidity ^0.8.22;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

contract FireNFTToken is ERC721URIStorage, Ownable {
    uint256 private _currentTokenId;

    constructor(
        string memory name,
        string memory symbol
    ) ERC721(name, symbol) Ownable(msg.sender) {
        _currentTokenId = 0;
    }

    //user can mint the nft in the cotract without any listing payment but the user will not be able to list them without payment
    function createNFT(
        address _owner,
        string memory tokenURI
    ) external returns (uint256) {
        _safeMint(_owner, ++_currentTokenId);
        _setTokenURI(_currentTokenId, tokenURI);
        return _currentTokenId;
    }

    function getCurrentTokenId() public view returns (uint256) {
        return _currentTokenId;
    }

    function deleteNFT(uint256 tokenId) public {
        require(
            ownerOf(tokenId) == msg.sender,
            "You are not the owner of this NFT"
        );
        _burn(tokenId);
    }
}
