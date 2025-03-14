// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Merkle {
    string public merkleRoot; // Stores the final hash as a string (without "0x")

    event MerkleRootUpdated(string newRoot);

    // event DebugHash(string step, bytes32 hash);
    // event DebugStringHash(string step, string hashString);

    /**
     * @dev Stores a new Merkle root as a string.
     * @param root The new Merkle root (precomputed SHA-256 hash as string).
     */
    function storeMerkleRoot(string memory root) public {
        merkleRoot = root;
        emit MerkleRootUpdated(root);
    }

    /**
     * @dev Retrieves the latest Merkle root from storage.
     * @return The latest Merkle root as a string.
     */
    function getMerkleRoot() public view returns (string memory) {
        return merkleRoot;
    }

    /**
     * @dev Verifies a Merkle proof using SHA-256.
     * @param leaf The precomputed SHA-256 hash string of the leaf node.
     * @param proof A 2D array of sibling hashes (string) and direction ("left"/"right").
     * @return True if the proof is valid, false otherwise.
     */
    // function verifyProof(string memory leaf, string[2][] memory proof) public returns (bool) {
    function verifyProof(
        string memory leaf,
        string[2][] memory proof
    ) public view returns (bool) {
        string memory computedHash = leaf;
        // emit DebugStringHash("Initial Leaf Hash", computedHash);

        for (uint256 i = 0; i < proof.length; i++) {
            string memory sibling = proof[i][0];
            string memory direction = proof[i][1];

            if (
                keccak256(abi.encodePacked(direction)) ==
                keccak256(abi.encodePacked("right"))
            ) {
                computedHash = toSha256Hash(
                    string(abi.encodePacked(computedHash, sibling))
                );
                // emit DebugStringHash("New Computed Hash (Right)", computedHash);
            } else if (
                keccak256(abi.encodePacked(direction)) ==
                keccak256(abi.encodePacked("left"))
            ) {
                computedHash = toSha256Hash(
                    string(abi.encodePacked(sibling, computedHash))
                );
                // emit DebugStringHash("New Computed Hash (Left)", computedHash);
            } else {
                revert("Invalid direction: must be 'left' or 'right'");
            }
        }

        // emit DebugStringHash("Final Computed Hash", computedHash);
        // emit DebugStringHash("Stored Merkle Root", merkleRoot);

        return
            keccak256(abi.encodePacked(computedHash)) ==
            keccak256(abi.encodePacked(merkleRoot));
    }

    /**
     * @dev Computes SHA-256 hash of a given input string.
     * @param input The input string.
     * @return The SHA-256 hash as a string.
     */
    function toSha256Hash(
        string memory input
    ) public pure returns (string memory) {
        return bytes32ToHexString(sha256(abi.encodePacked(input)));
    }

    /**
     * @dev Converts bytes32 to a hex string without "0x".
     * @param _bytes32 The bytes32 value.
     * @return The string representation of bytes32.
     */
    function bytes32ToHexString(
        bytes32 _bytes32
    ) public pure returns (string memory) {
        bytes memory alphabet = "0123456789abcdef";
        bytes memory str = new bytes(64);

        for (uint256 i = 0; i < 32; i++) {
            str[i * 2] = alphabet[uint8(_bytes32[i] >> 4)];
            str[1 + i * 2] = alphabet[uint8(_bytes32[i] & 0x0f)];
        }
        return string(str);
    }
}
