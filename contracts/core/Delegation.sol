// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {Registration} from "./Registration.sol";

abstract contract Delegation is Registration {
    error NikNeedRegistered();
    error RequestNotFound();
    error RequestAlreadyExist();
    error ProviderNotEligible();
    error InvalidStatusApproveRequest();
    error AddressNotEligible();

    enum Status {
        REJECTED,
        APPROVED,
        PENDING
    }

    struct Request {
        Status status;
        bytes32 nik;
    }

    struct DebtorInfo {
        mapping(address => Status) creditorStatus;
        address[] creditors; // List of creditors associated with the debtor
        // !NOTE: add metadata
    }

    // Mapping for debtor information (address(NIK) -> DebtorInfo)
    mapping(address => DebtorInfo) private _debtorInfo;
    // Mapping for delegation requests (Consumer -> Provider -> Request)
    mapping(address => mapping(address => Request)) private _request;

    event Delegate(
        bytes32 indexed nik,
        bytes32 indexed creditorConsumerCode,
        bytes32 indexed creditorProviderCode,
        Status status
    );

    function _getCustomerStoraget(
        bytes32 _nik
    ) private view returns (DebtorInfo storage, address) {
        address _nikAddress = _debtors[_nik];
        if (_nikAddress == address(0)) revert NikNeedRegistered();
        return (_debtorInfo[_nikAddress], _nikAddress);
    }

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

        if (_info.creditorStatus[_provider] != Status.APPROVED) {
            revert ProviderNotEligible();
        }

        return (_nikAddress, _consumer, _provider);
    }

    // Request delegation from one creditor to another
    function _requestDelegation(
        bytes32 _nik,
        bytes32 _codeConsumer,
        bytes32 _codeProvider
    ) internal {
        (
            address _nikAddress,
            address _consumer,
            address _provider
        ) = _checkCompliance(_nik, _codeConsumer, _codeProvider);

        if (msg.sender != _consumer) revert AddressNotEligible();
        if (_request[_consumer][_provider].status == Status.PENDING)
            revert RequestAlreadyExist();

        _request[_consumer][_provider] = Request({
            status: Status.PENDING,
            nik: _nik
        });
        if (_debtorInfo[_nikAddress].creditorStatus[_consumer] == Status(0)) {
            _debtorInfo[_nikAddress].creditors.push(_consumer);
        }
        _debtorInfo[_nikAddress].creditorStatus[_consumer] = Status.PENDING;
    }

    function _delegate(
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

        if (msg.sender != _provider) revert AddressNotEligible();
        if (_request[_consumer][_provider].status != Status.PENDING) {
            revert InvalidStatusApproveRequest();
        }

        _request[_consumer][_provider].status = _status;
        _debtorInfo[_nikAddress].creditorStatus[_consumer] = _status;

        emit Delegate(_nik, _codeConsumer, _codeProvider, _status);
    }

    // Add a creditor for a debtor
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
        _info.creditorStatus[_creditor] = Status.APPROVED;
        _info.creditors.push(_creditor);
    }

    function _getDebtorStatuses(
        bytes32 _nik
    ) internal view returns (address[] memory, Status[] memory) {
        DebtorInfo storage _info;
        (_info, ) = _getCustomerStoraget(_nik);
        uint256 count = _info.creditors.length;
        address[] memory creditorsList = new address[](count);
        Status[] memory statusesList = new Status[](count);

        for (uint256 i = 0; i < count; i++) {
            address creditor = _info.creditors[i];
            creditorsList[i] = creditor;
            statusesList[i] = _info.creditorStatus[creditor];
        }
        return (creditorsList, statusesList);
    }

    function _getActiveCreditorsByStatus(
        bytes32 _nik,
        Status _status
    ) internal view returns (address[] memory) {
        DebtorInfo storage _info;
        (_info, ) = _getCustomerStoraget(_nik);
        uint256 _count = 0;
        for (uint256 i = 0; i < _info.creditors.length; i++) {
            if (_info.creditorStatus[_info.creditors[i]] == _status) {
                _count++;
            }
        }

        address[] memory _getCreditors = new address[](_count);
        uint256 _index = 0;

        for (uint256 i = 0; i < _info.creditors.length; i++) {
            if (_info.creditorStatus[_info.creditors[i]] == _status) {
                _getCreditors[_index] = _info.creditors[i];
                _index++;
            }
        }

        return _getCreditors;
    }
}
