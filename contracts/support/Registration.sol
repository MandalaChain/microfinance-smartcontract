// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

abstract contract Registration is Ownable {
    error AddressNotEligible();
    error NikNotRegistered();
    error ProviderNotEligible();
    error ConsumerNotEligible();

    // mapping platform is eligible
    mapping(address => bool) private _paltform;
    // mapping from platform that customer is registered from NIK
    mapping(address => mapping(bytes32 => address)) private _customers;
    // mapping from platform that provider is registered
    mapping(address => mapping(address => bool)) private _providers;
    // mapping from platform that consumer is registered
    mapping(address => mapping(address => bool)) private _consumer;

    // check platform is eligible
    function _isPlatform(address _platform) internal view {
        if (!_paltform[_platform]) revert AddressNotEligible();
    }

    // check is customer already registered their NIK
    function _isCustomer(bytes32 _nik) internal view {
        if (_customers[msg.sender][_nik] != address(0))
            revert NikNotRegistered();
    }

    // check address is eligible as provider
    function _isProvider(address _addressProvider) internal view {
        if (!_providers[msg.sender][_addressProvider])
            revert ProviderNotEligible();
    }

    // check address is elgigble as consumer
    function _isConsumer(address _addressCunsumer) internal view {
        if (!_consumer[msg.sender][_addressCunsumer])
            revert ConsumerNotEligible();
    }

    // add platform is eligible
    function _addPlatform(address _addressPlatform) internal onlyOwner {
        _paltform[_addressPlatform] = true;
    }

    // add customer
    function _addCustomer(bytes32 _nik, address _addressCustomer) internal {
        _isPlatform(msg.sender);
        _customers[msg.sender][_nik] = _addressCustomer;
    }

    // add provider
    function _addProvider(address _addressProvider) internal {
        _isPlatform(msg.sender);
        _providers[msg.sender][_addressProvider] = true;
    }

    // add consumer
    function _addConsumer(address _addressConsumer) internal {
        _isPlatform(msg.sender);
        _consumer[msg.sender][_addressConsumer] = true;
    }

    // return address customer by nik
    function _getCustomer(bytes32 _nik) internal view returns (address) {
        return _customers[msg.sender][_nik];
    }

    // return eligibility provider
    function _getProvider(address _addressProvider) internal view returns (bool) {
        return _providers[msg.sender][_addressProvider];
    }

    // return elgibility consumer
    function _getConsumer(address _addressConsumer) internal view returns (bool) {
        return _consumer[msg.sender][_addressConsumer];
    }
}
