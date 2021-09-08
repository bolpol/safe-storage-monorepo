pragma solidity >=0.8.0;

library TimelockLibrary {
    struct Transaction {
        address callFrom;
        bytes32 hash;
        address target;
        uint value;
        string signature;
        bytes data;
        uint eta;
    }

    uint public constant GRACE_PERIOD = 14 days;
}