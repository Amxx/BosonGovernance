// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "./IGovernanceCore.sol";
import "./utils/Timers.sol";

abstract contract GovernanceCore is IGovernanceCore, Context, Timers {

    struct Proposal {
        uint256 block;
        uint256 supply;
        uint256 score;
        mapping (address => bool) voters;
    }

    mapping (bytes32 => Proposal) _proposals;

    modifier onlyActiveTimer(bytes32 id) virtual override {
        require(_isTimerActive(id), "GovernanceCore: invalid proposal");
        _;
    }

    modifier onlyDuringTimer(bytes32 id) virtual override {
        require(_isTimerDuring(id), "GovernanceCore: vote not currently active");
        _;
    }

    modifier onlyAfterTimer(bytes32 id) virtual override {
        require(_isTimerAfter(id), "GovernanceCore: proposal not ready to execute");
        _;
    }

    /*************************************************************************
     *                            View functions                             *
     *************************************************************************/
    function viewProposalStatus(bytes32 id) public view returns (uint8 status) {
        if (_isTimerBefore(id)) return uint8(0x0);
        if (_isTimerDuring(id)) return uint8(0x1);
        if (_isTimerAfter(id))  return uint8(0x2);
        if (_isTimerLocked(id)) return uint8(0x3);
        revert();
    }

    function viewProposal(bytes32 id)
    public view returns (uint256 startBlock, uint256 deadline, uint256 supply, uint256 score)
    {
        return ( _proposals[id].block, _getDeadline(id), _proposals[id].supply, _proposals[id].score);
    }

    function hashProposal(address[] calldata, uint256[] calldata, bytes[] calldata, bytes32)
    public view virtual returns (bytes32)
    {
        // This is cheaper and works just as well
        return keccak256(_msgData()[4:]);
        // return keccak256(abi.encode(target, value, data, salt));
    }

    /*************************************************************************
     *                               Private                                 *
     *************************************************************************/
    function _propose(
        address[] calldata target,
        uint256[] calldata value,
        bytes[] calldata data,
        bytes32 salt
    )
    internal virtual returns (bytes32)
    {
        bytes32 id = hashProposal(target, value, data, salt);
        _propose(id, target, value, data, salt);
        return id;
    }

    function _propose(
        bytes32 id,
        address[] calldata target,
        uint256[] calldata value,
        bytes[] calldata data,
        bytes32 salt
    )
    internal virtual
    {
        require(target.length == value.length, "GovernanceCore: invalid proposal length");
        require(target.length == data.length,  "GovernanceCore: invalid proposal length");
        require(target.length > 0,             "GovernanceCore: empty proposal");

        uint256 duration = votingDuration();
        uint256 offset   = votingOffset();

        _startTimer(id, block.timestamp + offset * 14 + duration); // prevent double proposal
        _proposals[id].block = block.number + offset;

        emit Proposed(id, target, value, data, salt);
    }

    function _execute(
        address[] calldata target,
        uint256[] calldata value,
        bytes[] calldata data,
        bytes32 salt
    )
    internal virtual returns (bytes32)
    {
        bytes32 id = hashProposal(target, value, data, salt);
        _execute(id, target, value, data, salt);
        return id;
    }

    function _execute(
        bytes32 id,
        address[] calldata target,
        uint256[] calldata value,
        bytes[] calldata data,
        bytes32 salt
    )
    internal virtual onlyAfterTimer(id)
    {
        require(target.length == value.length, "GovernanceCore: invalid proposal length");
        require(target.length == data.length,  "GovernanceCore: invalid proposal length");
        require(target.length > 0,             "GovernanceCore: empty proposal");

        _resetTimer(id); // check timer expired + reset
        _lockTimer(id); // avoid double execution

        Proposal storage proposal = _proposals[id];
        require(proposal.supply >= quorum(), "GovernanceCore: quorum not reached");
        require(proposal.score >= proposal.supply * requiredScore(), "GovernanceCore: required score not reached");

        _calls(id, target, value, data, salt);

        emit Executed(id);
    }

    function _castVote(
        bytes32 id,
        address account,
        uint256 score
    )
    internal virtual onlyDuringTimer(id)
    {
        require(score <= maxScore(), "GovernanceCore: invalid score");

        Proposal storage proposal = _proposals[id];
        require(!proposal.voters[account], "GovernanceCore: vote already casted");
        proposal.voters[account] = true;

        require(proposal.block < block.number, "GovernanceCore: too early to vote");
        uint256 balance = token().getPriorVotes(account, proposal.block);
        proposal.supply += balance;
        proposal.score += balance * score;

        emit Vote(id, account, balance, score);
    }

    function _calls(
        bytes32 /*id*/,
        address[] calldata target,
        uint256[] calldata value,
        bytes[] calldata data,
        bytes32 /*salt*/
    )
    internal virtual
    {
        for (uint256 i = 0; i < target.length; ++i) {
            _call(target[i], value[i], data[i]);
        }
    }

    function _call(
        address target,
        uint256 value,
        bytes memory data
    )
    internal virtual
    {
        if (data.length == 0) {
            Address.sendValue(payable(target), value);
        } else {
            Address.functionCallWithValue(target, data, value);
        }
    }
}
