// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract DIDRegistry {
    struct PublicKey {
        string id; // e.g., "did:example:123#keys-1"
        string typeKey; // e.g., "EcdsaSecp256k1VerificationKey2019"
        string publicKeyHex; // Hex representation of the public key
    }

    struct Service {
        string id; // Unique identifier for the service
        string typeServ; // Type of service, e.g., "LinkedDomains", "PeerService"
        string serviceEndpoint; // URL or endpoint of the service
    }

    struct DIDDocument {
        string did; // Decentralized Identifier
        address controller; // Address of the controller
        mapping(uint256 => PublicKey) publicKeys; // Mapping of public keys
        mapping(uint256 => Service) services; // Mapping of services
        uint256 publicKeyCount; // Count of public keys
        uint256 serviceCount; // Count of services
        bool exists; // Check if DID is registered
    }

    struct Claim {
        string claimType; // e.g., "email", "phoneNumber"
        string claimValue; // Value of the claim
    }

    struct VerifiableCredential {
        string context; // Context of the credential, e.g., W3C VC context
        string typeVC; // Type of the credential, e.g., "VerifiableCredential"
        string issuer; // Issuer's DID or address (in string format)
        address holder; // Address of the holder
        string issuanceDate; // Date of issuance
        string expirationDate; // Optional expiration date
        string proof; // Cryptographic proof (could be a signature)
        bool exists; // Check if VC is issued
    }

    // Mappings to store DIDs and VCs
    mapping(address => DIDDocument) public didRegistry; // Maps controller addresses to DID documents
    mapping(bytes32 => VerifiableCredential) public vcRegistry; // Maps VC hashes to Verifiable Credentials
    mapping(bytes32 => mapping(uint256 => Claim)) public claimsRegistry; // Maps VC hashes to individual claims
    mapping(bytes32 => uint256) public claimCount; // Maps VC hashes to the number of claims

    // Events to log actions
    event DIDRegistered(address indexed controller, string did);
    event VCIssued(address indexed issuer, address indexed holder, string credentialHash);

    // Register a DID
    function registerDID(
        string memory _did,
        PublicKey[] memory _publicKeys,
        Service[] memory _services
    ) public {
        require(!didRegistry[msg.sender].exists, "DID already registered");

        didRegistry[msg.sender].did = _did;
        didRegistry[msg.sender].controller = msg.sender;
        didRegistry[msg.sender].exists = true;

        // Store public keys
        for (uint256 i = 0; i < _publicKeys.length; i++) {
            didRegistry[msg.sender].publicKeys[didRegistry[msg.sender].publicKeyCount++] = _publicKeys[i];
        }

        // Store services
        for (uint256 i = 0; i < _services.length; i++) {
            didRegistry[msg.sender].services[didRegistry[msg.sender].serviceCount++] = _services[i];
        }

        emit DIDRegistered(msg.sender, _did);
    }

    // Issue a Verifiable Credential
    function issueVC(
        address _holder,
        string memory _context,
        string memory _typeVC,
        string memory _issuanceDate,
        string memory _expirationDate,
        Claim[] memory _claims,
        string memory _proof
    ) public {
        bytes32 vcId = keccak256(abi.encodePacked(_context, _holder, _issuanceDate));
        require(!vcRegistry[vcId].exists, "VC already issued");

        // Store claims in the mapping one by one
        for (uint256 i = 0; i < _claims.length; i++) {
            claimsRegistry[vcId][i] = _claims[i];
        }
        claimCount[vcId] = _claims.length; // Store the number of claims

        // Store the VC document
        vcRegistry[vcId] = VerifiableCredential({
            context: _context,
            typeVC: _typeVC,
            issuer: addressToString(msg.sender), // Convert address to string
            holder: _holder,
            issuanceDate: _issuanceDate,
            expirationDate: _expirationDate,
            proof: _proof,
            exists: true
        });

        emit VCIssued(msg.sender, _holder, string(abi.encodePacked(vcId)));
    }

    // Convert an address to a string
    function addressToString(address _addr) internal pure returns (string memory) {
        bytes32 value = bytes32(uint256(uint160(_addr)));
        bytes memory alphabet = "0123456789abcdef";

        bytes memory str = new bytes(42);
        str[0] = '0';
        str[1] = 'x';
        for (uint256 i = 0; i < 20; i++) {
            str[2 + i * 2] = alphabet[uint8(value[i + 12] >> 4)];
            str[3 + i * 2] = alphabet[uint8(value[i + 12] & 0x0f)];
        }
        return string(str);
    }

    // Verify a Verifiable Credential
    function verifyVC(
        string memory _context,
        address _holder,
        string memory _issuanceDate
    ) public view returns (bool) {
        bytes32 vcId = keccak256(abi.encodePacked(_context, _holder, _issuanceDate));
        return vcRegistry[vcId].exists;
    }

    // Get a registered DID
    function getDID(address _controller) public view returns (
        string memory did,
        PublicKey[] memory publicKeys,
        Service[] memory services
    ) {
        require(didRegistry[_controller].exists, "DID not registered");
        DIDDocument storage didDoc = didRegistry[_controller];
        PublicKey[] memory keys = new PublicKey[](didDoc.publicKeyCount);
        for (uint256 i = 0; i < didDoc.publicKeyCount; i++) {
            keys[i] = didDoc.publicKeys[i];
        }

        Service[] memory servs = new Service[](didDoc.serviceCount);
        for (uint256 i = 0; i < didDoc.serviceCount; i++) {
            servs[i] = didDoc.services[i];
        }

        return (didDoc.did, keys, servs);
    }

    // Get claims for a Verifiable Credential
    function getClaims(string memory _context, address _holder, string memory _issuanceDate) public view returns (Claim[] memory) {
        bytes32 vcId = keccak256(abi.encodePacked(_context, _holder, _issuanceDate));
        uint256 count = claimCount[vcId];
        Claim[] memory claims = new Claim[](count);
        for (uint256 i = 0; i < count; i++) {
            claims[i] = claimsRegistry[vcId][i];
        }
        return claims;
    }
}
