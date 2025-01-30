// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

/**
 * @title Registration
 * @notice Handles creditor and debtor registrations with optimized storage.
 */
abstract contract Registration {
    error NotEligible();
    error AlreadyExist();
    error AlreadyRemoved();
    error InvalidAddress();
    error InvalidHash();

    mapping(bytes32 => address) internal _debtors;
    mapping(bytes32 => address) internal _creditors;

    function _isCreditor(bytes32 _creditorCode) internal view returns (address){
        address _creditor = _creditors[_creditorCode];
        if (_creditor == address(0)) revert NotEligible();
        return _creditor;
    }

    function _addDebtor(bytes32 _nik, address _addressCustomer) internal {
        if (_nik == bytes32(0)) revert InvalidHash();
        if (_addressCustomer == address(0)) revert InvalidAddress();
        if (_debtors[_nik] != address(0)) revert AlreadyExist();
        _debtors[_nik] = _addressCustomer;
    }

    function _addCreditor(bytes32 _creditorCode, address _setAddress) internal {
        if (_creditorCode == bytes32(0)) revert InvalidHash();
        if (_setAddress == address(0)) revert InvalidAddress();
        if (_creditors[_creditorCode] != address(0)) revert AlreadyExist();
        _creditors[_creditorCode] = _setAddress;
    }

    function _removeCreditor(bytes32 _creditorCode) internal {
        if (_creditorCode == bytes32(0)) revert InvalidHash();
        if (_creditors[_creditorCode] == address(0)) revert AlreadyRemoved();
        delete _creditors[_creditorCode];
    }

    function _removeDebtor(bytes32 _nik) internal {
        if (_nik == bytes32(0)) revert InvalidHash();
        if (_debtors[_nik] == address(0)) revert AlreadyRemoved();
        delete _debtors[_nik];
    }
}
