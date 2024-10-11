// SPDX-License-Identifier: MIT
// AWAIS:: Generates and stores the key pairs for users.
pragma solidity ^0.8.0;

contract SysKeyGen {
    mapping(address => bytes32) public publicKey;
    mapping(address => bytes32) private privateKey;

    function generateKeys(bytes32 _privateKey, bytes32 _publicKey) external {
        privateKey[msg.sender] = _privateKey;
        publicKey[msg.sender] = _publicKey;
    }

    function getPublicKey(address owner) external view returns (bytes32) {
        return publicKey[owner];
    }

    function getPrivateKey(address owner) external view returns (bytes32) {
        require(msg.sender == owner, "Not authorized to view private key");
        return privateKey[owner];
    }
}
