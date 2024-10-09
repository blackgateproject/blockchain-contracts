// SPDX-License-Identifier: MIT
// AWAIS:: Init System w ECC params

pragma solidity ^0.8.0;

contract SysSetup {
    address public systemOwner;
    string public curveName = "secp256k1"; // Using secp256k1 curve
    uint256 public groupOrder;

    constructor() {
        systemOwner = msg.sender;
        groupOrder = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141; // secp256k1 group order
    }
}
