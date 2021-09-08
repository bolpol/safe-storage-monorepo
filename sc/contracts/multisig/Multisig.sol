pragma solidity ^0.8.4;

import "./Signable.sol";
import "../interfaces/ITimelock.sol";
import "../libs/TimelockLibrary.sol";

contract Multisig is Signable {

    enum Status {
        EMPTY, // zero state
        INITIALIZED, // created with one sign
        CANCELLED,  // canceled by consensus
        QUEUED, // approved and send to timelock
        EXECUTED // executed
    }

    struct Proposal {
        /// @notice Unique id for looking up a proposal
        uint id;

        // @dev actual signs
        uint256 signs;
        // @dev required signs
        uint256 reqsigns;

        Status status;
        /// @notice Creator of the proposal
        address proposer;
        /// @notice The timestamp that the proposal will be available for execution, set once the vote succeeds
        uint eta;
        /// @notice the ordered list of target addresses for calls to be made
        address[] targets;
        /// @notice The ordered list of values (i.e. msg.value) to be passed to the calls to be made
        uint[] values;
        /// @notice The ordered list of function signatures to be called
        string[] signatures;
        /// @notice The ordered list of calldata to be passed to each call
        bytes[] calldatas;

        address callFrom;

        string description;
    }

    mapping (uint => Proposal) public proposals;

    /// @notice The total number of proposals
    uint public proposalCount;

    address public timelock;

    constructor(address _timelock, address[] memory _accounts) {
        require(_timelock != address(0), "Timelock zero");
        require(_accounts.length >= MIN_NUM_SIGNERS, "Num signers consensus not reached");

        timelock = _timelock;
        totalSigners += _accounts.length;
    }

    function getStatus(uint _proposalId) public view returns (Status) {
        Proposal memory p = proposals[_proposalId];

        if (p.status == Status.CANCELLED) {
            return Status.CANCELLED;
        }
        if (p.status == Status.EXECUTED) {
            return Status.EXECUTED;
        }
        if (p.signs > 0) {
            if (p.eta + TimelockLibrary.GRACE_PERIOD <= block.timestamp) {
                return Status.CANCELLED;
            }

            if (p.reqsigns == p.signs) {
                return Status.QUEUED;
            }

            return Status.INITIALIZED;
        }

        return Status.EMPTY;
    }

    function getActions(uint _proposalId)
        public
        view
        returns (
            address[] memory targets,
            uint[] memory values,
            string[] memory signatures,
            bytes[] memory calldatas
        )
    {
        Proposal storage p = proposals[_proposalId];
        return (p.targets, p.values, p.signatures, p.calldatas);
    }

    function createAndSign(
        address[] memory targets,
        uint[] memory values,
        string[] memory signatures,
        bytes[] memory calldatas,
        string memory description,
        address callFrom // Pass SAFE STORAGE address if want interact with it
    ) external onlySigner {
        uint proposalId = proposalCount++;

        Proposal storage proposal = proposals[proposalId];
        proposal.targets = targets;
        proposal.values = values;
        proposal.signatures = signatures;
        proposal.calldatas = calldatas;
        proposal.description = description;
        proposal.proposer = msg.sender;
        proposal.callFrom = callFrom;

        proposalCount = proposalId;
    }

    function sign(uint _proposalId) external onlySigner {
        require(
             getStatus(_proposalId) == Status.INITIALIZED,
            "Wrong status"
        );

        Proposal storage proposal = proposals[_proposalId];
        proposal.signs++;
        if (proposal.signs == proposal.reqsigns) {
            proposal.status = Status.QUEUED; // block status
            proposal.eta = ITimelock(timelock).delay() + block.timestamp;
            TimelockLibrary.Transaction memory tx;
            for (uint i; i < proposal.targets.length; i++) {
                tx.target = proposal.targets[i];
                tx.value = proposal.values[i];
                tx.signature = proposal.signatures[i];
                tx.data = proposal.calldatas[i];
                tx.eta = proposal.eta;
                tx.hash = keccak256(abi.encode(_proposalId, i, tx.target, tx.value, tx.signature, tx.data, tx.eta));
                tx.callFrom = proposal.callFrom;

                ITimelock(timelock).queueTransaction(tx);
            }
        }
    }

    function execute(uint _proposalId) public payable onlySigner {
        require(
            getStatus(_proposalId) == Status.QUEUED,
            "Wrong status"
        );

        Proposal storage proposal = proposals[_proposalId];
        proposal.status = Status.EXECUTED; // block status
        TimelockLibrary.Transaction memory tx;
        for (uint i; i < proposal.targets.length; i++) {
            tx.target = proposal.targets[i];
            tx.value = proposal.values[i];
            tx.signature = proposal.signatures[i];
            tx.data = proposal.calldatas[i];
            tx.eta = proposal.eta;
            tx.hash = keccak256(abi.encode(_proposalId, i, tx.target, tx.value, tx.signature, tx.data, tx.eta));
            tx.callFrom = proposal.callFrom;

            ITimelock(timelock).executeTransaction(tx);
        }
    }

    function cancel(uint _proposalId) public {
        Status status = getStatus(_proposalId);

        require(
            status == Status.INITIALIZED ||
            status == Status.QUEUED,
            "Wrong status"
        );

        Proposal storage proposal = proposals[_proposalId];
        proposal.status = Status.CANCELLED;

        TimelockLibrary.Transaction memory tx;
        for (uint i; i < proposal.targets.length; i++) {
            tx.target = proposal.targets[i];
            tx.value = proposal.values[i];
            tx.signature = proposal.signatures[i];
            tx.data = proposal.calldatas[i];
            tx.eta = proposal.eta;
            tx.hash = keccak256(abi.encode(_proposalId, i, tx.target, tx.value, tx.signature, tx.data, tx.eta));
            tx.callFrom = proposal.callFrom;

            ITimelock(timelock).cancelTransaction(tx);
        }
    }
}