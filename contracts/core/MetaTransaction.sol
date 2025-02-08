/*
 * SPDX-License-Identifier: MIT
 *
 * @title MetaTransaction
 * @dev This contract provides a base implementation for meta-transactions.
 *      It includes a mapping for nonces and a function to verify and execute meta-transactions.
 *
 * @custom:error InvalidNonce - Thrown when the nonce is invalid.
 * @custom:error InvalidSignature - Thrown when the signature is invalid.
 * @custom:error MetaTransactionFailed - Thrown when the meta-transaction execution fails.
 */

pragma solidity ^0.8.20;

import {EIP712} from "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

abstract contract MetaTransaction is EIP712, Ownable {
    // ------------------------------------------------------------------------
    //                              Custom Errors
    // ------------------------------------------------------------------------
    error InvalidNonce();
    error InvalidSignature();
    error MetaTransactionFailed(string data);

    /**
     * @dev Maps creditor codes to their Ethereum addresses.
     */
    mapping(address => uint256) public nonces;

    // ------------------------------------------------------------------------
    //                              Structures
    // ------------------------------------------------------------------------
    /**
     * @dev A struct to represent a meta transaction, including the sender, nonce, and function call.
     */
    struct Transaction {
        address from;
        uint256 nonce;
        bytes functionCall;
    }

    // ------------------------------------------------------------------------
    //                                Events
    // ------------------------------------------------------------------------
    /**
     * @notice Emitted when a new platform address is change or set.
     * @param user          Wallet user execute transaction.
     * @param functionCall  The function call to be executed.
     */
    event MetaTransactionExecuted(address user, bytes functionCall);

    // ------------------------------------------------------------------------
    //                               Functions
    // ------------------------------------------------------------------------
    /**
     * @dev This function is used to verify the signature of a meta transaction.
     * @param _from         The sender of the meta transaction.
     * @param _nonce        The nonce associated with the meta transaction.
     * @param _functionCall The function call associated with the meta transaction.
     * @param _signature    The signature of the meta transaction.
     *
     * @return True if the signature is valid, false otherwise.
     *
     * @notice This function uses the `verify` function from the `EIP712` library to verify the signature.
     *         It is a public function that can be called by any address and returns a boolean value.
     *         It takes in four parameters: the sender, nonce, function call, and signature.
     *         It returns true if the signature is valid, and false otherwise.
     */
    function _verify(
        address _from,
        uint256 _nonce,
        bytes calldata _functionCall,
        bytes calldata _signature
    ) private view returns (bool) {
        bytes32 digest = _hashTypedDataV4(
            keccak256(
                abi.encode(
                    keccak256(
                        "MetaTransaction(address from,uint256 nonce,bytes functionCall)"
                    ),
                    _from,
                    _nonce,
                    keccak256(_functionCall)
                )
            )
        );

        address recoveredSigner = ECDSA.recover(digest, _signature);
        return recoveredSigner == _from;
    }

    /**
     * @dev This function is used to execute a meta transaction.
     * @param _from         The sender of the meta transaction.
     * @param _nonce        The nonce associated with the meta transaction.
     * @param _functionCall The function call associated with the meta transaction.
     * @param _signature    The signature of the meta transaction.
     *
     * @notice This function uses the `verify` function from the `EIP712` library to verify the signature.
     *         It is a public function that can be called by any address.
     *         It takes in four parameters: the sender, nonce, function call, and signature.
     *         It emits a `MetaTransactionExecuted` event.
     */
    function _executeMetaTransaction(
        address _from,
        uint256 _nonce,
        bytes calldata _functionCall,
        bytes calldata _signature
    ) internal {
        // Fetch once to reduce storage cost
        uint256 currentNonce = nonces[_from];

        if (_nonce != currentNonce) {
            revert InvalidNonce();
        }

        if (!_verify(_from, _nonce, _functionCall, _signature)) {
            revert InvalidSignature();
        }

        // Increment nonce before execution to prevent replays
        nonces[_from] = currentNonce + 1;

        // Execute the function call & handle errors efficiently
        (bool success, bytes memory returnData) = address(this).call(
            abi.encodePacked(_functionCall, _from) // Append `_from`
        );

        if (!success) {
            // ✅ Decode revert reason only if call fails (saves gas in successful cases)
            string memory errorMessage = _extractRevertMsg(returnData);
            revert MetaTransactionFailed(errorMessage);
        }

        emit MetaTransactionExecuted(_from, _functionCall);
    }

    // Optimized function to extract revert reason
    function _extractRevertMsg(
        bytes memory _returnData
    ) private pure returns (string memory) {
        if (_returnData.length < 68) return "Transaction reverted";

        assembly {
            _returnData := add(_returnData, 0x04) // Skip first 4 bytes (selector)
        }

        return abi.decode(_returnData, (string));
    }

    // ------------------------------------------------------------------------
    //                             Overriding Functions
    // ------------------------------------------------------------------------
    /**
     * @dev This function is used to get the sender of the meta transaction.
     * @return The sender of the meta transaction.
     *
     * @notice This function is a public function that can be called by any address.
     *         It returns the sender of the meta transaction.
     */
    function _msgSender() internal view override returns (address) {
        if (msg.sender == address(this)) {
            bytes memory array = msg.data;
            uint256 index = msg.data.length;
            address userAddress;
            assembly {
                userAddress := and(
                    mload(add(array, index)),
                    0xffffffffffffffffffffffffffffffffffffffff
                )
            }
            return userAddress;
        } else {
            return msg.sender;
        }
    }
}
