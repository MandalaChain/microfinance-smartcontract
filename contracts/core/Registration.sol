// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

abstract contract Registration is Ownable {
    error AddressNotEligible();
    error NotEligible();
    error AlreadyExist();
    error AlreadyRemoved();

    address private _platform;

    // mapping from platform that customer is registered from NIK
    mapping(bytes32 => address) private _debtors;
    // mapping from platform that debtors is registered
    mapping(address => bool) private _creditors;

    event DebtorAdded(bytes32 indexed nik, address indexed debtorAddress);
    event CreditorAdded(address indexed creditorAddress);

    // check platform is eligible
    modifier onlyPlatform() {
        if (msg.sender != _platform) revert AddressNotEligible();
        _;
    }

    // check address is eligible as debtor
    function _isCreditor(address _addressCreditor) internal view {
        if (!_creditors[_addressCreditor]) revert NotEligible();
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
        if (_getDebtor(_nik) != address(0)) revert AlreadyExist();
        _debtors[_nik] = _addressCustomer;
        emit DebtorAdded(_nik, _addressCustomer);
    }

    // add creditor
    // !Note: metadata is must added
    function _addCreditor(address _addressCreditor) internal onlyPlatform {
        if (_creditors[_addressCreditor]) revert AlreadyExist();
        _creditors[_addressCreditor] = true;
        emit CreditorAdded(_addressCreditor);
    }

    function _removeCreditor(address _addressCreditor) internal onlyPlatform {
        if (!_creditors[_addressCreditor]) revert AlreadyRemoved();
        _creditors[_addressCreditor] = false;
    }

    function _removeDebtor(bytes32 _nik) internal onlyPlatform {
        if (_debtors[_nik] == address(0)) revert AlreadyRemoved();
        delete _debtors[_nik];
    }

    // return address Debtor by nik
    function _getDebtor(bytes32 _nik) internal view returns (address) {
        return _debtors[_nik];
    }

    // return eligibility debtor
    // function _getCreditor(
    //     address _addressCreditor
    // ) internal view returns (bool) {
    //     return _creditors[_addressCreditor];
    // }
}
