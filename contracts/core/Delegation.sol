/*
 * SPDX-License-Identifier: MIT
 *
 * @title Delegation Contract
 * @dev This contract extends the `Registration` contract and manages delegation requests
 *      between creditors for a specific debtor. It provides internal functions to request,
 *      approve, and manage delegation relationships.
 *
 * ## Features:
 * - Creditor delegation requests for debtors.
 * - Approval and rejection workflow for delegation requests.
 * - Mapping-based storage for efficient lookups.
 *
 * @custom:error NikNeedRegistered      - Thrown when the provided NIK is not yet registered.
 * @custom:error RequestAlreadyExist    - Thrown when a similar pending request already exists.
 * @custom:error ProviderNotEligible    - Thrown when the provider is not in an approved status.
 * @custom:error InvalidStatusApproveRequest - Thrown when attempting to approve/reject a non-pending request.
 * @custom:error AddressNotEligible     - Thrown when the caller does not match the required address (consumer or provider).
 * @custom:error InvalidHash            - Thrown when one of the provided identifiers (NIK/creditor code) is invalid (zero).
 */

pragma solidity ^0.8.20;

import {Registration} from "./Registration.sol";

/**
 * @title Delegation
 * @notice Handles delegation request logic between creditors for a specific debtor (identified by NIK).
 * @dev Inherits from the `Registration` contract to access debtors and creditors mappings.
 */
abstract contract Delegation is Registration {
    // ------------------------------------------------------------------------
    //                              Custom Errors
    // ------------------------------------------------------------------------
    error NikNeedRegistered();
    error RequestAlreadyExist();
    error ProviderNotEligible();
    error InvalidStatusApproveRequest();
    error AddressNotEligible();

    // ------------------------------------------------------------------------
    //                                 Enums
    // ------------------------------------------------------------------------
    /**
     * @dev Status represents the state of a request or a creditor's relationship to a debtor.
     *      - REJECTED: The request was denied.
     *      - APPROVED: The request was approved (or the creditor was manually added).
     *      - PENDING:  The request is awaiting approval or rejection.
     */
    enum Status {
        REJECTED,
        APPROVED,
        PENDING
    }

    // ------------------------------------------------------------------------
    //                              Structures
    // ------------------------------------------------------------------------
    /**
     * @dev Request holds details about a delegation request from one creditor (consumer)
     *      to another creditor (provider) for a specific debtor (identified by `nik`).
     */
    struct Request {
        Status status;
        bytes32 nik;
    }

    /**
     * @dev DebtorInfo contains all creditors related to a single debtor,
     *      mapping each creditor's address to a `Status`, and storing a list of those creditor addresses.
     */
    struct DebtorInfo {
        mapping(address => Status) creditorStatus;
        address[] creditors;
        // @notice You can add more metadata here if needed.
    }

    // ------------------------------------------------------------------------
    //                         Contract State Variables
    // ------------------------------------------------------------------------
    /**
     * @dev Maps a debtor's address to their `DebtorInfo`, which holds each creditor's status for that debtor.
     */
    mapping(address => DebtorInfo) private _debtorInfo;

    /**
     * @dev Stores delegation requests in a nested mapping:
     *      _request[consumer][provider] => Request({ status, nik })
     */
    mapping(address => mapping(address => Request)) private _request;

    // ------------------------------------------------------------------------
    //                                Events
    // ------------------------------------------------------------------------
    /**
     * @notice Emitted when a delegation request is processed (approved or rejected).
     * @param nik                   The unique identifier for the debtor (NIK).
     * @param creditorConsumerCode  The code (hashed) of the creditor acting as consumer.
     * @param creditorProviderCode  The code (hashed) of the creditor acting as provider.
     * @param status                The final status of the request (APPROVED or REJECTED).
     */
    event Delegate(
        bytes32 indexed nik,
        bytes32 indexed creditorConsumerCode,
        bytes32 indexed creditorProviderCode,
        Status status
    );

    // ------------------------------------------------------------------------
    //                          Internal Functions
    // ------------------------------------------------------------------------

    /**
     * @dev Retrieves the DebtorInfo of a specific debtor based on their NIK
     *      and the corresponding address from `_debtors`.
     * @param _nik The unique identifier (hashed) for the debtor.
     * @return debtorInfo The storage reference to the `DebtorInfo` structure.
     * @return nikAddress The address associated with the given `_nik`.
     * @notice Reverts with `NikNeedRegistered` if the debtor is not registered.
     */
    function _getCustomerStoraget(
        bytes32 _nik
    ) private view returns (DebtorInfo storage debtorInfo, address nikAddress) {
        address _nikAddress = _debtors[_nik];
        if (_nikAddress == address(0)) revert NikNeedRegistered();
        return (_debtorInfo[_nikAddress], _nikAddress);
    }

    /**
     * @dev Common checks used in both `_requestDelegation` and `_delegate`.
     *      Ensures that NIK and creditor codes are valid, and that the provider is approved.
     * @param _nik          The unique identifier (hashed) for the debtor.
     * @param _codeConsumer The hashed code for the creditor acting as consumer.
     * @param _codeProvider The hashed code for the creditor acting as provider.
     * @return _nikAddress  The address of the debtor.
     * @return _consumer    The resolved address of the consumer creditor.
     * @return _provider    The resolved address of the provider creditor.
     * @notice Reverts with `InvalidHash` if any input hash is zero.
     * @notice Reverts with `ProviderNotEligible` if the provider is not in APPROVED status for the debtor.
     */
    function _checkCompliance(
        bytes32 _nik,
        bytes32 _codeConsumer,
        bytes32 _codeProvider
    )
        private
        view
        returns (address _nikAddress, address _consumer, address _provider)
    {
        if (
            _nik == bytes32(0) ||
            _codeConsumer == bytes32(0) ||
            _codeProvider == bytes32(0)
        ) revert InvalidHash();

        DebtorInfo storage _info;
        (_info, _nikAddress) = _getCustomerStoraget(_nik);

        _consumer = _isCreditor(_codeConsumer);
        _provider = _isCreditor(_codeProvider);

        // Ensure that the provider is already approved for this debtor
        if (_info.creditorStatus[_provider] != Status.APPROVED) {
            revert ProviderNotEligible();
        }

        return (_nikAddress, _consumer, _provider);
    }

    /**
     * @dev Allows a creditor (consumer) to request delegation from another creditor (provider).
     * @param _nik          The unique identifier (hashed) for the debtor.
     * @param _codeConsumer The hashed code representing the consumer creditor.
     * @param _codeProvider The hashed code representing the provider creditor.
     * @notice Reverts with `RequestAlreadyExist` if there is already a pending request.
     * @notice Reverts with `AddressNotEligible` if `_executor` is not the consumer.
     */
    function _requestDelegation(
        address _executor,
        bytes32 _nik,
        bytes32 _codeConsumer,
        bytes32 _codeProvider
    ) internal {
        (
            address _nikAddress,
            address _consumer,
            address _provider
        ) = _checkCompliance(_nik, _codeConsumer, _codeProvider);

        if (_executor != _consumer) revert AddressNotEligible();
        if (_request[_consumer][_provider].status == Status.PENDING)
            revert RequestAlreadyExist();

        // Create a new request and set it to PENDING
        _request[_consumer][_provider] = Request({
            status: Status.PENDING,
            nik: _nik
        });

        // If consumer is new to this debtor, add them to the debtor's list of creditors
        if (_debtorInfo[_nikAddress].creditorStatus[_consumer] == Status(0)) {
            _debtorInfo[_nikAddress].creditors.push(_consumer);
        }

        // Mark the consumer status as PENDING
        _debtorInfo[_nikAddress].creditorStatus[_consumer] = Status.PENDING;
    }

    /**
     * @dev Allows a creditor (provider) to approve or reject a pending delegation request.
     * @param _nik          The unique identifier (hashed) for the debtor.
     * @param _codeConsumer The hashed code representing the consumer creditor.
     * @param _codeProvider The hashed code representing the provider creditor.
     * @param _status       The final status of the delegation (APPROVED or REJECTED).
     * @notice Reverts with `InvalidStatusApproveRequest` if the request is not currently PENDING.
     * @notice Reverts with `AddressNotEligible` if `_executor` is not the provider.
     */
    function _delegate(
        address _executor,
        bytes32 _nik,
        bytes32 _codeConsumer,
        bytes32 _codeProvider,
        Status _status
    ) internal {
        (
            address _nikAddress,
            address _consumer,
            address _provider
        ) = _checkCompliance(_nik, _codeConsumer, _codeProvider);

        if (_executor != _provider) revert AddressNotEligible();
        if (_request[_consumer][_provider].status != Status.PENDING) {
            revert InvalidStatusApproveRequest();
        }

        // Update the request status
        _request[_consumer][_provider].status = _status;
        // Reflect the new status in the debtor's records
        _debtorInfo[_nikAddress].creditorStatus[_consumer] = _status;

        emit Delegate(_nik, _codeConsumer, _codeProvider, _status);
    }

    /**
     * @dev Adds a creditor directly to a debtor with an APPROVED status.
     * @param _nik          The unique identifier (hashed) for the debtor.
     * @param _codeCreditor The hashed code representing the creditor.
     * @notice Reverts with `AlreadyExist` if the creditor is already in APPROVED status.
     */
    function _addCreditorForDebtor(
        bytes32 _nik,
        bytes32 _codeCreditor
    ) internal {
        if (_nik == bytes32(0) || _codeCreditor == bytes32(0))
            revert InvalidHash();

        address _creditor = _isCreditor(_codeCreditor);

        DebtorInfo storage _info;
        (_info, ) = _getCustomerStoraget(_nik);

        if (_info.creditorStatus[_creditor] == Status.APPROVED)
            revert AlreadyExist();

        // Approve the creditor for this debtor and record it
        _info.creditorStatus[_creditor] = Status.APPROVED;
        _info.creditors.push(_creditor);
    }

    /**
     * @dev Retrieves all creditors for a given debtor, along with their respective statuses.
     * @param _nik The unique identifier (hashed) for the debtor.
     * @return creditorsList The array of creditor addresses.
     * @return statusesList  The array of statuses corresponding to each creditor.
     * @notice Reverts with `NikNeedRegistered` if the debtor is not registered.
     */
    function _getDebtorStatuses(
        bytes32 _nik
    )
        internal
        view
        returns (address[] memory creditorsList, Status[] memory statusesList)
    {
        DebtorInfo storage _info;
        (_info, ) = _getCustomerStoraget(_nik);
        uint256 count = _info.creditors.length;

        creditorsList = new address[](count);
        statusesList = new Status[](count);

        for (uint256 i = 0; i < count; i++) {
            address creditor = _info.creditors[i];
            creditorsList[i] = creditor;
            statusesList[i] = _info.creditorStatus[creditor];
        }
        return (creditorsList, statusesList);
    }

    /**
     * @dev Retrieves the status of a specific creditor for a given debtor status (APPROVED, REJECTED, or PENDING).
     * @param _nik      The unique identifier (hashed) for the debtor.
     * @param _creditor The unique identifier (hashed) for the creditor.
     * @return _status  An status from request delegation.
     */
    function _getStatusRequest(
        bytes32 _nik,
        bytes32 _creditor
    ) internal view returns (Status) {
        (, address _nikAddress) = _getCustomerStoraget(_nik);
        address _creditorAddress = _isCreditor(_creditor);
        return _debtorInfo[_nikAddress].creditorStatus[_creditorAddress];
    }

    /**
     * @dev Retrieves all creditors for a debtor that match a specific status (APPROVED, REJECTED, or PENDING).
     * @param _nik    The unique identifier (hashed) for the debtor.
     * @param _status The `Status` to filter by.
     * @return _getCreditors An array of creditor addresses that match the provided `_status`.
     * @notice Reverts with `NikNeedRegistered` if the debtor is not registered.
     */
    function _getActiveCreditorsByStatus(
        bytes32 _nik,
        Status _status
    ) internal view returns (address[] memory _getCreditors) {
        DebtorInfo storage _info;
        (_info, ) = _getCustomerStoraget(_nik);

        uint256 _count = 0;

        // Count creditors with the desired status
        for (uint256 i = 0; i < _info.creditors.length; i++) {
            if (_info.creditorStatus[_info.creditors[i]] == _status) {
                _count++;
            }
        }

        _getCreditors = new address[](_count);
        uint256 _index = 0;

        // Populate the result array
        for (uint256 i = 0; i < _info.creditors.length; i++) {
            if (_info.creditorStatus[_info.creditors[i]] == _status) {
                _getCreditors[_index] = _info.creditors[i];
                _index++;
            }
        }

        return _getCreditors;
    }
}
