// SPDX-License-Identifier: MIT
// AWAIS:: Issues identity credentials to users.

pragma solidity ^0.8.0;

contract IdIssue {
    struct Identity {
        address owner;
        bytes32 identityHash;
        uint256 issueDate;
        bool valid;
    }

    mapping(address => Identity) public identities;

    event IdentityIssued(address indexed owner, bytes32 identityHash, uint256 issueDate);

    function issueIdentity(bytes32 identityHash) external {
        identities[msg.sender] = Identity({
            owner: msg.sender,
            identityHash: identityHash,
            issueDate: block.timestamp,
            valid: true
        });
        emit IdentityIssued(msg.sender, identityHash, block.timestamp);
    }

    function revokeIdentity(address owner) external {
        require(identities[owner].valid == true, "Identity already revoked");
        identities[owner].valid = false;
    }

    function isValidIdentity(address owner) external view returns (bool) {
        return identities[owner].valid;
    }
}
