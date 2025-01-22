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
        address indexed creditorAddress,
        string institutionCode,
        string institutionName,
        string approvalDate,
        string signerName,
        string signerPosition
    );

    event DebtorAddedWithMetadata(
        bytes32 indexed nik,
        string name,
        string creditorCode,
        string creditorName,
        string applicationDate,
        string approvalDate,
        string urlKTP,
        string urlApproval
    );

    event DelegationRequestedMetadata(
        bytes32 indexed nik,
        string requestId,
        string nikDebtor,
        string creditorCode,
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

    function addCreditor(address creditorAddress) external {
        _addCreditor(creditorAddress);
    }

    function addCreditor(
        address creditorAddress,
        string memory institutionCode,
        string memory institutionName,
        string memory approvalDate,
        string memory signerName,
        string memory signerPosition
    ) external {
        _addCreditor(creditorAddress);
        emit CreditorAddedWithMetadata(
            creditorAddress,
            institutionCode,
            institutionName,
            approvalDate,
            signerName,
            signerPosition
        );
    }

    function removeCreditor(address creditorAddress) external {
        _removeCreditor(creditorAddress);
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
        address _creditor
    ) external {
        _requestDelegation(_nik, _creditor);
    }

    function requestDelegation(
        bytes32 nik,
        address creditor,
        string memory requestId,
        string memory nikDebtor,
        string memory creditorCode,
        string memory transactionId,
        string memory referenceId,
        string memory requestDate
    ) external {
        _requestDelegation(nik, creditor);
        emit DelegationRequestedMetadata(
            nik,
            requestId,
            nikDebtor,
            creditorCode,
            transactionId,
            referenceId,
            requestDate
        );
    }

    function delegate(
        bytes32 _nik,
        address _consumer,
        Status _status
    ) external {
        _delegate(_nik, _consumer, _status);
    }

    function addDebtorToCreditor(
        bytes32 nik,
        address creditor,
        string memory name,
        string memory creditorCode,
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
            creditorCode,
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
