// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./tokenView/ITokenView.sol";

abstract contract IGovernanceCore is ITokenView {
    // settings
    function votingDuration() public view virtual returns (uint256);
    function quorum() public view virtual returns (uint256);
    function maxScore() public view virtual returns (uint256) { return 100; }
    function requiredScore() public view virtual returns (uint256) { return 50; }
    // proposals
    function propose(address[] calldata target, uint256[] calldata value, bytes[] calldata data, bytes32 salt) external virtual;
    function execute(address[] calldata target, uint256[] calldata value, bytes[] calldata data, bytes32 salt) external payable virtual;
    // votes
    function castVote(bytes32 id, uint256 score) external virtual;
    function castVoteBySig(bytes32 id, uint256 score, bytes calldata signature) external virtual;
}
