// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./BytesLib.sol";

interface IStatelessBlockchain {
    function verifyIdentity(
        address user,
        uint256 identityCredential
    ) external returns (bool);
}

interface IDIDRegistry {
    function getDID(
        address _controller
    ) external view returns (string memory did);
}

contract RSAAccumulator {
    using BytesLib for bytes;

    bytes acc_post;
    bytes modulus;
    address public owner;
    IStatelessBlockchain public statelessBlockchain;
    IDIDRegistry public didRegistry;

    constructor(
        bytes memory _modulus,
        bytes memory _acc_post,
        address statelessBlockchainAddress,
        address didRegistryAddress
    ) {
        acc_post = _acc_post;
        modulus = _modulus;
        owner = msg.sender;
        statelessBlockchain = IStatelessBlockchain(statelessBlockchainAddress);
        didRegistry = IDIDRegistry(didRegistryAddress);
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can perform this action");
        _;
    }

    function updateAccumulator(bytes memory newAccPost) public onlyOwner {
        acc_post = newAccPost;
    }

    function verify(bytes memory base, bytes32 e) public returns (bool) {
        // Count the loops required for base (blocks of 32 bytes)
        uint base_length = base.length;
        uint loops_base = (base_length + 31) / 32;
        // Count the loops required for modulus (blocks of 32 bytes)
        uint modulus_length = modulus.length;
        uint loops_modulus = (modulus_length + 31) / 32;
        bytes memory _modulus = modulus;

        bytes memory p;
        // are all of these inside the precompile now?
        assembly {
            // define pointer
            p := mload(0x40)
            // store data assembly-favouring ways
            mstore(p, base_length)

            mstore(add(p, 0x20), 0x180) // Length of Base
            mstore(add(p, 0x40), 0x20) // Length of Exponent
            mstore(add(p, 0x60), 0x180) // Length of Modulus

            // NOTE:: Going to Solidity 8.0 swapped pos for add(1,i) to add(i,1)
            for {
                let i := 0
            } lt(i, loops_base) {
                i := add(i, 1)
            } {
                mstore(
                    add(add(p, 0x80), mul(32, i)),
                    mload(add(base, mul(32, add(i, 1))))
                )
            } // Base

            mstore(add(p, 0x200), e) // Exponent

            // Add the contents of b to the array. NOTE:: Going to Solidity 8.0 swapped pos for add(1,i) to add(i,1)
            for {
                let i := 0
            } lt(i, loops_modulus) {
                i := add(i, 1)
            } {
                mstore(
                    add(add(p, 0x220), mul(32, i)),
                    mload(add(_modulus, mul(32, add(i, 1))))
                )
            } // Modulus

            // call modexp precompile!
            let success := call(
                sub(gas(), 2000),
                0x05,
                0,
                add(p, 0x20),
                0x380,
                add(p, 0x20),
                0x180
            )

            // gas fiddling
            switch success
            case 0 {
                revert(0, 0)
            }
            // data
            mstore(0x40, add(p, add(0x20, base_length)))
            // o := p
        }

        return p.equal(acc_post);
    }

    function verifyIdentityWithStatelessBlockchain(
        address user,
        uint256 identityCredential
    ) public returns (bool) {
        return statelessBlockchain.verifyIdentity(user, identityCredential);
    }

    function getDID(address _controller) public view returns (string memory) {
        return didRegistry.getDID(_controller);
    }
}
