// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165Storage.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract SafeStorage is ERC165Storage, Ownable, ERC721Holder, ERC1155Holder {
    event Received(address indexed from, uint256 indexed amount);
    event ReceivedFallback(address indexed from, uint256 indexed amount);

    fallback() external payable {
        if (msg.value > 0) {
            emit ReceivedFallback(msg.sender, msg.value);
        }
    }

    receive() external payable {
        if (msg.value > 0) {
            emit Received(msg.sender, msg.value);
        }
    }

    function execute(
        address _target,
        uint256 _value,
        bytes memory _data
    )
        external
        payable
        virtual
        onlyOwner
        returns (bool success, bytes memory result)
    {
        require(
            address(this).balance + msg.value >= _value,
            "low ether balance"
        );

        (success, result) = _target.call{value: _value}(_data);

        if (!success) {
            // Next 5 lines from https://ethereum.stackexchange.com/a/83577
            if (result.length < 68) revert();
            assembly {
                result := add(result, 0x04)
            }
            revert(abi.decode(result, (string)));
        }
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC1155Receiver, ERC165Storage)
        returns (bool)
    {
        return
            ERC1155Receiver.supportsInterface(interfaceId) ||
            ERC165Storage.supportsInterface(interfaceId);
    }
}
