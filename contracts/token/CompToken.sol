// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/Arrays.sol";
import "./IComp.sol";

abstract contract CompToken is IComp, ERC20Permit {
    bytes32 private constant _DELEGATION_TYPEHASH = keccak256("Delegation(address delegator,address delegatee,uint256 expiry)");

    mapping (address => address)                      private _delegates;
    mapping (address => uint256[])                    private _checkpointBlocks;
    mapping (address => mapping (uint256 => uint256)) private _checkpointWeights;

    constructor(string memory name, string memory symbol) ERC20(name, symbol) ERC20Permit(name) {}

    function delegate(address delegatee)
    public virtual override
    {
        return _delegate(_msgSender(), delegatee);
    }

    function delegateFromBySig(address delegator, address delegatee, uint expiry, uint8 v, bytes32 r, bytes32 s)
    public virtual override
    {
        revert("TODO: delegateFromBySig disabled until _useNonce is available");

        // require(block.timestamp <= expiry, "CompERC20Wrapper: signature expired");
        //
        // require(
        //     delegator == ECDSA.recover(
        //         _hashTypedDataV4(keccak256(abi.encode(
        //             _DELEGATION_TYPEHASH,
        //             delegatee,
        //             _useNonce(delegator),
        //             expiry
        //         ))),
        //         v, r, s
        //     ),
        //     "CompERC20Wrapper: invalid signature"
        // );
        //
        // return _delegate(delegator, delegatee);
    }

    function _delegate(address delegator, address delegatee)
    internal
    {
        address currentDelegate = _delegates[delegator];
        uint256 delegatorBalance = balanceOf(delegator);
        _delegates[delegator] = delegatee;

        emit DelegateChanged(delegator, currentDelegate, delegatee);

        _moveDelegates(currentDelegate, delegatee, delegatorBalance);
    }

    function getPriorVotes(address account, uint blockNumber)
    public view override returns (uint256)
    {
        require(blockNumber < block.number, "CompERC20Wrapper: not yet determined");

        uint256 pos = Arrays.findUpperBound(_checkpointBlocks[account], blockNumber);
        return pos == 0 ? 0 : _checkpointWeights[account][pos - 1];
    }

    function getCurrentVotes(address account)
    external view override returns (uint256)
    {
        uint256 pos = _checkpointBlocks[account].length;
        return pos == 0 ? 0 : _checkpointWeights[account][pos - 1];
    }

    function _moveDelegates(address srcRep, address dstRep, uint256 amount)
    internal
    {
        if (srcRep != dstRep && amount > 0) {
            if (srcRep != address(0)) {
                uint256 srcRepNum = _checkpointBlocks[srcRep].length;
                uint256 srcRepOld = srcRepNum == 0 ? 0 : _checkpointWeights[srcRep][srcRepNum - 1];
                uint256 srcRepNew = srcRepOld - amount;
                _writeCheckpoint(srcRep, srcRepNum, srcRepOld, srcRepNew);
            }

            if (dstRep != address(0)) {
                uint256 dstRepNum = _checkpointBlocks[dstRep].length;
                uint256 dstRepOld = dstRepNum == 0 ? 0 : _checkpointWeights[dstRep][dstRepNum - 1];
                uint256 dstRepNew = dstRepOld + amount;
                _writeCheckpoint(dstRep, dstRepNum, dstRepOld, dstRepNew);
            }
        }
    }

    function _writeCheckpoint(address delegatee, uint256 pos, uint256 oldWeight, uint256 newWeight)
    internal
    {
      if (pos > 0 && _checkpointBlocks[delegatee][pos - 1] == block.number) {
          _checkpointWeights[delegatee][pos - 1] = newWeight;
      } else {
          _checkpointBlocks[delegatee].push(block.number);
          _checkpointWeights[delegatee][pos] = newWeight;
      }

      emit DelegateVotesChanged(delegatee, oldWeight, newWeight);
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount)
    internal virtual override
    {
        address fromDelegate = _delegates[from];
        address toDelegate   = _delegates[to];
        _moveDelegates(
            fromDelegate == address(0) ? from : fromDelegate,
            toDelegate   == address(0) ? to   : toDelegate,
            amount
        );
    }
}
