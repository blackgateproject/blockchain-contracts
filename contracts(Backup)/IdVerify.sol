// SPDX-License-Identifier: MIT
// AWAIS:: Allows users to submit proofs of identity.

pragma solidity ^0.8.0;

import "./IdProve.sol";

contract IdVerify {
    IdProve public idProveContract;

    constructor(address _idProveContract) {
        idProveContract = IdProve(_idProveContract);
    }

    function verifyIdentity(address owner, bytes32 identityHash, bytes32 proof) external view returns (bool) {
        IdProve.Proof memory storedProof = idProveContract.getProof(owner);
        // Perform verification based on storedProof (this logic should be handled externally)
        return (storedProof.identityHash == identityHash && storedProof.proof == proof);
    }
}
