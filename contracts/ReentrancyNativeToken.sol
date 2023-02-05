//SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * DO NOT USE THIS ON PRODUCTION
 */
contract VulnerableNativeTokenReentrancy is Ownable {
    mapping(address => uint256) public stakingData;

    constructor () {}

    function stake() public payable {
        stakingData[msg.sender] += msg.value;
    }

    function withdraw() public {
        _transferNativeToken(msg.sender, stakingData[msg.sender]);
    }

    function emergencyWithdraw() public onlyOwner {
        _transferNativeToken(msg.sender, address(this).balance);
    }

    function _transferNativeToken(address account, uint256 amount) internal {
        (bool success, ) = account.call{value: amount}("");
        require(success, "TRANSFER_FAILED");
    }
}