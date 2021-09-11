// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract ERC20Mock is ERC20("Mock ERC20", "E20MOCK") {
    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }
}
