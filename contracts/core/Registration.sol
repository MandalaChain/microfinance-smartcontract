// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

abstract contract Registration {
    error NotEligible();
    error AlreadyExist();
    error AlreadyRemoved();
    error InvalidAddress();
    error InvalidHash();

    // mapping from platform that customer is registered from NIK
    mapping(bytes32 => address) private _debtors;
    // mapping from platform that debtors is registered
    mapping(bytes32 => address) private _creditors;

    function _checkHash(bytes32 _hashInput) internal pure {
        if(_hashInput == bytes32(0)) revert InvalidHash();
    }

    function _checkAddressNotZero(
        address _checkAddress
    ) internal pure returns (bool) {
        return _checkAddress == address(0);
    }

    // check address is eligible as debtor
    function _isCreditor(bytes32 _creditorCode) internal view {
        address _address = _creditors[_creditorCode];
        if (_checkAddressNotZero(_address)) revert NotEligible();
    }

    function _addDebtor(bytes32 _nik, address _addressCustomer) internal {
        _checkHash(_nik);
        if (_checkAddressNotZero(_addressCustomer)) revert InvalidAddress();
        if (!_checkAddressNotZero(_getDebtor(_nik))) revert AlreadyExist();
        _debtors[_nik] = _addressCustomer;
    }

    function _addCreditor(bytes32 _creditorCode, address _setAddress) internal {
        _checkHash(_creditorCode);
        if (_checkAddressNotZero(_setAddress)) revert InvalidAddress();
        address _address = _creditors[_creditorCode];
        if (!_checkAddressNotZero(_address)) revert AlreadyExist();
        _creditors[_creditorCode] = _setAddress;
    }

    function _removeCreditor(bytes32 _creditorCode) internal {
        _checkHash(_creditorCode);
        address _address = _creditors[_creditorCode];
        if (_checkAddressNotZero(_address)) revert AlreadyRemoved();
        delete _creditors[_creditorCode];
    }

    function _removeDebtor(bytes32 _nik) internal {
        _checkHash(_nik);
        address _address = _debtors[_nik];
        if (_checkAddressNotZero(_address)) revert AlreadyRemoved();
        delete _debtors[_nik];
    }

    function _getCreditor(
        bytes32 _codeCreditor
    ) internal view returns (address) {
        return _creditors[_codeCreditor];
    }

    function _getDebtor(bytes32 _nik) internal view returns (address) {
        return _debtors[_nik];
    }
}
