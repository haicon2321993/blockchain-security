//SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";

/**
 * DO NOT USE THIS ON PRODUCTION
 */
contract VulnerableMarketplaceFrontrun is ReentrancyGuard, ERC721Holder {
    using SafeERC20 for IERC20;

    struct Offer {
        // The offer currency
        address currency;
        // The offer amount
        uint256 amount;
    }

    struct ListingInfo {
        // The address of the seller
        address tokenOwner;
        // The listing currency
        address currency;
        // The listing price
        uint256 price;
    }

    // A mapping from NFT token to its listing information map[NFTContract][NFTID] => ListingInfo
    mapping(address => mapping(uint256 => ListingInfo)) public tokensOnSale;

    constructor () {}

    function list(uint256 tokenId, address tokenContract, uint256 price, address currency) external nonReentrant {
        address tokenOwner = IERC721(tokenContract).ownerOf(tokenId);
        require(msg.sender == tokenOwner, "Not token owner");
        require(price >= 1e9, "Price is too low");
        require(currency != address(0), "Native token is not allowed");

        IERC721(tokenContract).safeTransferFrom(tokenOwner, address(this), tokenId);
        tokensOnSale[tokenContract][tokenId] = ListingInfo({
            tokenOwner: tokenOwner,
            currency: currency,
            price: price
            });
    }

    function delist(uint256 tokenId, address tokenContract) external nonReentrant {
        ListingInfo storage currentListing = tokensOnSale[tokenContract][tokenId];

        require(currentListing.price > 0, "Not listed");
        require(msg.sender == currentListing.tokenOwner, "Not token owner");

        IERC721(tokenContract).safeTransferFrom(address(this), currentListing.tokenOwner, tokenId);
        delete tokensOnSale[tokenContract][tokenId];
    }

    function updateListingPrice(uint256 tokenId, address tokenContract, uint256 price) external nonReentrant {
        ListingInfo storage currentListing = tokensOnSale[tokenContract][tokenId];

        require(currentListing.price > 0, "Not listed");
        require(msg.sender == currentListing.tokenOwner, "Not token owner");

        currentListing.price = price;
    }

    function buy(uint256 tokenId, address tokenContract) external payable nonReentrant {
        ListingInfo storage currentListing = tokensOnSale[tokenContract][tokenId];
        require(currentListing.price > 0, "Not listed");

        address buyer = msg.sender;
        address seller = currentListing.tokenOwner;
        require(buyer != seller, "Cannot buy your own token");

        // transfer ERC20 fund from buyer to contract
        IERC20(currentListing.currency).safeTransferFrom(buyer, address(this), currentListing.price);
        // transfer ERC20 fund from contract to seller
        IERC20(currentListing.currency).safeTransfer(seller, currentListing.price);
        // transfer ERC721 from contract to buyer
        IERC721(tokenContract).safeTransferFrom(address(this), buyer, tokenId);

        delete tokensOnSale[tokenContract][tokenId];
    }
}