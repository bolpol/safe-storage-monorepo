// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.6;
pragma abicoder v2;

interface ISafeStorage {
    function execute(address _receipts, uint _value, bytes memory _data)
        external
        payable
        returns (bool success, bytes memory result);
}