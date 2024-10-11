// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract IdProve {
    struct Proof {
        bytes32 identityHash;
        bytes32 proof;
    }

    mapping(address => Proof) public proofs;

    event ProofSubmitted(address indexed owner, bytes32 identityHash, bytes32 proof);

    function submitProof(bytes32 identityHash, bytes32 proof) external {
        proofs[msg.sender] = Proof({
            identityHash: identityHash,
            proof: proof
        });
        emit ProofSubmitted(msg.sender, identityHash, proof);
    }

    function getProof(address owner) external view returns (Proof memory) {
        return proofs[owner];
    }
}
