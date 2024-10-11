// SPDX-License-Identifier: MIT
// AWAIS:: Handles identity revocation.

pragma solidity ^0.8.0;

import "./IdIssue.sol";

contract IPRevoke {
    IdIssue public idIssueContract;

    constructor(address _idIssueContract) {
        idIssueContract = IdIssue(_idIssueContract);
    }

    function revokeIdentity(address owner) external {
        idIssueContract.revokeIdentity(owner);
    }

    function isRevoked(address owner) external view returns (bool) {
        return !idIssueContract.isValidIdentity(owner);
    }
}
