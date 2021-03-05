// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./CompToken.sol";

contract CompWrapper is CompToken {
    ERC20 immutable _underlyingToken;

    constructor(ERC20 underlyingToken)
    CompToken(
        string(abi.encodePacked("Governance ", underlyingToken.name())),
        string(abi.encodePacked("G-",          underlyingToken.symbol()))
    )
    {
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
}
