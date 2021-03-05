// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./CompToken.sol";

contract CompWrapper is CompToken {
    ERC20 immutable public token;

    constructor(ERC20 token_)
    CompToken(
        string(abi.encodePacked("Governance ", token_.name())),
        string(abi.encodePacked("G-",          token_.symbol()))
    )
    {
        token = token_;
    }

    function depositFor(address account, uint256 amount) public virtual returns (bool) {
        require(token.transferFrom(_msgSender(), address(this), amount));
        _mint(account, amount);
        return true;
    }

    function withdrawTo(address account, uint256 amount) public virtual returns (bool) {
        _burn(_msgSender(), amount);
        require(token.transfer(account, amount));
        return true;
    }
}
