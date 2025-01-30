// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {Delegation} from "./core//Delegation.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract DataSharing is Delegation, Ownable {
    address private _platform;

    constructor(address _setNewPlatform) Ownable(msg.sender) {
        _platform = _setNewPlatform;
    }

    modifier onlyPlatform() {
        if (msg.sender != _platform) revert AddressNotEligible();
        _;
    }

    // ======================================================================
    //                              EVENTS
    // ======================================================================
    event CreditorAddedWithMetadata(
        bytes32 indexed creditorCode,
        string institutionCode,
        string institutionName,
        string approvalDate,
        string signerName,
        string signerPosition
    );

    event DebtorAddedWithMetadata(
        bytes32 indexed nik,
        string name,
        bytes32 indexed creditorCode,
        string creditorName,
        string applicationDate,
        string approvalDate,
        string urlKTP,
        string urlApproval
    );

    event DelegationRequestedMetadata(
        bytes32 indexed nik,
        string requestId,
        bytes32 creditorConsumerCode,
        bytes32 creditorProviderCode,
        string transactionId,
        string referenceId,
        string requestDate
    );

    event PackagePurchased(
        string institutionCode,
        string purchaseDate,
        string invoiceNumber,
        uint256 packageId,
        uint256 quantity,
        string startDate,
        string endDate,
        uint256 quota
    );

    // ======================================================================
    //                              REGISTRATION
    // ======================================================================
    function addDebtor(
        bytes32 nik,
        address debtorAddress
    ) external onlyPlatform {
        _addDebtor(nik, debtorAddress);
    }

    function addCreditor(
        bytes32 creditorCode,
        address creditorAddress
    ) external onlyPlatform {
        _addCreditor(creditorCode, creditorAddress);
    }

    function addCreditor(
        address creditorAddress,
        bytes32 creditorCode,
        string memory institutionCode,
        string memory institutionName,
        string memory approvalDate,
        string memory signerName,
        string memory signerPosition
    ) external onlyPlatform {
        _addCreditor(creditorCode, creditorAddress);
        emit CreditorAddedWithMetadata(
            creditorCode,
            institutionCode,
            institutionName,
            approvalDate,
            signerName,
            signerPosition
        );
    }

    function removeCreditor(bytes32 creditorCode) external onlyPlatform {
        _removeCreditor(creditorCode);
    }

    function removeDebtor(bytes32 nik) external onlyPlatform {
        _removeDebtor(nik);
    }

    function getCreditor(bytes32 codeCreditor) external view returns (address) {
        return _getCreditor(codeCreditor);
    }

    function getDebtor(bytes32 nik) external view returns (address) {
        return _getDebtor(nik);
    }

    // ======================================================================
    //                                DELEGATION
    // ======================================================================
    function requestDelegation(
        bytes32 _nik,
        bytes32 _consumer,
        bytes32 _provider
    ) external {
        _requestDelegation(_nik, _consumer, _provider);
    }

    function requestDelegation(
        bytes32 nik,
        bytes32 _consumer,
        bytes32 _provider,
        string memory requestId,
        string memory transactionId,
        string memory referenceId,
        string memory requestDate
    ) external {
        _requestDelegation(nik, _consumer, _provider);
        emit DelegationRequestedMetadata(
            nik,
            requestId,
            _consumer,
            _provider,
            transactionId,
            referenceId,
            requestDate
        );
    }

    function delegate(
        bytes32 nik,
        bytes32 consumer,
        bytes32 provider,
        Status status
    ) external {
        _delegate(nik, consumer, provider, status);
    }

    function addDebtorToCreditor(
        bytes32 nik,
        bytes32 creditor,
        string memory name,
        string memory creditorName,
        string memory applicationDate,
        string memory approvalDate,
        string memory urlKTP,
        string memory urlApproval
    ) external onlyPlatform {
        _addCreditorForDebtor(nik, creditor);
        emit DebtorAddedWithMetadata(
            nik,
            name,
            creditor,
            creditorName,
            applicationDate,
            approvalDate,
            urlKTP,
            urlApproval
        );
    }

    function getDebtorDataActiveCreditors(
        bytes32 _nik
    ) external view returns (address[] memory, Status[] memory) {
        (
            address[] memory creditorList,
            Status[] memory statusList
        ) = _getDebtorStatuses(_nik);
        return (creditorList, statusList);
    }

    function getActiveCreditorsByStatus(
        bytes32 _nik,
        Status _status
    ) external view returns (address[] memory) {
        return _getActiveCreditorsByStatus(_nik, _status);
    }

    // ======================================================================
    //                              EVENTS
    // ======================================================================
    function purchasePackage(
        string memory institutionCode, // Hashed institution code
        string memory purchaseDate,
        string memory invoiceNumber,
        uint256 packageId,
        uint256 quantity,
        string memory startDate,
        string memory endDate,
        uint256 quota
    ) external {
        // Emit event tanpa menyimpan data ke storage
        emit PackagePurchased(
            institutionCode,
            purchaseDate,
            invoiceNumber,
            packageId,
            quantity,
            startDate,
            endDate,
            quota
        );
    }

    function setPlatform(address _setNewPlatform) external onlyOwner {
        _platform = _setNewPlatform;
    }
}
