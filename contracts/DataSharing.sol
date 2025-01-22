// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {Delegation} from "./core//Delegation.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract DataSharing is Delegation {
    constructor(address _setNewPlatform) Ownable(msg.sender) {
        _setPlatform(_setNewPlatform);
    }

    // ======================================================================
    //                              REGISTRATION
    // ======================================================================
    function addDebtor(bytes32 nik, address debtorAddress) external {
        _addDebtor(nik, debtorAddress);
    }

    function addCreditor(address creditorAddress) external {
        _addCreditor(creditorAddress);
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
        address _creditor,
        string calldata _metadata
    ) external {
        _requestDelegation(_nik, _creditor, _metadata);
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
        address creditor
    ) external onlyPlatform {
        _addCreditorForDebtor(nik, creditor);
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
