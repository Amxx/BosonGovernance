// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";
import "../GovernanceCore.sol";

contract Governance is GovernanceCore, EIP712 {
    bytes32 private constant _VOTE_TYPEHASH = keccak256("Vote(bytes32 id,uint256 score)");

    IComp immutable internal _token;

    constructor(string memory name_, string memory version_, IComp token_)
    EIP712(name_, version_)
    {
        _token = token_;
    }

    function token()          public view override returns (IComp)   { return _token; }
    function votingOffset()   public pure override returns (uint256) { return 0;      }
    function votingDuration() public pure override returns (uint256) { return 3600;   }
    function quorum()         public pure override returns (uint256) { return 1;      }
    function maxScore()       public pure override returns (uint256) { return 100;    }
    function requiredScore()  public pure override returns (uint256) { return 50;     }

    function propose(
        address[] calldata target,
        uint256[] calldata value,
        bytes[] calldata data,
        bytes32 salt
    )
    public returns (bytes32)
    {
        return _propose(target, value, data, salt);
    }

    function execute(
        address[] calldata target,
        uint256[] calldata value,
        bytes[] calldata data,
        bytes32 salt
    )
    public payable returns (bytes32)
    {
        return _execute(target, value, data, salt);
    }

    function castVote(bytes32 id, uint256 score)
    public
    {
        _castVote(id, _msgSender(), score);
    }

    function castVoteBySig(bytes32 id, uint256 score, uint8 v, bytes32 r, bytes32 s)
    public
    {
        address voter = ECDSA.recover(
            _hashTypedDataV4(keccak256(abi.encodePacked(_VOTE_TYPEHASH, id, score))),
            v, r, s
        );
        _castVote(id, voter, score);
    }
}
