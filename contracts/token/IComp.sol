// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IComp is IERC20 {
    event DelegateChanged(address indexed delegator, address indexed fromDelegate, address indexed toDelegate);
    event DelegateVotesChanged(address indexed delegate, uint256 previousBalance, uint256 newBalance);

    function delegate(address delegatee) external;
    function delegateFromBySig(address delegator, address delegatee, uint256 expiry, uint8 v, bytes32 r, bytes32 s) external;
    function getPriorVotes(address account, uint256 blockNumber) external view returns (uint256);
    function getCurrentVotes(address account) external view returns (uint256);
}
