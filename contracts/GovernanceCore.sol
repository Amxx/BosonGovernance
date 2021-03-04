// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "./IGovernanceCore.sol";
import "./utils/Timers.sol";

abstract contract GovernanceCore is IGovernanceCore, EIP712, Context, Timers {
    struct Proposal {
        uint256 snapshot;
        uint256 supply;
        uint256 score;
        mapping (address => bool) voters;
    }

    mapping (bytes32 => Proposal) _proposals;

    constructor(string memory name, string memory version) EIP712(name, version) {}

    /*************************************************************************
     *                            View functions                             *
     *************************************************************************/
    function viewProposalStatus(bytes32 id) public view returns (uint8 status) {
        if (_beforeTimer(id)) return uint8(0x0);
        if (_duringTimer(id)) return uint8(0x1);
        if (_afterTimer(id))  return uint8(0x2);
        if (_lockedTimer(id)) return uint8(0x3);
        revert();
    }

    function viewProposal(bytes32 id) public view returns (uint256 deadline, uint256 supply, uint256 score) {
        return (_getDeadline(id), _proposals[id].supply, _proposals[id].score);
    }

    function hashProposal(address[] calldata target, uint256[] calldata value, bytes[] calldata data, bytes32 salt) public pure virtual returns (bytes32 hash) {
        return keccak256(abi.encode(target, value, data, salt));
    }

    /*************************************************************************
     *                                Actions                                *
     *************************************************************************/
    function propose(address[] calldata target, uint256[] calldata value, bytes[] calldata data, bytes32 salt) public virtual override {
        require(target.length == value.length, "GovernanceCore: invalid proposal length");
        require(target.length == data.length,  "GovernanceCore: invalid proposal length");
        require(target.length > 0,             "GovernanceCore: empty proposal");

        bytes32 id = hashProposal(target, value, data, salt);

        _startTimer(id, block.timestamp + votingDuration()); // prevent double proposal

        _proposals[id].snapshot = _snapshot();
        // TODO: emit event(s)
    }

    function execute(address[] calldata target, uint256[] calldata value, bytes[] calldata data, bytes32 salt) public payable virtual override {
        require(target.length == value.length, "GovernanceCore: invalid proposal length");
        require(target.length == data.length,  "GovernanceCore: invalid proposal length");
        require(target.length > 0,             "GovernanceCore: empty proposal");

        bytes32 id = hashProposal(target, value, data, salt);

        _resetTimer(id); // check timer expired + reset
        _lockTimer(id); // avoid double execution

        Proposal storage proposal = _proposals[id];
        require(proposal.supply >= quorum(), "GovernanceCore: quorum not reached");
        require(proposal.score >= proposal.supply * requiredScore(), "GovernanceCore: required score not reached");

        for (uint256 i = 0; i < target.length; ++i) {
            _call(target[i], value[i], data[i]);
        }
        // TODO: emit event(s)
    }

    function castVote(bytes32 id, uint256 score) public virtual override {
        _castVote(id, _msgSender(), score);
    }

    function castVoteBySig(bytes32 id, uint256 score, bytes calldata signature) public virtual override {
        address voter = ECDSA.recover(
            _hashTypedDataV4(keccak256(abi.encodePacked(keccak256("Vote(bytes32 id,uint256 score)"), id, score))),
            signature
        );
        _castVote(id, voter, score);
    }

    /*************************************************************************
     *                               Internal                                *
     *************************************************************************/
    function _call(address target, uint256 value, bytes memory data) internal {
        if (data.length == 0) {
            Address.sendValue(payable(target), value);
        } else {
            Address.functionCallWithValue(target, data, value);
        }
        // TODO: emit event
    }

    function _castVote(bytes32 id, address account, uint256 score) internal {
        require(_duringTimer(id), "GovernanceCore: vote not currently active");
        require(score <= maxScore(), "GovernanceCore: invalid score");

        Proposal storage proposal = _proposals[id];
        require(!proposal.voters[account], "GovernanceCore: vote already casted");
        proposal.voters[account] = true;

        uint256 balance = _balanceOfAt(account, proposal.snapshot);
        proposal.supply += balance;
        proposal.score += balance * score;
        // TODO: emit event
    }
}