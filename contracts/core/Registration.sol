// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

abstract contract Registration is Ownable {
    error AddressNotEligible();
    error NotEligible();
    error AlreadyExist();

    address private immutable _platform;

    // mapping from platform that customer is registered from NIK
    mapping(bytes32 => address) private _debtors;
    // mapping from platform that debtors is registered
    mapping(address => bool) private _creditors;

    constructor(address _setPlatform) {
        _platform = _setPlatform;
    }

    // check platform is eligible
    function _isPlatform() internal view {
        if (msg.sender != _platform) revert AddressNotEligible();
    }

    // check address is eligible as debtor
    function _isCreditor(address _addressCreditor) internal view {
        if (!_creditors[_addressCreditor]) revert NotEligible();
    }

    // add Debtor
    function _addDebtor(bytes32 _nik, address _addressCustomer) internal {
        _isPlatform();
        if (_getDebtor(_nik) != address(0)) revert AlreadyExist();
        _debtors[_nik] = _addressCustomer;
    }

    // add creditor
    function _addCreditor(address _addressCreditor) internal {
        _isPlatform();
        if (_getCreditor(_addressCreditor)) revert AlreadyExist();
        _creditors[_addressCreditor] = true;
    }

    // return address Debtor by nik
    function _getDebtor(bytes32 _nik) internal view returns (address) {
        return _debtors[_nik];
    }

    // return eligibility debtor
    function _getCreditor(
        address _addressCreditor
    ) internal view returns (bool) {
        return _creditors[_addressCreditor];
    }
}
