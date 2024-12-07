// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IStatelessBlockchain {
    function verifyIdentity(
        address user,
        uint256 identityCredential
    ) external returns (bool);
}

interface IRSAAccumulator {
    function verify(bytes memory base, bytes32 e) external returns (bool);
}

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
    event VCIssued(
        address indexed issuer,
        address indexed holder,
        string credentialHash
    );

    IStatelessBlockchain public statelessBlockchain;
    IRSAAccumulator public rsaAccumulator;

    constructor(address statelessBlockchainAddress) {
        statelessBlockchain = IStatelessBlockchain(statelessBlockchainAddress);
    }

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
            didRegistry[msg.sender].publicKeys[
                didRegistry[msg.sender].publicKeyCount++
            ] = _publicKeys[i];
        }

        // Store services
        for (uint256 i = 0; i < _services.length; i++) {
            didRegistry[msg.sender].services[
                didRegistry[msg.sender].serviceCount++
            ] = _services[i];
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
        bytes32 vcId = keccak256(
            abi.encodePacked(_context, _holder, _issuanceDate)
        );
        require(!vcRegistry[vcId].exists, "VC already issued");
        require(_claims.length > 0, "Claims are required");

        // Store claims in the mapping
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
            expirationDate: _expirationDate, // Properly store expiration date
            proof: _proof,
            exists: true
        });

        emit VCIssued(msg.sender, _holder, string(abi.encodePacked(vcId)));
    }

    // Convert an address to a string
    function addressToString(
        address _addr
    ) internal pure returns (string memory) {
        bytes32 value = bytes32(uint256(uint160(_addr)));
        bytes memory alphabet = "0123456789abcdef";

        bytes memory str = new bytes(42);
        str[0] = "0";
        str[1] = "x";
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
        bytes32 vcId = keccak256(
            abi.encodePacked(_context, _holder, _issuanceDate)
        );
        VerifiableCredential memory vc = vcRegistry[vcId];

        // Check if the VC exists
        if (!vc.exists) {
            return false;
        }

        // Check for expiration
        if (bytes(vc.expirationDate).length > 0) {
            uint256 expirationTimestamp = parseTimestamp(vc.expirationDate);
            return block.timestamp <= expirationTimestamp;
        }
        return true; // If no expiration date, it's valid
    }

    // Verify a DID using a Verifiable Credential
    function verifyDID(
        string memory _context,
        address _holder,
        string memory _issuanceDate,
        string memory _proof
    ) public view returns (bool) {
        bytes32 vcId = keccak256(
            abi.encodePacked(_context, _holder, _issuanceDate)
        );
        VerifiableCredential memory vc = vcRegistry[vcId];

        // Check if the VC exists
        if (!vc.exists) {
            return false;
        }

        // Verify the proof (signature)
        return
            keccak256(abi.encodePacked(vc.proof)) ==
            keccak256(abi.encodePacked(_proof));
    }

    // Get a registered DID
    function getDID(
        address _controller
    )
        public
        view
        returns (
            string memory did,
            PublicKey[] memory publicKeys,
            Service[] memory services
        )
    {
        require(didRegistry[_controller].exists, "DID not registered");
        DIDDocument storage didDoc = didRegistry[_controller];
        PublicKey[] memory keys = new PublicKey[](didDoc.publicKeyCount);
        Service[] memory servs = new Service[](didDoc.serviceCount);

        // Copy public keys
        for (uint256 i = 0; i < didDoc.publicKeyCount; i++) {
            keys[i] = didDoc.publicKeys[i];
        }

        // Copy services
        for (uint256 i = 0; i < didDoc.serviceCount; i++) {
            servs[i] = didDoc.services[i];
        }

        return (didDoc.did, keys, servs);
    }

    // Get claims for a given Verifiable Credential
    function getClaims(
        string memory _context,
        address _holder,
        string memory _issuanceDate
    ) public view returns (Claim[] memory) {
        bytes32 vcId = keccak256(
            abi.encodePacked(_context, _holder, _issuanceDate)
        );
        uint256 count = claimCount[vcId];

        Claim[] memory claims = new Claim[](count);
        for (uint256 i = 0; i < count; i++) {
            claims[i] = claimsRegistry[vcId][i];
        }

        return claims;
    }

    // Function to parse a timestamp string
    function parseTimestamp(
        string memory dateString
    ) internal pure returns (uint256) {
        bytes memory dateBytes = bytes(dateString);
        require(
            dateBytes.length == 20,
            "Invalid date format: Expected YYYY-MM-DDTHH:MM:SSZ"
        );

        // Extract year, month, day, hour, minute, second
        uint256 year = parseUint(dateBytes, 0, 4);
        uint256 month = parseUint(dateBytes, 5, 2);
        uint256 day = parseUint(dateBytes, 8, 2);
        uint256 hour = parseUint(dateBytes, 11, 2);
        uint256 minute = parseUint(dateBytes, 14, 2);
        uint256 second = parseUint(dateBytes, 17, 2);

        // Simple validation for month and day
        require(month >= 1 && month <= 12, "Invalid month");
        require(day >= 1 && day <= 31, "Invalid day"); // Consider adding logic for specific month days

        // Calculate the timestamp (this is still a simplified calculation)
        uint256 timestamp = (year - 1970) *
            365 days +
            (month - 1) *
            30 days +
            (day - 1) *
            1 days +
            hour *
            1 hours +
            minute *
            1 minutes +
            second *
            1 seconds;

        return timestamp;
    }

    // Function to parse a substring into a uint
    function parseUint(
        bytes memory b,
        uint256 start,
        uint256 length
    ) internal pure returns (uint256) {
        uint256 result = 0;
        for (uint256 i = start; i < start + length; i++) {
            result = result * 10 + (uint8(b[i]) - 48); // ASCII '0' = 48
        }
        return result;
    }

    function verifyIdentityWithStatelessBlockchain(
        address user,
        uint256 identityCredential
    ) public returns (bool) {
        return statelessBlockchain.verifyIdentity(user, identityCredential);
    }

    function verifyWithRSAAccumulator(
        bytes memory base,
        bytes32 e
    ) public returns (bool) {
        return rsaAccumulator.verify(base, e);
    }
}
