// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./DIDRegistry.sol";

contract ZKRollupManager {
    struct MerkleTree {
        bytes32 root; // Current Merkle root
        uint256 depth; // Depth of the Merkle tree
    }

    DIDRegistry private didRegistry;
    MerkleTree private merkleTree;

    event MerkleRootUpdated(bytes32 newRoot);
    event BatchProcessed(uint256 batchSize, bytes32 newRoot);
    event SignInValidated(string did, bool valid);

    constructor(address _didRegistryAddress, uint256 _treeDepth) {
        didRegistry = DIDRegistry(_didRegistryAddress);
        merkleTree.depth = _treeDepth;
        merkleTree.root = bytes32(0); // Initialize with an empty root
    }

    /**
     * @dev Process a batch of operations with a ZK-SNARK proof
     * @param newRoot The updated Merkle root after batch processing
     * @param a ZK-SNARK proof element (a)
     * @param b ZK-SNARK proof element (b)
     * @param c ZK-SNARK proof element (c)
     * @param input Public inputs for the ZK-SNARK verifier
     */
    function processBatch(
        bytes32 newRoot,
        uint256[2] memory a,
        uint256[2][2] memory b,
        uint256[2] memory c,
        uint256[] memory input
    ) external {
        require(verifyZKProof(a, b, c, input), "Invalid ZK-SNARK proof");

        // Update Merkle root
        merkleTree.root = newRoot;
        emit MerkleRootUpdated(newRoot);
        emit BatchProcessed(input.length, newRoot);
    }

    /**
     * @dev Sign-in process for a DID
     * @param did The DID being verified
     * @param leafHash The Merkle tree leaf hash for this DID
     * @param proof The Merkle proof array
     * @param index The index of the leaf in the Merkle tree
     */
    function signIn(
        string memory did,
        bytes32 leafHash,
        bytes32[] memory proof,
        uint256 index
    ) external view returns (bool) {
        bool isValid = verifyMerkleProof(leafHash, proof, index, merkleTree.root);
        emit SignInValidated(did, isValid);
        return isValid;
    }

    /**
     * @dev Verifies a Merkle proof
     * @param leaf The hash of the leaf node
     * @param proof The proof array
     * @param index The index of the leaf node
     * @param root The Merkle root to validate against
     */
    function verifyMerkleProof(
        bytes32 leaf,
        bytes32[] memory proof,
        uint256 index,
        bytes32 root
    ) internal pure returns (bool) {
        bytes32 computedHash = leaf;

        for (uint256 i = 0; i < proof.length; i++) {
            if (index % 2 == 0) {
                computedHash = keccak256(abi.encodePacked(computedHash, proof[i]));
            } else {
                computedHash = keccak256(abi.encodePacked(proof[i], computedHash));
            }
            index /= 2;
        }

        return computedHash == root;
    }

    /**
     * @dev Verifies a ZK-SNARK proof using the precompiled contract
     * @param a ZK-SNARK proof element (a)
     * @param b ZK-SNARK proof element (b)
     * @param c ZK-SNARK proof element (c)
     * @param input Public inputs for the ZK-SNARK verifier
     */
    function verifyZKProof(
        uint256[2] memory a,
        uint256[2][2] memory b,
        uint256[2] memory c,
        uint256[] memory input
    ) internal pure returns (bool) {
        (bool success, bytes memory returnData) = address(0x0000000000000000000000000000000000000008).staticcall(
            abi.encode(a, b, c, input)
        );

        return success && abi.decode(returnData, (bool));
    }

    /**
     * @dev Retrieves the current Merkle root
     */
    function getCurrentRoot() external view returns (bytes32) {
        return merkleTree.root;
    }

    /**
     * @dev Fallback function to reject direct ETH transfers
     */
    fallback() external payable {
        revert("Direct ETH transfers not supported");
    }

    receive() external payable {
        revert("ETH transfers not supported");
    }
}
