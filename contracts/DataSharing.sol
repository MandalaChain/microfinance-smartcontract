// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract DataSharing is Ownable {
    using ECDSA for bytes32;

    // Events
    event RequestSubmitted(address indexed requester, bytes32 indexed hashedNIK, uint256 timestamp);
    event ApprovalLogged(bytes32 indexed hashedNIK, address indexed approver, uint256 timestamp);
    event DataAccessed(bytes32 indexed hashedNIK, address indexed requester, uint256 timestamp);

    // Custom Errors
    error InvalidPermission();
    error InvalidHash();
    error UnauthorizedAccess();

    struct Request {
        address requester;
        bytes32 hashedNIK;
        bool approved;
        uint256 timestamp;
    }

    mapping(bytes32 => Request) private requests;
    mapping(bytes32 => address) private dataOwners;

    constructor() Ownable(msg.sender) {}

    // Modifier to check if the caller is the owner of the data
    modifier onlyDataOwner(bytes32 hashedNIK) {
        if (dataOwners[hashedNIK] != msg.sender) revert UnauthorizedAccess();
        _;
    }

    // Submit a data request
    function submitRequest(bytes32 hashedNIK) external {
        if (hashedNIK == bytes32(0)) revert InvalidHash();

        requests[hashedNIK] = Request({
            requester: msg.sender,
            hashedNIK: hashedNIK,
            approved: false,
            timestamp: block.timestamp
        });

        emit RequestSubmitted(msg.sender, hashedNIK, block.timestamp);
    }

    // Approve a data request
    function approveRequest(bytes32 hashedNIK) external onlyDataOwner(hashedNIK) {
        Request storage request = requests[hashedNIK];

        if (request.requester == address(0)) revert InvalidPermission();

        request.approved = true;
        emit ApprovalLogged(hashedNIK, msg.sender, block.timestamp);
    }

    // Access data (with logging)
    function accessData(bytes32 hashedNIK) external {
        Request memory request = requests[hashedNIK];

        if (!request.approved) revert UnauthorizedAccess();

        emit DataAccessed(hashedNIK, msg.sender, block.timestamp);
    }

    // Register data owner
    function registerDataOwner(bytes32 hashedNIK, address owner) external onlyOwner {
        if (dataOwners[hashedNIK] != address(0)) revert InvalidPermission();
        dataOwners[hashedNIK] = owner;
    }

    // Retrieve log details
    function getRequestDetails(bytes32 hashedNIK) external view returns (Request memory) {
        return requests[hashedNIK];
    }

    // Retrieve owner of the hashed NIK
    function getDataOwner(bytes32 hashedNIK) external view returns (address) {
        return dataOwners[hashedNIK];
    }
}
