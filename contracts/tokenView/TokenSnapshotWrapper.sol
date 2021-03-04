// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Snapshot.sol";
import "./ITokenView.sol";

abstract contract TokenSnapshotWrapper is ITokenView, ERC20Snapshot {
    ERC20 immutable _underlyingToken;

    constructor(ERC20 underlyingToken) ERC20(
        string(abi.encodePacked("Stacked ", underlyingToken.name())),
        string(abi.encodePacked("S-", underlyingToken.symbol()))
    ) {
        _underlyingToken = underlyingToken;
    }

    function depositFor(address account, uint256 amount) public virtual returns (bool) {
        require(_underlyingToken.transferFrom(_msgSender(), address(this), amount));
        _mint(account, amount);
        return true;
    }

    function withdrawTo(address account, uint256 amount) public virtual returns (bool) {
        _burn(_msgSender(), amount);
        require(_underlyingToken.transfer(account, amount));
        return true;
    }

    function _snapshot() internal virtual override(ITokenView, ERC20Snapshot) returns (uint256) {
        return ERC20Snapshot._snapshot();
    }

    function _balanceOfAt(address account, uint256 snapshotId) internal virtual override(ITokenView) returns (uint256) {
        return ERC20Snapshot.balanceOfAt(account, snapshotId);
    }
}
