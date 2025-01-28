// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./RSAAccumulatorVerifier.sol";

contract DIDRegistry {
    struct DIDDocument {
        string did; // Decentralized Identifier
        string ipfsCID; // IPFS CID of the DID Document
        string accumulatorValue; // RSA Accumulator Value
        string publicKey; // Public Key associated with the DID
        // address controller; // Owner of the DID
        uint256 createdAt; // Timestamp of when the DID was created
    }

    mapping(string => DIDDocument) private dids; // Map DID to DIDDocument
    // mapping(address => string) private controllers; // Map address to DID

    event DIDRegistered(string did, string ipfsCID); // Event emitted when a DID is registered
    event DIDUpdated(string did, string ipfsCID); // Event emitted when a DID is updated

    /**
     * @dev Registers a new DID.
     * @param _did The Decentralized Identifier.
     * @param _ipfsCID The IPFS CID of the DID Document.
     * @param _accumulatorValue The RSA Accumulator Value.
     * @param _publicKey The Public Key associated with the DID.
     */
    function registerDID(
        string memory _did,
        string memory _ipfsCID,
        string memory _accumulatorValue,
        string memory _publicKey
    ) external {
        // require(bytes(controllers[msg.sender]).length == 0, "Controller already has a DID");
        require(bytes(dids[_did].did).length == 0, "DID already registered");

        DIDDocument memory newDoc = DIDDocument({
            did: _did,
            ipfsCID: _ipfsCID,
            accumulatorValue: _accumulatorValue,
            publicKey: _publicKey,
            // controller: msg.sender,
            createdAt: block.timestamp
        });

        dids[_did] = newDoc;
        // controllers[msg.sender] = _did;

        emit DIDRegistered(_did, _ipfsCID);
    }

    /**
     * @dev Updates the IPFS CID of an existing DID.
     * @param _did The Decentralized Identifier.
     * @param _ipfsCID The new IPFS CID of the DID Document.
     */
    function updateDID(string memory _did, string memory _ipfsCID) external {
        DIDDocument storage doc = dids[_did];
        // require(
        //     doc.controller == msg.sender,
        //     "Only the controller can update the DID"
        // );

        doc.ipfsCID = _ipfsCID;

        emit DIDUpdated(_did, _ipfsCID);
    }

    /**
     * @dev Retrieves the DID Document associated with a given DID.
     * @param _did The Decentralized Identifier.
     * @return The DID Document.
     */
    function getDID(
        string memory _did
    ) external view returns (DIDDocument memory) {
        return dids[_did];
    }

    /**
     * @dev Retrieves the DID Document associated with a given controller address.
     * @param _controller The address of the controller.
     * @return The DID Document.
     */
    // function getDIDByController(
    //     address _controller
    // ) external view returns (DIDDocument memory) {
    //     string memory did = controllers[_controller];
    //     require(bytes(did).length != 0, "No DID found for the controller");
    //     return dids[did];
    // }
}
