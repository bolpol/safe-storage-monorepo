pragma solidity >=0.8.0;

import "@openzeppelin/contracts/utils/introspection/ERC165Storage.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract SafeStorage is
    ERC165Storage,
    Ownable,
    ERC721Holder,
    ERC1155Holder
{
    event Received(address indexed from, uint256 indexed amount);
    event ReceivedFallback(address indexed from, uint256 indexed amount);

    constructor() { }

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

    function registerInterface(bytes4 interfaceId) public virtual onlyOwner {
        _registerInterface(interfaceId);
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

    function withdraw(uint value)
        external
        virtual
        onlyOwner
        returns (bytes memory result)
    {
        require(address(this).balance >= value, "Not enough balance");

        bool success;
        (success, result) = address(this).call{value: value}("");

        require(success, "Withdraw failed");
    }

    function execute(address _receipts, uint _value, bytes memory _data)
        external
        payable
        virtual
        returns (bool success, bytes memory result)
    {
        (success, result) = _receipts.call{value: _value}(_data);

        if (!success) {
            // Next 5 lines from https://ethereum.stackexchange.com/a/83577
            if (result.length < 68) revert();
            assembly {
                result := add(result, 0x04)
            }
            revert(abi.decode(result, (string)));
        }
    }
}