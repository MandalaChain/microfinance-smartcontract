// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

/**
 * @title ISharedErrors
 * @notice Shared custom error declarations reused across contracts.
 * @dev Centralizes error selectors to avoid duplicated declarations.
 */
interface ISharedErrors {
    error InvalidNonce();
    error InvalidSignature();
    error MetaTransactionFailed(string data);
}
