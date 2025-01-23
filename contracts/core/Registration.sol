// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

abstract contract Registration is Ownable {
    error AddressNotEligible();
    error NotEligible();
    error AlreadyExist();
    error AlreadyRemoved();
    error InvalidAddress();

    address private _platform;

    // mapping from platform that customer is registered from NIK
    mapping(bytes32 => address) private _debtors;
    // mapping from platform that debtors is registered
    mapping(bytes32 => address) private _creditors;

    event DebtorAdded(bytes32 indexed nik, address indexed debtorAddress);
    event CreditorAdded(bytes32 indexed creditorAddress);

    // check platform is eligible
    modifier onlyPlatform() {
        if (msg.sender != _platform) revert AddressNotEligible();
        _;
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

    function _setPlatform(address _setNewPlatform) internal onlyOwner {
        _platform = _setNewPlatform;
    }

    // add Debtor
    // !Note: metadata is must added
    function _addDebtor(
        bytes32 _nik,
        address _addressCustomer
    ) internal onlyPlatform {
        if (!_checkAddressNotZero(_getDebtor(_nik))) revert AlreadyExist();
        _debtors[_nik] = _addressCustomer;
        emit DebtorAdded(_nik, _addressCustomer);
    }

    // add creditor
    // !Note: metadata is must added
    function _addCreditor(
        bytes32 _creditorCode,
        address _setAddress
    ) internal onlyPlatform {
        if (_checkAddressNotZero(_setAddress)) revert InvalidAddress();
        address _address = _creditors[_creditorCode];
        if (!_checkAddressNotZero(_address)) revert AlreadyExist();
        _creditors[_creditorCode] = _setAddress;
        emit CreditorAdded(_creditorCode);
    }

    function _removeCreditor(bytes32 _creditorCode) internal onlyPlatform {
        address _address = _creditors[_creditorCode];
        if (_checkAddressNotZero(_address)) revert AlreadyRemoved();
        delete _creditors[_creditorCode];
    }

    function _removeDebtor(bytes32 _nik) internal onlyPlatform {
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
