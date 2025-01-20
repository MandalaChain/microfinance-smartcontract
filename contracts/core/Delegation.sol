// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {Registration} from "./Registration.sol";

abstract contract Delegation is Registration {
    error NikNeedRegistered();
    error RequestNotFound();
    error RequestAlreadyExist();

    enum Status {
        PENDING,
        APPROVED,
        REJECTED
    }
    struct LogCustomer {
        address creditor;
        Status status;
    }

    struct Request {
        Status status;
        bytes32 nik;
        uint256 timestamp;
        string metadata;
    }

    // mapping log for customer
    mapping(bytes32 => LogCustomer) private _activeCreditor;
    // mapping request delegation from creditors
    mapping(address => mapping(address => Request)) private _request;

    event RequestCreated(
        address indexed consumer,
        address provider,
        bytes32 nik,
        uint256 timestamp,
        string metadata
    );

    function _requestDelegation(
        bytes32 _nik,
        address _provider,
        string memory _metadata
    ) internal {
        if (_getDebtor(_nik) == address(0)) revert NikNeedRegistered();
        _isCreditor(msg.sender);
        _isCreditor(_provider);

        Request memory _req = _getRequest(msg.sender, _provider);
        if (_req.status == Status.PENDING) revert RequestAlreadyExist();

        uint256 _timestamp = block.timestamp;
        _req = Request({
            status: Status.PENDING,
            nik: _nik,
            timestamp: _timestamp,
            metadata: _metadata
        });
        // adding to log debtor
        _activeCreditor[_nik] = LogCustomer({
            creditor: msg.sender,
            status: Status.PENDING
        });

        emit RequestCreated(msg.sender, _provider, _nik, _timestamp, _metadata);
    }

    // function approveDelegation(address _consumer, address _provider) internal {
    //     Request memory _req = _getRequest(msg.sender, _provider);
        
    // }

    function _getRequest(
        address consumer,
        address provider
    ) internal view returns (Request memory) {
        if (_request[consumer][provider].nik == bytes32(0)) {
            revert RequestNotFound();
        }
        return _request[consumer][provider];
    }
}
