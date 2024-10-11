// SPDX-License-Identifier: MIT
// AWAIS:: Enables tracing of identities.

pragma solidity ^0.8.0;

contract IdTrace {
    mapping(address => bytes32) public identityCommitments;

    event CommitmentAdded(address indexed owner, bytes32 commitment);

    function addCommitment(address owner, bytes32 commitment) external {
        identityCommitments[owner] = commitment;
        emit CommitmentAdded(owner, commitment);
    }

    function traceIdentity(address owner) external view returns (bytes32) {
        return identityCommitments[owner];
    }
}
