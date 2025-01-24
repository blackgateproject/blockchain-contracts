// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./DIDRegistry.sol";

contract VerifiableCredentialManager {
    // Structure to store Verifiable Credential details
    struct VerifiableCredential {
        string did; // Decentralized Identifier
        string vcHash; // Hash of the Verifiable Credential
        string ipfsCID; // IPFS CID of the Verifiable Credential document
        uint256 issuedAt; // Timestamp when the VC was issued
    }

    DIDRegistry private didRegistry; // Instance of the DIDRegistry contract
    mapping(string => VerifiableCredential[]) private vcStore; // Mapping from DID to its issued VCs

    // Event emitted when a new VC is issued
    event VCIssued(string did, string vcHash, string ipfsCID);

    // Constructor to initialize the DIDRegistry contract address
    constructor(address _didRegistryAddress) {
        didRegistry = DIDRegistry(_didRegistryAddress);
    }

    // Function to issue a new Verifiable Credential
    function issueVC(
        string memory _did,
        string memory _vcHash,
        string memory _ipfsCID
    ) external {
        // Fetch the DID document from the DIDRegistry
        DIDRegistry.DIDDocument memory didDoc = didRegistry.getDID(_did);

        // Ensure that the caller is the controller of the DID
        /*
        require(
            didDoc.controller == msg.sender,
            "Only the DID controller can issue a VC"
        );
        */

        // Store the new Verifiable Credential in the vcStore mapping
        vcStore[_did].push(
            VerifiableCredential({
                did: _did,
                vcHash: _vcHash,
                ipfsCID: _ipfsCID,
                issuedAt: block.timestamp
            })
        );

        // Emit the VCIssued event
        emit VCIssued(_did, _vcHash, _ipfsCID);
    }

    // Function to retrieve all Verifiable Credentials for a given DID
    function getVCs(
        string memory _did
    ) external view returns (VerifiableCredential[] memory) {
        return vcStore[_did];
    }

    // Function to verify if a given VC hash exists for a given DID
    function verifyVC(
        string memory _did,
        string memory _vcHash
    ) external view returns (bool) {
        VerifiableCredential[] memory vcs = vcStore[_did];

        // Iterate through all VCs for the given DID
        for (uint256 i = 0; i < vcs.length; i++) {
            // Compare the hash of the stored VC with the provided VC hash
            if (
                keccak256(abi.encodePacked(vcs[i].vcHash)) ==
                keccak256(abi.encodePacked(_vcHash))
            ) {
                return true;
            }
        }
        return false;
    }
}
