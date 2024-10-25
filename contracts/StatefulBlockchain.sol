// SPDX-License-Identifier: MIT

/*

Block Header:
    > Previous Block Hash
    > Merkle Root of Transactions
    > IDC
    > Nonce
    > Meta Content -> (Node, index, timestamp, valid time, location, Datatype/Name, Producer[Signature])

*/

pragma solidity ^0.8.0;

/*
contract StatelessBlockchainWithIPFS {
    struct Transaction {
        bytes32 identityHash;
        string ipfsCID;
        bool isRevoked;
    }

    struct BlockHeader {
        bytes32 previousBlockHash; // Hash of the previous block
        bytes32 merkleRoot; // Merkle root of the transactions
        bytes32 idCommitment; // IDC (Identity Commitment)
        uint256 timestamp; // Timestamp of block creation
        uint256 nodeIndex; // Node producing the block
        bytes32 producerSignature; // Signature of the block producer
    }

    struct BlockBody {
        Transaction[] transactions; // List of identity transactions
    }

    struct Block {
        BlockHeader header; // Contains the block header
        BlockBody body; // Contains the block body with transactions
        bytes proofPreviousBlock; // NI-PoE proof for the previous block
        bytes proofCurrentBlock; // NI-PoE proof for the current block
    }

    Block[] public blockchain;

    uint256 public accumulatorBase; // Generator for RSA accumulator
    uint256 public modulus; // RSA modulus (product of two primes)

    mapping(bytes32 => uint256) public identityProofs; // Stores proofs for identity hashes
    mapping(bytes32 => bool) public revokedIdentities; // Track revoked identities
    mapping(bytes32 => string) public identityToIPFS; // Store IPFS CIDs mapped to identity hashes

    address public owner;

    event BlockCreated(
        bytes32 blockHash,
        bytes32 previousBlockHash,
        bytes32 merkleRoot,
        bytes32 idCommitment
    );
    event IdentityAdded(bytes32 indexed identityHash, string ipfsCID);
    event IdentityRevoked(bytes32 indexed identityHash, uint256 witness);

    modifier onlyOwner() {
        require(msg.sender == owner, "Not authorized");
        _;
    }

    constructor(uint256 _modulus, uint256 _accumulatorBase) {
        modulus = _modulus;
        accumulatorBase = _accumulatorBase;
        owner = msg.sender;
        // Initial block with empty accumulator and no previous block
        createBlock(0, new Transaction);
    }

    // Function to create a new block
    function createBlock(
        bytes32 _previousBlockHash,
        Transaction[] memory _transactions
    ) public onlyOwner {
        bytes32 merkleRoot = computeMerkleRoot(_transactions);
        BlockHeader memory newHeader = BlockHeader({
            previousBlockHash: _previousBlockHash,
            merkleRoot: merkleRoot,
            idCommitment: computeIDCommitment(), // Placeholder function for IDC calculation
            timestamp: block.timestamp,
            nodeIndex: getNodeIndex(), // Function to fetch node index
            producerSignature: signBlock() // Placeholder function for producer's signature
        });

        BlockBody memory newBody = BlockBody({transactions: _transactions});

        bytes memory proofPreviousBlock = computeNIPoE(_previousBlockHash);
        bytes memory proofCurrentBlock = computeNIPoE(merkleRoot);

        Block memory newBlock = Block({
            header: newHeader,
            body: newBody,
            proofPreviousBlock: proofPreviousBlock,
            proofCurrentBlock: proofCurrentBlock
        });

        blockchain.push(newBlock);
        emit BlockCreated(
            keccak256(abi.encode(newBlock)), // Compute hash of the new block
            newHeader.previousBlockHash,
            newHeader.merkleRoot,
            newHeader.idCommitment
        );
    }

    // Function to calculate the Merkle Root of all transactions in the latest block
    function computeMerkleRoot(
        Transaction[] memory _transactions
    ) private pure returns (bytes32) {
        // Logic to compute the Merkle Root (simplified for now)
        if (_transactions.length == 0) {
            return bytes32(0);
        }
        bytes32[] memory transactionHashes = new bytes32[](
            _transactions.length
        );
        for (uint256 i = 0; i < _transactions.length; i++) {
            transactionHashes[i] = keccak256(
                abi.encodePacked(
                    _transactions[i].identityHash,
                    _transactions[i].ipfsCID,
                    _transactions[i].isRevoked
                )
            );
        }
        return calculateMerkleTreeRoot(transactionHashes);
    }

    // Recursive function to calculate the Merkle Tree Root
    function calculateMerkleTreeRoot(
        bytes32[] memory hashes
    ) internal pure returns (bytes32) {
        while (hashes.length > 1) {
            if (hashes.length % 2 != 0) {
                // If odd number of transactions, duplicate the last hash
                hashes.push(hashes[hashes.length - 1]);
            }
            bytes32[] memory newLevel = new bytes32[](hashes.length / 2);
            for (uint256 i = 0; i < newLevel.length; i++) {
                newLevel[i] = keccak256(
                    abi.encodePacked(hashes[2 * i], hashes[2 * i + 1])
                );
            }
            hashes = newLevel;
        }
        return hashes[0];
    }

    // Helper function to compute the ID Commitment (IDC)
    function computeIDCommitment() private view returns (bytes32) {
        // Placeholder for computing IDC based on identity-related commitments
        return keccak256(abi.encodePacked(accumulatorBase, modulus));
    }

    // Placeholder function for generating NI-PoE proof
    function computeNIPoE(bytes32 _input) private pure returns (bytes memory) {
        // Simplified placeholder logic
        return abi.encode(_input);
    }

    // Placeholder function to sign the block
    function signBlock() private view returns (bytes32) {
        // Logic for producer to sign the block (simplified)
        return keccak256(abi.encodePacked(msg.sender, block.timestamp));
    }

    // Function to add a new identity and its corresponding IPFS CID
    function addIdentity(
        bytes32 identityHash,
        string memory ipfsCID
    ) public onlyOwner {
        require(!revokedIdentities[identityHash], "Identity is revoked");

        // Get the latest block's identity commitment (RSA accumulator)
        Block storage latestBlock = blockchain[blockchain.length - 1];
        uint256 currentAccumulator = uint256(
            latestBlock.transactions.length > 0
                ? latestBlock.transactions[0].identityHash
                : bytes32(0)
        );

        // Get the prime representative for the identity
        uint256 primeRepresentative = identityToPrime(identityHash);

        // Calculate the new accumulator: accumulator = base ^ product of all primes (mod N)
        uint256 newAccumulator = modExp(
            currentAccumulator,
            primeRepresentative,
            modulus
        );

        // Store the proof (current accumulator before adding the new identity)
        identityProofs[identityHash] = currentAccumulator;

        // Link the IPFS CID to the identity hash
        identityToIPFS[identityHash] = ipfsCID;

        // Create a new transaction
        latestBlock.transactions.push(
            Transaction(identityHash, ipfsCID, false)
        );

        // Recalculate the Merkle Root
        latestBlock.merkleRoot = calculateMerkleRoot();

        // Create a new block with the updated accumulator and transactions
        bytes32 newIdentityCommitment = bytes32(newAccumulator);
        createBlock(newIdentityCommitment, latestBlock.blockHash);

        emit IdentityAdded(identityHash, ipfsCID);
    }

    // Function to revoke an identity from the accumulator
    function revokeIdentity(bytes32 identityHash) public onlyOwner {
        require(!revokedIdentities[identityHash], "Identity already revoked");

        // Mark the identity as revoked
        revokedIdentities[identityHash] = true;

        // Get the latest block's identity commitment (RSA accumulator)
        Block storage latestBlock = blockchain[blockchain.length - 1];
        uint256 currentAccumulator = uint256(
            latestBlock.transactions.length > 0
                ? latestBlock.transactions[0].identityHash
                : bytes32(0)
        );

        // Get the prime representative for the identity
        uint256 primeRepresentative = identityToPrime(identityHash);

        // Calculate the new accumulator by dividing out the prime (modular multiplicative inverse)
        uint256 inversePrime = modExp(
            primeRepresentative,
            modulus - 2,
            modulus
        ); // Inverse mod N
        uint256 newAccumulator = modExp(
            currentAccumulator,
            inversePrime,
            modulus
        );

        // Create a new transaction for revocation
        latestBlock.transactions.push(Transaction(identityHash, "", true));

        // Recalculate the Merkle Root
        latestBlock.merkleRoot = calculateMerkleRoot();

        // Create a new block with the updated accumulator after revocation
        bytes32 newIdentityCommitment = bytes32(newAccumulator);
        createBlock(newIdentityCommitment, latestBlock.blockHash);

        emit IdentityRevoked(identityHash, currentAccumulator);
    }

    // Verify that an identity is part of the accumulator (membership proof)
    function verifyIdentity(
        bytes32 identityHash,
        uint256 witness
    ) public view returns (bool) {
        require(!revokedIdentities[identityHash], "Identity is revoked");

        // Get the latest block's accumulator
        Block storage latestBlock = blockchain[blockchain.length - 1];
        uint256 latestAccumulator = uint256(latestBlock.identityCommitment);

        // Use the identity hash as a prime representative
        uint256 primeRepresentative = identityToPrime(identityHash);

        // Calculate expected accumulator: witness ^ prime = accumulator (mod N)
        uint256 expectedAccumulator = modExp(
            witness,
            primeRepresentative,
            modulus
        );

        // Check if the calculated accumulator matches the stored accumulator
        return expectedAccumulator == latestAccumulator;
    }

    // Retrieve the IPFS CID linked to an identity
    function getIPFSCID(
        bytes32 identityHash
    ) public view returns (string memory) {
        return identityToIPFS[identityHash];
    }

    // Modular exponentiation: (base^exp) % mod
    function modExp(
        uint256 base,
        uint256 exp,
        uint256 mod
    ) internal pure returns (uint256) {
        uint256 result = 1;
        uint256 x = base % mod;
        while (exp > 0) {
            if (exp % 2 == 1) {
                result = (result * x) % mod;
            }
            exp = exp / 2;
            x = (x * x) % mod;
        }
        return result;
    }

    // Helper function to get the latest block's accumulator
    function getLatestAccumulator() public view returns (uint256) {
        Block storage latestBlock = blockchain[blockchain.length - 1];
        return uint256(latestBlock.identityCommitment);
    }

    // Function to fetch node index (placeholder)
    function getNodeIndex() private view returns (uint256) {
        return 0; // Placeholder for node index logic
    }

    // Helper function to map identity hash to a prime number
    // NOTE: This will be replaced with a secure off-chain prime hashing algorithm
    function identityToPrime(
        bytes32 identityHash
    ) internal pure returns (uint256) {
        return uint256(identityHash) | 1; // Simplified, ensures an odd number for prime likelihood
    }
}

*/