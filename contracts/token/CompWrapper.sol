// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC20Comp.sol";
import "./ERC20Wrapper.sol";

contract CompWrapper is ERC20Wrapper, ERC20Comp {
    constructor(ERC20 token_)
    ERC20Wrapper(token_)
    ERC20Comp(
        string(abi.encodePacked("Governance ", token_.name())),
        string(abi.encodePacked("G-",          token_.symbol()))
    )
    {}

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual override(ERC20, ERC20Comp) {
        super._beforeTokenTransfer(from, to, amount);
    }
}
