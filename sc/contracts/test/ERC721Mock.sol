// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract ERC721Mock is ERC721("Test ERC721", "TEST721") {
    function mint(address to, uint tokenId) external {
        _mint(to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}