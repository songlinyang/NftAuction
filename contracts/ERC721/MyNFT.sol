pragma solidity ^0.8;

import {ERC721URIStorage, ERC721} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
contract MyNFT is ERC721URIStorage {
    uint256 private _nextTokenId;

    constructor(string memory name, string memory symbol) ERC721(name, symbol) {
        _nextTokenId = 1; // 开始tokenId从1开始
    }
    function mint(address to, uint256 tokenId) public {
        _mint(to, tokenId);
    }

    function awardItem(address player, string memory tokenURI) public returns (uint256) {
        uint256 tokenId = _nextTokenId++;
        _mint(player, tokenId);
        _setTokenURI(tokenId, tokenURI);

        return tokenId;
    }
    

}