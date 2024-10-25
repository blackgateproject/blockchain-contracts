// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract StatelessBlockchain {
    uint256 public accumulator;
    uint256 public modN; // RSA modulus N
    mapping(address => uint256) public identities; // Maps user to identity credential hash
    mapping(address => uint256) public witness; // Witness for each identity

    event IdentityAdded(address indexed user, uint256 credentialHash);
    event IdentityRemoved(address indexed user, uint256 credentialHash);
    event IdentityVerified(address indexed user, bool isValid);
    event Debug(uint256 hashedCredential, uint256 newAccumulator); // DEBUG: Logs for debugging

    constructor(uint256 bitsize) {
        accumulator = 1;
        modN = generatePrime(bitsize);
    }

    function generatePrime(uint256 bitsize) internal view returns (uint256) {
        require(
            bitsize >= 8 && bitsize <= 256,
            "Bitsize must be between 8 and 256"
        ); // Limit bitsize for safety
        uint256 randomNum = uint256(
            keccak256(abi.encodePacked(block.timestamp, block.prevrandao))
        ) % (2 ** bitsize);

        unchecked {
            // Wrap increment to avoid overflow
            while (!isPrime(randomNum)) {
                randomNum++;
            }
        }
        return randomNum;
    }

    // Basic primality test for smaller bit sizes
    function isPrime(uint256 num) internal pure returns (bool) {
        if (num <= 1) return false;
        if (num <= 3) return true;
        if (num % 2 == 0 || num % 3 == 0) return false;
        for (uint256 i = 5; i * i <= num; i += 6) {
            if (num % i == 0 || num % (i + 2) == 0) return false;
        }
        return true;
    }

    // Prime representation hash function with threshold
    function primeHash(uint256 input) internal pure returns (uint256) {
        uint256 hashValue = uint256(keccak256(abi.encodePacked(input)));
        return hashValue > 1 ? hashValue : 2; // Ensure hashValue > 1
    }

    // Add new identity to the accumulator
    function addIdentity(uint256 identityCredential) public {
        require(identities[msg.sender] == 0, "Identity already exists");

        uint256 hashedCredential = primeHash(identityCredential);
        identities[msg.sender] = hashedCredential;
        witness[msg.sender] = accumulator;

        accumulator = modExp(accumulator, hashedCredential, modN);

        // Emit debug log
        emit Debug(hashedCredential, accumulator);

        emit IdentityAdded(msg.sender, identityCredential);
    }

    // Remove identity from the accumulator
    function removeIdentity() public {
        require(identities[msg.sender] != 0, "Identity does not exist");
        uint256 hashedCredential = identities[msg.sender];
        accumulator = modExp(accumulator, modInv(hashedCredential, modN), modN);
        delete identities[msg.sender];
        delete witness[msg.sender];

        emit IdentityRemoved(msg.sender, hashedCredential);
    }

    // Verify identity using the witness.
    function verifyIdentity(
        address user,
        uint256 identityCredential
    ) public returns (bool) {
        uint256 hashedCredential = primeHash(identityCredential);
        uint256 witnessValue = witness[user];
        uint256 calculatedAccumulator = modExp(
            witnessValue,
            hashedCredential,
            modN
        );
        bool isValid = (calculatedAccumulator == accumulator);

        emit IdentityVerified(user, isValid);
        return isValid;
    }

    // Modular exponentiation
    function modExp(
        uint256 base,
        uint256 exp,
        uint256 mod
    ) internal pure returns (uint256) {
        uint256 result = 1;
        while (exp > 0) {
            if (exp % 2 == 1) {
                result = (result * base) % mod;
            }
            base = (base * base) % mod;
            exp /= 2;
        }
        return result;
    }

    // Modular inverse (Extended Euclidean Algorithm)
    function modInv(uint256 a, uint256 mod) internal pure returns (uint256) {
        int256 t = 0;
        int256 newT = 1;
        int256 r = int256(mod);
        int256 newR = int256(a);
        while (newR != 0) {
            int256 quotient = r / newR;
            (t, newT) = (newT, t - quotient * newT);
            (r, newR) = (newR, r - quotient * newR);
        }
        if (r > 1) revert("No inverse");
        if (t < 0) t += int256(mod);
        return uint256(t);
    }
}
