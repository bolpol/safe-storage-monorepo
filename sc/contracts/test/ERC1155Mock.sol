// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";

contract ERC1155Mock is ERC1155("https://example.com/") {
    function mint(address to, uint tokenId, uint tokenAmount, bytes memory data) external {
        _mint(to, tokenId, tokenAmount, data);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC1155) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}
