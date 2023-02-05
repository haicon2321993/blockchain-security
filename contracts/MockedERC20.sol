//SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/**
 * DO NOT USE THIS ON PRODUCTION
 */
contract MockedERC20 is ERC20 {
    constructor(
        string memory name,
        string memory symbol,
        uint256 supply
    ) ERC20(name, symbol) {
        _mint(msg.sender, supply);
    }
}