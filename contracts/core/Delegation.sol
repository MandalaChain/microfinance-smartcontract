// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {Registration} from "./Registration.sol";

abstract contract Delegation is Registration {
    error NikNeedRegistered();
    error RequestNotFound();
    error RequestAlreadyExist();
    error ProviderNotEligible();

    enum Status {
        APPROVED,
        REJECTED,
        PENDING
    }

    struct Request {
        Status status;
        bytes32 nik;
        uint256 timestamp;
        string metadata;
    }

    struct DebtorInfo {
        mapping(address => Status) creditorStatus;
        address[] creditors; // List of creditors associated with the debtor
    }

    // Mapping for debtor information (NIK -> DebtorInfo)
    mapping(bytes32 => DebtorInfo) private _debtorInfo;

    // Mapping for delegation requests (Consumer -> Provider -> Request)
    mapping(address => mapping(address => Request)) private _request;

    event RequestCreated(
        address indexed consumer,
        address provider,
        bytes32 nik,
        uint256 timestamp,
        string metadata
    );

    event StatusUpdated(
        bytes32 indexed nik,
        address indexed creditor,
        Status status
    );

    // Request delegation from one creditor to another
    function _requestDelegation(
        bytes32 _nik,
        address _provider,
        string calldata _metadata
    ) internal {
        if (_getDebtor(_nik) == address(0)) revert NikNeedRegistered();
        _isCreditor(msg.sender);
        _isCreditor(_provider);

        DebtorInfo storage info = _debtorInfo[_nik];
        if (info.creditorStatus[msg.sender] == Status(0)) {
            info.creditors.push(msg.sender);
        }
        info.creditorStatus[msg.sender] = Status.PENDING;


        Request storage _req = _request[msg.sender][_provider];
        if (_req.status == Status.PENDING) revert RequestAlreadyExist();

        uint256 _timestamp = block.timestamp;
        _request[msg.sender][_provider] = Request({
            status: Status.PENDING,
            nik: _nik,
            timestamp: _timestamp,
            metadata: _metadata
        });

        emit RequestCreated(msg.sender, _provider, _nik, _timestamp, _metadata);
    }

    // Add a creditor for a debtor
    function _addCreditorForDebtor(bytes32 _nik, address _creditor) internal {
        DebtorInfo storage _info = _debtorInfo[_nik];
        if (_info.creditorStatus[_creditor] == Status.APPROVED)
            revert AlreadyExist();
        _info.creditorStatus[_creditor] = Status.APPROVED;
        _info.creditors.push(_creditor);

        emit StatusUpdated(_nik, _creditor, Status.APPROVED);
    }

    // Get all creditor statuses for a debtor
    function _getActiveCreditors(
        bytes32 _nik
    ) internal view returns (address[] memory, Status[] memory) {
        DebtorInfo storage _info = _debtorInfo[_nik];
        uint256 _count = _info.creditors.length;
        address[] memory _creditorsList = new address[](_count);
        Status[] memory _statusesList = new Status[](_count);

        for (uint256 i = 0; i < _count; i++) {
            address creditor = _info.creditors[i];
            _creditorsList[i] = creditor;
            _statusesList[i] = _info.creditorStatus[creditor];
        }
        return (_creditorsList, _statusesList);
    }

    function _getActiveCreditorsByStatus(
        bytes32 _nik,
        Status _status
    ) internal view returns (address[] memory) {
        DebtorInfo storage _info = _debtorInfo[_nik];
        uint256 _count = 0;
        for (uint256 i = 0; i < _info.creditors.length; i++) {
            if (_info.creditorStatus[_info.creditors[i]] == _status) {
                _count++;
            }
        }

        // Buat array hasil
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
