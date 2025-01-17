// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract DataSharingPlatform is Ownable {
    using ECDSA for bytes32;

    // Events
    event RequestToCustomer(address indexed requester, address indexed customer, bytes32 indexed hashedNIK, uint256 timestamp);
    event RequestToProvider(address indexed requester, address indexed provider, bytes32 indexed hashedNIK, uint256 timestamp);
    event DataAccess(address indexed requester, address indexed provider, bytes32 indexed hashedNIK, uint256 timestamp);
    event ActiveProviderAdded(bytes32 indexed hashedNIK, address indexed provider);

    // Custom Errors
    error InvalidPermission();
    error InvalidHash();
    error UnauthorizedAccess();
    error InvalidAddress();
    error AlreadyApproved();

    enum StatusShared {
        Pending,
        Approved,
        Rejected
    }

    struct Status {
        StatusShared statusCustomer;
        StatusShared statusProvider;
    }

    struct Metadata {
        string requestApproval;
        string requestDelegation;
        string approve;
        string delegate;
    }

    struct Request {
        bytes32 hashedNIK;
        address customer;
        address requester;
        address provider;
        Status status;
        Metadata metadata;
    }

    mapping(address => mapping(address => Request)) private _log;
    // Mapping verifier providers
    mapping(address => bool) private _activeProviders;

    constructor() Ownable(msg.sender) {}

    function _onlyActiveProvider() private view { // This function combine with Paket festure from the platform
        if (_activeProviders[msg.sender] != true) revert UnauthorizedAccess();
    }

    function _checkNikAndWallet(bytes32 hashedNIK, address wallet) private pure {
        if (hashedNIK == bytes32(0)) revert InvalidHash();
        if (wallet == address(0)) revert InvalidAddress();
    }

    // Tambah log permintaan ke Customer
    function requestApproval(
        address customer,
        bytes32 hashedNIK,
        string memory metadata
    ) external {
        _onlyActiveProvider();
        _checkNikAndWallet(hashedNIK, customer);
        if (_log[msg.sender][customer].statusCustomer != StatusShared.Approved) revert AlreadyApproved();

        _log[msg.sender][customer].customer = customer;
        _log[msg.sender][customer].requester = msg.sender;
        _log[msg.sender][customer].statusCustomer = StatusShared.Pending;
        _log[msg.sender][customer].metadata.requestApproval = metadata;

        emit RequestToCustomer(msg.sender, customer, hashedNIK, block.timestamp);
    }

    // Tambah log permintaan ke penyedia data
    function requestDelegation(
        address provider,
        bytes32 hashedNIK,
        string memory metadata
    ) external {
        _onlyActiveProvider();
        _checkNikAndWallet(hashedNIK, provider);
        if (_log[msg.sender][provider].statusProvider != StatusShared.Approved) revert AlreadyApproved();

        _log[msg.sender][provider].provider = provider;
        _log[msg.sender][provider].statusProvider = StatusShared.Pending;
        _log[msg.sender][provider].metadata.requestDelegation = metadata;

        emit RequestToProvider(msg.sender, provider, hashedNIK, block.timestamp);
    }

    // function approve(address requester, string memory metadata) external {
    //     Log memory log = _logCustomer[msg.sender][requester];
    //     if (log.status != StatusShared.Pending) revert InvalidPermission();
    
    // }

    // Log akses data
    // function logDataAccess(
    //     bytes32 hashedNIK,
    //     address requester,
    //     address provider
    // ) external {
    //     if (hashedNIK == bytes32(0) || requester == address(0) || provider == address(0)) revert InvalidHash();

    //     transactionLogs[hashedNIK].push(MetadataLog({
    //         requester: requester,
    //         provider: provider,
    //         hashedNIK: hashedNIK,
    //         approved: true,
    //         timestamp: block.timestamp
    //     }));

    //     emit DataAccess(requester, provider, hashedNIK, block.timestamp);
    // }

    // Tambahkan penyedia data aktif
    // function addActiveProvider(bytes32 hashedNIK, address provider) internal {
    //     if (provider == address(0)) revert InvalidHash();
    //     activeProviders[hashedNIK][provider] = true;
    //     emit ActiveProviderAdded(hashedNIK, provider);
    // }

    // // Periksa apakah penyedia aktif
    // function isActiveProvider(bytes32 hashedNIK, address provider) external view returns (bool) {
    //     return activeProviders[hashedNIK][provider];
    // }

    // // Ambil semua log transaksi untuk hashed NIK tertentu
    // function getTransactionLogs(bytes32 hashedNIK) external view returns (MetadataLog[] memory) {
    //     return transactionLogs[hashedNIK];
    // }
}
