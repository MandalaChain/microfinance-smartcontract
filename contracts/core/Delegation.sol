// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {Registration} from "./Registration.sol";

abstract contract Delegation is Registration {
    error NikNeedRegistered();
    error RequestNotFound();
    error RequestAlreadyExist();
    error ProviderNotEligible();
    error InvalidStatusApproveRequest();

    enum Function {
        DELEGATE,
        REQUEST
    }

    enum Status {
        APPROVED,
        REJECTED,
        PENDING
    }

    struct Request {
        Status status;
        bytes32 nik;
        uint256 timestamp;
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

    event RequestCreated(
        address indexed consumer,
        address provider,
        bytes32 nik,
        uint256 timestamp
    );

    event ApproveDelegate(
        address indexed consumer,
        address provider,
        bytes32 nik,
        uint256 timestamp
    );

    event StatusUpdated(
        bytes32 indexed nik,
        address indexed creditor,
        Status status
    );

    function _getCustomerStoraget(
        bytes32 _nik
    ) private view returns (DebtorInfo storage) {
        address _nikAddress = _getDebtor(_nik);
        return _debtorInfo[_nikAddress];
    }

    function _checkCompliance(
        bytes32 _nik,
        address _consumer,
        address _provider,
        Function _function
    ) private view returns (address) {
        address _nikAddress = _getDebtor(_nik);
        if (_nikAddress == address(0)) revert NikNeedRegistered();
        _isCreditor(_consumer);
        _isCreditor(_provider);

        DebtorInfo storage _info = _getCustomerStoraget(_nik);
        if (_info.creditorStatus[_provider] != Status.APPROVED) {
            revert ProviderNotEligible();
        }
        Request memory _req = _request[_consumer][_provider];

        if (_function == Function.REQUEST) {
            if (_req.status == Status.PENDING) revert RequestAlreadyExist();
        }

        if (_function == Function.DELEGATE) {
            if (_req.status != Status.PENDING) {
                revert InvalidStatusApproveRequest();
            }
        }
        return _nikAddress;
    }

    // Request delegation from one creditor to another
    function _requestDelegation(
        bytes32 _nik,
        address _provider
    ) internal {
        address _nikAddress = _checkCompliance(
            _nik,
            msg.sender,
            _provider,
            Function.REQUEST
        );

        uint256 _timestamp = block.timestamp;
        _request[msg.sender][_provider] = Request({
            status: Status.PENDING,
            nik: _nik,
            timestamp: _timestamp
        });
        if (_debtorInfo[_nikAddress].creditorStatus[msg.sender] == Status(0)) {
            _debtorInfo[_nikAddress].creditors.push(msg.sender);
        }
        _debtorInfo[_nikAddress].creditorStatus[msg.sender] = Status.PENDING;

        emit RequestCreated(msg.sender, _provider, _nik, _timestamp);
    }

    function _delegate(
        bytes32 _nik,
        address _consumer,
        Status _status
    ) internal {
        address _nikAddress = _checkCompliance(
            _nik,
            _consumer,
            msg.sender,
            Function.DELEGATE
        );

        uint256 _timestamp = block.timestamp;
        _request[_consumer][msg.sender].status = _status;
        _request[_consumer][msg.sender].timestamp = _timestamp;
        _debtorInfo[_nikAddress].creditorStatus[_consumer] = _status;

        emit ApproveDelegate(_consumer, msg.sender, _nik, _timestamp);
    }

    // Add a creditor for a debtor
    function _addCreditorForDebtor(bytes32 _nik, address _creditor) internal {
        DebtorInfo storage _info = _getCustomerStoraget(_nik);
        if (_info.creditorStatus[_creditor] == Status.APPROVED)
            revert AlreadyExist();
        _info.creditorStatus[_creditor] = Status.APPROVED;
        _info.creditors.push(_creditor);

        emit StatusUpdated(_nik, _creditor, Status.APPROVED);
    }

    function _getDebtorStatuses(
        bytes32 _nik
    ) internal view returns (address[] memory, Status[] memory) {
        DebtorInfo storage info = _getCustomerStoraget(_nik);
        uint256 count = info.creditors.length;
        address[] memory creditorsList = new address[](count);
        Status[] memory statusesList = new Status[](count);

        for (uint256 i = 0; i < count; i++) {
            address creditor = info.creditors[i];
            creditorsList[i] = creditor;
            statusesList[i] = info.creditorStatus[creditor];
        }
        return (creditorsList, statusesList);
    }

    function _getActiveCreditorsByStatus(
        bytes32 _nik,
        Status _status
    ) internal view returns (address[] memory) {
        DebtorInfo storage _info = _getCustomerStoraget(_nik);
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
