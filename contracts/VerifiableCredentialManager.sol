// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./DIDRegistry.sol";

contract VerifiableCredentialManager {
    struct VerifiableCredential {
        string did;
        string vcHash; // Hash of the Verifiable Credential
        string ipfsCID; // IPFS CID of the Verifiable Credential document
        uint256 issuedAt;
    }

    DIDRegistry private didRegistry;
    mapping(string => VerifiableCredential[]) private vcStore; // DID to its issued VCs

    event VCIssued(string did, string vcHash, string ipfsCID);

    constructor(address _didRegistryAddress) {
        didRegistry = DIDRegistry(_didRegistryAddress);
    }

    function issueVC(
        string memory _did,
        string memory _vcHash,
        string memory _ipfsCID
    ) external {
        DIDRegistry.DIDDocument memory didDoc = didRegistry.getDID(_did);
        require(
            didDoc.controller == msg.sender,
            "Only the DID controller can issue a VC"
        );

        vcStore[_did].push(
            VerifiableCredential({
                did: _did,
                vcHash: _vcHash,
                ipfsCID: _ipfsCID,
                issuedAt: block.timestamp
            })
        );

        emit VCIssued(_did, _vcHash, _ipfsCID);
    }

    function getVCs(
        string memory _did
    ) external view returns (VerifiableCredential[] memory) {
        return vcStore[_did];
    }

    function verifyVC(
        string memory _did,
        string memory _vcHash
    ) external view returns (bool) {
        VerifiableCredential[] memory vcs = vcStore[_did];
        for (uint256 i = 0; i < vcs.length; i++) {
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
