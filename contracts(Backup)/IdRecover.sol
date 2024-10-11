// SPDX-License-Identifier: MIT
// AWAIS:: Allows recovery of lost or revoked identities.

pragma solidity ^0.8.0;

import "./IdIssue.sol";

contract IdRecover {
    IdIssue public idIssueContract;

    constructor(address _idIssueContract) {
        idIssueContract = IdIssue(_idIssueContract);
    }

    function recoverIdentity(address owner, bytes32 newIdentityHash) external {
        idIssueContract.issueIdentity(newIdentityHash);
    }
}
