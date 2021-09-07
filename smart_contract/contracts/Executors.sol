// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.6;
pragma abicoder v2;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IExecutors.sol";

/// @title Executors
abstract contract Executors is IExecutors, Ownable {

    function multicall(bytes[] calldata data)
        external
        virtual
        override
        payable
        onlyOwner
        returns (bytes[] memory results)
    {
        results = new bytes[](data.length);
        for (uint256 i = 0; i < data.length; i++) {
            (bool success, bytes memory result) = address(this).call(data[i]);

            _callError(success, result);

            results[i] = result;
        }
    }

    /// @notice Enables calling multiple methods in a single call to the contract
    function multicallDelegate(bytes[] calldata data)
        external
        virtual
        override
        payable
        onlyOwner
        returns (bytes[] memory results)
    {
        results = new bytes[](data.length);
        for (uint256 i = 0; i < data.length; i++) {
            (bool success, bytes memory result) = address(this).delegatecall(data[i]);

            _callError(success, result);

            results[i] = result;
        }
    }

    function multicallTo(bytes[] calldata data, address[] calldata _receipts)
        external
        virtual
        override
        payable
        onlyOwner
        returns (bytes[] memory results)
    {
        require(data.length == _receipts.length, "Executor: data not _receipts");

        results = new bytes[](data.length);
        for (uint256 i = 0; i < data.length; i++) {
            (bool success, bytes memory result) = _receipts[i].call(data[i]);

            _callError(success, result);

            results[i] = result;
        }
    }

    function singlecall(bytes calldata data)
        external
        virtual
        payable
        override
        onlyOwner
        returns (bytes memory result)
    {
        bool success;
        (success, result) = address(this).call(data);

        _callError(success, result);
    }

    function singlecallDelegate(bytes calldata data)
        external
        virtual
        payable
        override
        onlyOwner
        returns (bytes memory result)
        {
            bool success;
            (success, result) = address(this).delegatecall(data);

            _callError(success, result);
    }

    function singlecallTo(bytes calldata data, address _receipts)
        external
        virtual
        payable
        override
        onlyOwner
        returns (bytes memory result)
    {
        bool success;
        (success, result) = _receipts.call(data);

        _callError(success, result);
    }

    function _callError(bool success, bytes memory result) internal pure {
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
