// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract DIDRegistry {
    struct DIDDocument {
        string did;
        address controller;
        string publicKey;
        bool exists;
    }

    struct VerifiableCredential {
        string credentialHash;
        address issuer;
        address holder;
        string issuanceDate;
        bool exists;
    }

    mapping(address => DIDDocument) public didRegistry;
    mapping(bytes32 => VerifiableCredential) public vcRegistry;

    event DIDRegistered(address indexed controller, string did);
    event VCIssued(address indexed issuer, address indexed holder, string credentialHash);

    // Register a DID
    function registerDID(string memory _did, string memory _publicKey) public {
        require(!didRegistry[msg.sender].exists, "DID already registered");

        didRegistry[msg.sender] = DIDDocument({
            did: _did,
            controller: msg.sender,
            publicKey: _publicKey,
            exists: true
        });

        emit DIDRegistered(msg.sender, _did);
    }

    // Issue a Verifiable Credential
    function issueVC(address _holder, string memory _credentialHash, string memory _issuanceDate) public {
        bytes32 vcId = keccak256(abi.encodePacked(_credentialHash, _holder));
        require(!vcRegistry[vcId].exists, "VC already issued");

        vcRegistry[vcId] = VerifiableCredential({
            credentialHash: _credentialHash,
            issuer: msg.sender,
            holder: _holder,
            issuanceDate: _issuanceDate,
            exists: true
        });

        emit VCIssued(msg.sender, _holder, _credentialHash);
    }

    // Verify a Verifiable Credential
    function verifyVC(string memory _credentialHash, address _holder) public view returns (bool) {
        bytes32 vcId = keccak256(abi.encodePacked(_credentialHash, _holder));
        return vcRegistry[vcId].exists;
    }

    // Get a registered DID
    function getDID(address _controller) public view returns (string memory did, string memory publicKey) {
        require(didRegistry[_controller].exists, "DID not registered");
        DIDDocument memory didDoc = didRegistry[_controller];
        return (didDoc.did, didDoc.publicKey);
    }
}
