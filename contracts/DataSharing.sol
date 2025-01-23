// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {Delegation} from "./core//Delegation.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract DataSharing is Delegation {
    constructor(address _setNewPlatform) Ownable(msg.sender) {
        _setPlatform(_setNewPlatform);
    }

    // ======================================================================
    //                              EVENTS
    // ======================================================================
    event CreditorAddedWithMetadata(
        bytes32 indexed creditorAddress,
        string institutionCode,
        string institutionName,
        string approvalDate,
        string signerName,
        string signerPosition
    );

    event DebtorAddedWithMetadata(
        bytes32 indexed nik,
        string name,
        bytes32 creditorCode,
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

    // ======================================================================
    //                              REGISTRATION
    // ======================================================================
    function addDebtor(bytes32 nik, address debtorAddress) external {
        _addDebtor(nik, debtorAddress);
    }

    function addCreditor(
        bytes32 creditorCode,
        address creditorAddress
    ) external {
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
    ) external {
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

    function removeCreditor(bytes32 creditorCode) external {
        _removeCreditor(creditorCode);
    }

    function removeDebtor(bytes32 nik) external {
        _removeDebtor(nik);
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
        bytes32 _nik,
        bytes32 _consumer,
        bytes32 _provider,
        Status _status
    ) external {
        _delegate(_nik, _consumer, _provider, _status);
    }

    function addDebtorToCreditor(
        bytes32 nik,
        bytes32 creditor,
        address creditorAddress,
        string memory name,
        string memory creditorName,
        string memory applicationDate,
        string memory approvalDate,
        string memory urlKTP,
        string memory urlApproval
    ) external onlyPlatform {
        _addCreditorForDebtor(nik, creditorAddress);
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
}
