/**
 * SPDX-License-Identifier: MIT
 *
 * @title MetaTransaction
 * @author Baliola Team
 * @notice Abstract base that provides gasless meta-transaction execution via
 *         EIP-712 typed-data signatures.
 * @dev Any contract inheriting `MetaTransaction` can accept off-chain signed
 *      function calls and execute them on behalf of users.
 *
 *      Flow:
 *      1. User signs an EIP-712 `MetaTransaction(address from, uint256 nonce,
 *         bytes functionCall)` off-chain.
 *      2. Relayer calls `executeMetaTransaction` with the signed payload.
 *      3. The contract verifies the signature, increments the nonce, then
 *         `self.call`s the encoded function with the original signer
 *         appended to calldata.
 *      4. `_msgSender()` detects the `self.call` context and extracts the
 *         real sender from the last 20 bytes of `msg.data`.
 *
 *      Security considerations:
 *      - Per-address monotonic nonce prevents replay.
 *      - Nonce is incremented **before** execution (checks-effects-interactions).
 *      - `_verify` is `private` to prevent external bypass.
 *
 *      Failure handling:
 *      - Inner call revert data is bubbled unchanged so custom errors and
 *        panic selectors remain visible to users, relayers, and monitors.
 *
 * @custom:error InvalidNonce - Thrown when the nonce is invalid.
 * @custom:error InvalidSignature - Thrown when the signature is invalid.
 * @custom:error MetaTransactionFailed - Thrown when the meta-transaction execution fails.
 */

pragma solidity 0.8.28;

import {EIP712} from "solady/src/utils/EIP712.sol";
import {ECDSA} from "solady/src/utils/ECDSA.sol";

import {ISharedErrors} from "../libraries/ISharedError.sol";

abstract contract MetaTransaction is EIP712 {
    // ------------------------------------------------------------------
    //  State
    // ------------------------------------------------------------------

    /// @notice Per-address monotonic nonce used to prevent replay attacks.
    /// @dev Public by design so wallets and relayers can construct EIP-712
    ///      payloads; nonce values are not treated as secrets.
    mapping(address => uint256) public noncesTx;

    // ------------------------------------------------------------------
    //  Structures
    // ------------------------------------------------------------------

    /**
     * @dev Represents a meta-transaction payload.
     * @param from         Original transaction sender.
     * @param nonce        Sender's current nonce.
     * @param functionCall ABI-encoded function call to execute on `this`.
     */
    struct Transaction {
        address from;
        uint256 nonce;
        bytes functionCall;
    }

    // ------------------------------------------------------------------
    //  Events
    // ------------------------------------------------------------------

    /**
     * @notice Emitted after a meta-transaction is successfully executed.
     * @param user          The original signer / sender.
     * @param functionCall  The ABI-encoded function call that was executed.
     * @param signature     The EIP-712 signature that authorised execution.
     */
    event MetaTransactionExecuted(
        address indexed user,
        bytes functionCall,
        bytes signature
    );

    // ------------------------------------------------------------------
    //  External Functions
    // ------------------------------------------------------------------

    /**
     * @notice Verifies an EIP-712 signature and executes the encoded function
     *         call on behalf of `_from`.
     * @param _from         The original signer.
     * @param _nonce        Must equal `noncesTx[_from]`.
     * @param _functionCall ABI-encoded function call to execute.
     * @param _signature    EIP-712 signature produced by `_from`.
     */
    function _executeMetaTransaction(
        address _from,
        uint256 _nonce,
        bytes calldata _functionCall,
        bytes calldata _signature
    ) internal {
        // Fetch once to reduce storage cost
        uint256 currentNonce = noncesTx[_from];

        if (_nonce != currentNonce) {
            revert ISharedErrors.InvalidNonce();
        }

        if (!_verify(_from, _nonce, _functionCall, _signature)) {
            revert ISharedErrors.InvalidSignature();
        }

        // Increment nonce before execution to prevent replays
        noncesTx[_from] = currentNonce + 1;

        // Emit before external interaction; event is rolled back automatically if call fails.
        emit MetaTransactionExecuted(_from, _functionCall, _signature);

        // Execute the function call & handle errors efficiently
        (bool success, bytes memory returnData) = address(this).call(
            // Always append the verified signer as the trusted sender suffix.
            abi.encodePacked(_functionCall, _from)
        );

        if (!success) {
            _bubbleRevert(returnData);
        }

    }

    // ------------------------------------------------------------------
    //  Internal / Private Functions
    // ------------------------------------------------------------------

    /**
     * @dev Verifies the EIP-712 typed-data signature for a meta-transaction.
     * @param _from         Expected signer.
     * @param _nonce        Nonce value included in the signed struct.
     * @param _functionCall ABI-encoded function call.
     * @param _signature    ECDSA signature bytes.
     * @return `true` if recovered address matches `_from`.
     */
    function _verify(
        address _from,
        uint256 _nonce,
        bytes calldata _functionCall,
        bytes calldata _signature
    ) private view returns (bool) {
        bytes32 digest = _hashTypedData(
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
     * @dev Reverts with the exact bytes returned by a failed inner call.
     *      This preserves `Error(string)`, `Panic(uint256)`, and custom errors.
     * @param returnData Raw bytes returned by the failed `call`.
     */
    function _bubbleRevert(bytes memory returnData) private pure {
        if (returnData.length > 0) {
            // solhint-disable-next-line no-inline-assembly
            assembly {
                revert(add(returnData, 0x20), mload(returnData))
            }
        }

        revert ISharedErrors.MetaTransactionFailed("Call failed");
    }

    // ------------------------------------------------------------------
    //  Overriding Functions
    // ------------------------------------------------------------------

    /**
     * @dev Returns the real transaction sender.
     *      When called via `executeMetaTransaction` (`msg.sender == address(this)`),
     *      the original signer address is appended to calldata by the
     *      `call(_functionCall)` relay.  This function extracts it from the
     *      last 20 bytes.
     *      In all other contexts, returns `msg.sender` directly.
     * @return The resolved sender address.
     */
    function _msgSender() internal view virtual returns (address) {
        if (msg.sender == address(this)) {
            // Ensure calldata is long enough
            require(msg.data.length >= 20, "Invalid calldata");

            address userAddress;
            // solhint-disable-next-line no-inline-assembly
            assembly {
                // Safe extraction from msg.data
                userAddress := shr(96, calldataload(sub(calldatasize(), 20)))
            }
            return userAddress;
        } else {
            return msg.sender;
        }
    }
}
