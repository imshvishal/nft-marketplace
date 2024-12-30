# NFT MarketPlace

This project has three contracts which would be helpful for deploying the contracts used for the nft marketplaces.

# Contracts

## 1. FireToken.sol

This contract is an ERC20 contract which can be used as a custom token for the transactions.  
`NOTE: it automatically mints all the tokens initially to the minter upon deployment.`

## 2. FireNFTToken.sol -> FireNFTToken(ERC721URIStorage, Ownable)

This contract would hold all the nfts and multiple instances of this contract could also be deployed to implement the collections.

### Functions:

1. ```sol
    createNFT(address _owner, string memory tokenURI) external returns (uint256)
   ```
   > This function is a helper function which would help the marketplace to mint a new nft into the contract.
2. ```
   deleteNFT(uint256 tokenId) external returns (bool)
   ```
   > This function would delete the nft from the contract.

## 3. FireNFTMarketPlace.sol -> FireNFTMarketPlace(Ownable, ReentrancyGuard)

This contract is the controller of the whole marketplace.

### Functions:
