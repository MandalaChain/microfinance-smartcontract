/*
 * SPDX-License-Identifier: MIT
 *
 * @title Registration Contract
 * @dev This contract manages the registration of creditors and debtors with optimized storage.
 * It provides internal functions to add, verify, and remove creditors and debtors.
 * 
 * ## Features:
 * - Efficient mapping-based storage.
 * - Revert mechanisms for various validation checks.
 * - Internal functions for flexibility in derived contracts.
 *
 * @custom:error NotEligible - Thrown when a queried entity is not registered.
 * @custom:error AlreadyExist - Thrown when an entity is already registered.
 * @custom:error AlreadyRemoved - Thrown when attempting to remove a non-existent entity.
 * @custom:error InvalidAddress - Thrown when an invalid address is provided.
 * @custom:error InvalidHash - Thrown when an invalid identifier hash is provided.
 */
pragma solidity 0.8.28;

/**
 * @title Registration
 * @notice Handles creditor and debtor registrations with optimized storage.
 * @dev This contract provides internal functions to manage registration data.
 */
abstract contract Registration {
    // Custom errors
    error NotEligible();
    error AlreadyExist();
    error AlreadyRemoved();
    error InvalidAddress();
    error InvalidHash();

    // Storage mappings for registered debtors and creditors
    mapping(bytes32 => address) internal _debtors;
    mapping(bytes32 => address) internal _creditors;

    /**
     * @dev Checks if a creditor exists in the system.
     * @param _creditorCode The unique identifier (hashed) for the creditor.
     * @return The address of the registered creditor.
     * @notice Reverts with `NotEligible` if the creditor is not found.
     */
    function _isCreditor(bytes32 _creditorCode) internal view returns (address){
        address _creditor = _creditors[_creditorCode];
        if (_creditor == address(0)) revert NotEligible();
        return _creditor;
    }

    /**
     * @dev Adds a new debtor to the registry.
     * @param _nik The unique identifier (hashed) for the debtor.
     * @param _addressCustomer The Ethereum address of the debtor.
     * @notice Reverts if the debtor already exists, or if invalid data is provided.
     */
    function _addDebtor(bytes32 _nik, address _addressCustomer) internal {
        if (_nik == bytes32(0)) revert InvalidHash();
        if (_addressCustomer == address(0)) revert InvalidAddress();
        if (_debtors[_nik] != address(0)) revert AlreadyExist();
        _debtors[_nik] = _addressCustomer;
    }

    /**
     * @dev Adds a new creditor to the registry.
     * @param _creditorCode The unique identifier (hashed) for the creditor.
     * @param _setAddress The Ethereum address of the creditor.
     * @notice Reverts if the creditor already exists, or if invalid data is provided.
     */
    function _addCreditor(bytes32 _creditorCode, address _setAddress) internal {
        if (_creditorCode == bytes32(0)) revert InvalidHash();
        if (_setAddress == address(0)) revert InvalidAddress();
        if (_creditors[_creditorCode] != address(0)) revert AlreadyExist();
        _creditors[_creditorCode] = _setAddress;
    }

    /**
     * @dev Removes a registered creditor from the system.
     * @param _creditorCode The unique identifier (hashed) of the creditor.
     * @notice Reverts if the creditor does not exist or invalid data is provided.
     */
    function _removeCreditor(bytes32 _creditorCode) internal {
        if (_creditorCode == bytes32(0)) revert InvalidHash();
        if (_creditors[_creditorCode] == address(0)) revert AlreadyRemoved();
        delete _creditors[_creditorCode];
    }

    /**
     * @dev Removes a registered debtor from the system.
     * @param _nik The unique identifier (hashed) of the debtor.
     * @notice Reverts if the debtor does not exist or invalid data is provided.
     */
    function _removeDebtor(bytes32 _nik) internal {
        if (_nik == bytes32(0)) revert InvalidHash();
        if (_debtors[_nik] == address(0)) revert AlreadyRemoved();
        delete _debtors[_nik];
    }
}
