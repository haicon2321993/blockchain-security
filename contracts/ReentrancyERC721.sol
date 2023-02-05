//SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * DO NOT USE THIS ON PRODUCTION
 */
contract VulnerableMintERC721Reentrancy is Ownable, ERC721Enumerable {
    uint256 public MAX_NFT_SUPPLY = 10000;
    uint256 public MAX_PER_USER = 20;

    constructor(
        string memory name,
        string memory symbol
    ) ERC721(name, symbol) {
    }

    function mint(uint256 amount) public {
        require(totalSupply() < MAX_NFT_SUPPLY, "NFTBox: Max supply exceeded");
        require(amount > 0, "NFTBox: Invalid amount");
        require(amount <= MAX_PER_USER, "NFTBox: Rate limit exceeded");
        require(totalSupply() + amount <= MAX_NFT_SUPPLY, "NFTBox: sold out");

        for (uint i = 0; i < amount; i++) {
            uint256 mintIndex = totalSupply();
            _safeMint(msg.sender, mintIndex);
        }
    }

    receive() external payable {}
    fallback() external payable {}
}