//SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

/**
 * DO NOT USE THIS ON PRODUCTION
 */
contract MockedNFT is ERC721 {
    uint256 public maxSupply;
    string public baseURI;

    struct NFT {
        uint256 id;
    }

    NFT[] private _nfts;

    constructor(
        string memory name,
        string memory symbol
    ) ERC721(name, symbol) {}

    function mint(uint256 amount) public {
        for (uint i = 0; i < amount; i++) {
            uint nftId = _createNFT();
            _safeMint(msg.sender, nftId);
        }
    }

    function _createNFT() private returns (uint256) {
        uint256 id = _nfts.length;
        _nfts.push(NFT(id));

        return id;
    }
}