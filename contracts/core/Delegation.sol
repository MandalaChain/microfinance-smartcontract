/*
 * SPDX-License-Identifier: MIT
 *
 * @title Delegation Contract
 * @dev This contract extends the `Registration` contract and manages approval-based
 *      delegation relationships between creditors for a specific debtor.
 *
 * ## Features:
 * - Creditor delegation approvals for debtors.
 * - Mapping-based storage for efficient lookups.
 *
 * @custom:error NikNeedRegistered      - Thrown when the provided NIK is not yet registered.
 * @custom:error DelegateAlreadyExist   - Thrown when a similar delegation already exists.
 * @custom:error ProviderNotEligible    - Thrown when the provider is not in an approved status.
 * @custom:error InvalidHash            - Thrown when one of the provided identifiers (NIK/creditor code) is invalid (zero).
 */

pragma solidity 0.8.28;

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
    error DelegateAlreadyExist();
    error ProviderNotEligible();

    // ------------------------------------------------------------------------
    //                                 Enums
    // ------------------------------------------------------------------------
    /**
     * @dev Status represents a creditor's relationship to a debtor.
     *      - APPROVED: The creditor was approved for the debtor.
     */
    enum Status {
        NONE,
        APPROVED
    }

    // ------------------------------------------------------------------------
    //                              Structures
    // ------------------------------------------------------------------------
    /**
     * @dev Request holds the delegation status from one creditor (consumer)
     *      to another creditor (provider) for a specific debtor.
     */
    struct Request {
        Status status;
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
     * @dev Stores delegation requests keyed by NIK, consumer, and provider.
     */
    mapping(bytes32 => mapping(address => mapping(address => Request)))
        private _request;

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
     * @dev Common checks used before approving a delegation.
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
     * @dev Approves a delegation relationship for the consumer creditor.
     * @param _nik          The unique identifier (hashed) for the debtor.
     * @param _codeConsumer The hashed code representing the consumer creditor.
     * @param _codeProvider The hashed code representing the provider creditor.
     */
    function _delegate(
        bytes32 _nik,
        bytes32 _codeConsumer,
        bytes32 _codeProvider
    ) internal {
        (
            address _nikAddress,
            address _consumer,
            address _provider
        ) = _checkCompliance(_nik, _codeConsumer, _codeProvider);
        DebtorInfo storage _info = _debtorInfo[_nikAddress];

        if (_request[_nik][_consumer][_provider].status != Status.NONE) {
            revert DelegateAlreadyExist();
        }
        if (_info.creditorStatus[_consumer] == Status.APPROVED) {
            revert AlreadyExist();
        }

        // Update the request status
        _request[_nik][_consumer][_provider].status = Status.APPROVED;
        // Reflect the new status in the debtor's records
        _addApprovedCreditor(_info, _consumer);
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
        _addApprovedCreditor(_info, _creditor);
    }

    /**
     * @dev Adds a creditor directly to a debtor with an APPROVED status.
     * @param _nik          The unique identifier (hashed) for the debtor.
     * @param _codeConsumer The hashed code representing the consumer creditor.
     * @param _codeProvider The hashed code representing the provider creditor.
     * @notice Reverts with `AlreadyExist` if the provider is already in APPROVED status.
     * @notice Reverts with `DelegateAlreadyExist` if the request already exists.
     */
    function _processAction(
        bytes32 _nik,
        bytes32 _codeConsumer,
        bytes32 _codeProvider
    ) internal {
        if (
            _nik == bytes32(0) ||
            _codeConsumer == bytes32(0) ||
            _codeProvider == bytes32(0)
        ) revert InvalidHash();

        DebtorInfo storage _info;
        (_info, ) = _getCustomerStoraget(_nik);

        address _consumer = _isCreditor(_codeConsumer);
        address _provider = _isCreditor(_codeProvider);

        if (_info.creditorStatus[_provider] == Status.APPROVED) {
            revert AlreadyExist();
        }
        if (_info.creditorStatus[_consumer] == Status.APPROVED) {
            revert AlreadyExist();
        }

        // Approve both creditors for this debtor and record each once.
        _addApprovedCreditor(_info, _provider);
        _addApprovedCreditor(_info, _consumer);

        // Update the request status
        _request[_nik][_consumer][_provider].status = Status.APPROVED;
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
     * @dev Retrieves all approved creditors for a debtor.
     * @param _nik    The unique identifier (hashed) for the debtor.
     * @return _getCreditors An array of approved creditor addresses.
     * @notice Reverts with `NikNeedRegistered` if the debtor is not registered.
     */
    function _getActiveCreditors(
        bytes32 _nik
    ) internal view returns (address[] memory _getCreditors) {
        DebtorInfo storage _info;
        (_info, ) = _getCustomerStoraget(_nik);

        uint256 _count = 0;
        Status _status = Status.APPROVED;

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

    /**
     * @dev Records a creditor as approved for a debtor after callers have
     *      verified it is not already present.
     */
    function _addApprovedCreditor(
        DebtorInfo storage _info,
        address _creditor
    ) private {
        _info.creditorStatus[_creditor] = Status.APPROVED;
        _info.creditors.push(_creditor);
    }

    /**
     * @dev Clears debtor-scoped creditor arrays and mapping values before the
     *      debtor registry entry is removed.
     */
    function _beforeRemoveDebtor(
        bytes32,
        address _debtorAddress
    ) internal virtual override {
        DebtorInfo storage _info = _debtorInfo[_debtorAddress];
        for (uint256 i = 0; i < _info.creditors.length; i++) {
            delete _info.creditorStatus[_info.creditors[i]];
        }
        delete _info.creditors;
    }
}
