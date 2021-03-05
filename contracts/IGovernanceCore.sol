// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./token/IComp.sol";

abstract contract IGovernanceCore {
    // events
    event Proposed(bytes32 indexed id, address[] target, uint256[] value, bytes[] data, bytes32 salt);
    event Executed(bytes32 indexed id, address[] target, uint256[] value, bytes[] data, bytes32 salt);
    event Vote(bytes32 indexed id, address account, uint256 balance, uint256 score);

    // settings
    function token() public view virtual returns (IComp);
    function votingOffset() public view virtual returns (uint256);
    function votingDuration() public view virtual returns (uint256);
    function quorum() public view virtual returns (uint256);
    function maxScore() public view virtual returns (uint256) { return 100; }
    function requiredScore() public view virtual returns (uint256) { return 50; }

    // proposals
    function propose(address[] calldata target, uint256[] calldata value, bytes[] calldata data, bytes32 salt) external virtual;
    function execute(address[] calldata target, uint256[] calldata value, bytes[] calldata data, bytes32 salt) external payable virtual;

    // votes
    function castVote(bytes32 id, uint256 score) external virtual;
    function castVoteBySig(bytes32 id, uint256 score, uint8 v, bytes32 r, bytes32 s) external virtual;
}
