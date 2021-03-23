// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";


abstract contract ERC20Wrapper is ERC20 {
    ERC20 immutable public underlyingToken;

    constructor(ERC20 underlyingToken_) {
        underlyingToken = underlyingToken_;
    }

    function depositFor(address account, uint256 amount) public virtual returns (bool) {
        require(underlyingToken.transferFrom(_msgSender(), address(this), amount));
        _mint(account, amount);
        return true;
    }

    function withdrawTo(address account, uint256 amount) public virtual returns (bool) {
        _burn(_msgSender(), amount);
        require(underlyingToken.transfer(account, amount));
        return true;
    }
}
