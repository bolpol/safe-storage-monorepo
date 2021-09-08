pragma solidity ^0.8.4;

contract Signable {

    uint256 constant public MIN_NUM_SIGNERS = 3;
    uint256 constant public MAX_NUM_SIGNERS = 1000;

    uint256 public totalSigners;

    mapping (address => bool) private _signers;

    function addSigner(address _account) public onlyThis {
        _signers[_account] = true;
        totalSigners++;

        require(totalSigners <= MAX_NUM_SIGNERS, "NUM_SIGS_CONS");
    }

    function removeSigner(address _account) public onlyThis {
        _signers[_account] = false;
        totalSigners--;

        require(totalSigners >= MIN_NUM_SIGNERS, "NUM_SIGS_CONS");
    }

    function flipSignerAddress(address _old, address _new) public {
        if (msg.sender != address(this)) {
            require(_old == msg.sender, "no flip rights");
        }
        require(_old != _new, "the same address");
        require(_new != address(0), "zero address");

        _signers[_old] = false;
        _signers[_new] = true;
    }

    modifier onlySigner() {
        require(_signers[msg.sender], "No permission");
        _;
    }

    modifier onlyThis() {
        require(msg.sender == address(this), "Call must come from this contract.");
        _;
    }
}