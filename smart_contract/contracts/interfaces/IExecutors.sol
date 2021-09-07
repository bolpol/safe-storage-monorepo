// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.6;
pragma abicoder v2;

interface IExecutors {

    function multicall(bytes[] calldata data)
        external
        payable
        returns (bytes[] memory results);

    function multicallDelegate(bytes[] calldata data)
        external
        payable
        returns (bytes[] memory results);

    function multicallTo(bytes[] calldata data, address[] calldata _receipts)
        external
        payable
        returns (bytes[] memory results);

    function singlecall(bytes calldata data)
        external
        payable
        returns (bytes memory result);

    function singlecallDelegate(bytes calldata data)
        external
        payable
        returns (bytes memory result);

    function singlecallTo(bytes calldata data, address _receipts)
        external
        payable
        returns (bytes memory result);
}