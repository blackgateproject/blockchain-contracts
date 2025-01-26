// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./BytesLib.sol";

contract RSAAccumulatorVerifier {
    using BytesLib for bytes;

    bytes private acc_post; // The current accumulator value
    bytes private modulus; // The modulus used in the RSA accumulator
    address public owner; // The owner of the contract

    // Constructor to initialize the contract with modulus and initial accumulator value
    constructor(bytes memory _modulus, bytes memory _acc_post) {
        acc_post = _acc_post;
        modulus = _modulus;
        owner = msg.sender;
    }

    // Modifier to restrict access to only the owner
    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can perform this action");
        _;
    }

    // Function to set the accumulator value, restricted to the owner
    function setAccumulator(bytes memory _acc_post) public onlyOwner {
        acc_post = _acc_post;
    }

    // Function to get the current accumulator value
    function getAccumulator() public view onlyOwner returns (bytes memory) {
        return acc_post;
    }

    // Function to get the modulus value
    function getModulus() public view onlyOwner returns (bytes memory) {
        return modulus;
    }

    // Function to set the modulus value, restricted to the owner
    function setModulus(bytes memory _modulus) public onlyOwner {
        modulus = _modulus;
    }

    // Function to verify the base with the exponent and modulus
    function verify(bytes memory base, bytes32 e) public returns (bool) {
        uint base_length = base.length;
        uint loops_base = (base_length + 31) / 32; // Calculate the number of 32-byte blocks for base
        uint modulus_length = modulus.length;
        uint loops_modulus = (modulus_length + 31) / 32; // Calculate the number of 32-byte blocks for modulus
        bytes memory _modulus = modulus;

        bytes memory p;
        assembly {
            // Define pointer
            p := mload(0x40)
            // Store the length of the base
            mstore(p, base_length)

            // Store lengths for base, exponent, and modulus
            mstore(add(p, 0x20), 0x180) // Length of Base
            mstore(add(p, 0x40), 0x20) // Length of Exponent
            mstore(add(p, 0x60), 0x180) // Length of Modulus

            // Store the base in memory
            for {
                let i := 0
            } lt(i, loops_base) {
                i := add(i, 1)
            } {
                mstore(
                    add(add(p, 0x80), mul(32, i)),
                    mload(add(base, mul(32, add(i, 1))))
                )
            }

            // Store the exponent in memory
            mstore(add(p, 0x200), e)

            // Store the modulus in memory
            for {
                let i := 0
            } lt(i, loops_modulus) {
                i := add(i, 1)
            } {
                mstore(
                    add(add(p, 0x220), mul(32, i)),
                    mload(add(_modulus, mul(32, add(i, 1))))
                )
            }

            // Call the modexp precompile
            let success := call(
                sub(gas(), 2000),
                0x05,
                0,
                add(p, 0x20),
                0x380,
                add(p, 0x20),
                0x180
            )

            // Handle failure
            switch success
            case 0 {
                revert(0, 0)
            }

            // Update the free memory pointer
            mstore(0x40, add(p, add(0x20, base_length)))
        }

        // Compare the result with the current accumulator value
        return p.equal(acc_post);
    }
}