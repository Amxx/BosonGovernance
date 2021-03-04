// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../GovernanceCore.sol";
import "../tokenView/TokenSnapshotWrapper.sol";

contract Governance is GovernanceCore, TokenSnapshotWrapper {

    constructor(string memory name, string memory version, ERC20 underlyingToken)
    GovernanceCore(name, version)
    TokenSnapshotWrapper(underlyingToken)
    {}

    function votingDuration() public pure override returns (uint256) {
        return 3600;
    }

    function quorum() public pure override returns (uint256) {
        return 1;
    }

    function _snapshot() internal override(ITokenView, TokenSnapshotWrapper) returns (uint256) {
        return TokenSnapshotWrapper._snapshot();
    }
}
