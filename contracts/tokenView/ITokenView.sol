// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

abstract contract ITokenView {
    function _snapshot() internal virtual returns (uint256);
    function _balanceOfAt(address, uint256) internal virtual returns (uint256);
}
