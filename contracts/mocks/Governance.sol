// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../GovernanceCore.sol";

contract Governance is GovernanceCore {
    IComp immutable internal _token;

    constructor(string memory name_, string memory version_, IComp token_)
    GovernanceCore(name_, version_)
    {
        _token = token_;
    }

    function token() public view override returns (IComp) {
        return _token;
    }

    function votingDuration() public pure override returns (uint256) {
        return 3600;
    }

    function quorum() public pure override returns (uint256) {
        return 1;
    }
}
