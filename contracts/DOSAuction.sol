//SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";

/**
 * DO NOT USE THIS ON PRODUCTION
 */
contract VulerableAuctionDOS is Ownable, ReentrancyGuard, ERC721Holder {
    using Counters for Counters.Counter;

    struct Auction {
        // ID for the ERC721 token
        uint256 tokenId;
        // Address for the ERC721 contract
        address tokenContract;
        // The time auction End
        uint256 endTime;
        // The address that should receive the funds once the NFT is sold.
        address tokenOwner;
        // The address of the current highest bid
        address bidder;
        // The current highest bid amount
        uint256 amount;
    }

    mapping(uint256 => Auction) public auctions;
    Counters.Counter private _auctionIdTracker;

    constructor () {}

    function createBid(uint256 auctionId) external payable nonReentrant
    {
        address lastBidder = auctions[auctionId].bidder;
        require(block.timestamp < auctions[auctionId].endTime, "Auction expired");
        require(msg.value >= 1e16, "Min Price is 0.01 BNB");
        require(msg.value >= auctions[auctionId].amount, "Must send more than last bid");

        if(lastBidder != address(0)) {
            // transfer BNB from contract to last bidder: the hacker
            (bool isSuccessTransfer,) = lastBidder.call{value: auctions[auctionId].amount}("");
            require(isSuccessTransfer, "Transfer failed: gas error");
        }

        auctions[auctionId].amount = msg.value;
        auctions[auctionId].bidder = msg.sender;
    }

    function createAuction(uint256 tokenId, address tokenContract) public {
        address tokenOwner = IERC721(tokenContract).ownerOf(tokenId);
        require(msg.sender == tokenOwner, "Caller must be approved or owner for token id");

        _auctionIdTracker.increment();
        uint256 auctionId = _auctionIdTracker.current();
        uint256 endTime = block.timestamp + 5 minutes;

        auctions[auctionId] = Auction({
            tokenId: tokenId,
            tokenContract: tokenContract,
            endTime: endTime,
            tokenOwner: tokenOwner,
            bidder: address(0),
            amount: 0
        });

        IERC721(tokenContract).safeTransferFrom(tokenOwner, address(this), tokenId);
    }

    function endAuction(uint256 auctionId) public {
        Auction memory auctionInfo = auctions[auctionId];
        require(block.timestamp >= auctionInfo.endTime, "Auction hasn't completed");

        // transfer NFT from contract to last bidder
        IERC721(auctionInfo.tokenContract).safeTransferFrom(address(this), auctionInfo.bidder, auctionInfo.tokenId);

        // transfer BNB from contract to aunction owner
        (bool isSuccessTransfer,) = auctionInfo.tokenOwner.call{value: auctions[auctionId].amount}("");
        require(isSuccessTransfer, "Transfer failed: gas error");

        delete auctions[auctionId];
    }
}