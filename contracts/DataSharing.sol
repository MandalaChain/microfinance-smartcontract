/*
 * SPDX-License-Identifier: MIT
 *
 * @title DataSharing Contract
 * @dev This contract extends the `Delegation` contract to manage data sharing
 *      and delegation requests among creditors and debtors. It leverages
 *      mapping-based storage for efficient lookups and includes metadata
 *      emission for tracking important actions.
 *
 * ## Features:
 * - Integrates with the `Delegation` system for creditor-debtor relationships.
 * - Supports adding and removing debtors/creditors with associated metadata.
 * - Includes event emission for purchase packages and delegation requests.
 * - Allows only the platform address (and contract owner for platform updates) to perform
 *   certain registration and removal functions.
 *
 * @custom:error AddressNotEligible - Thrown when `msg.sender` is not the expected address (e.g., `_platform`).
 * @custom:error InvalidHash        - Thrown when a provided identifier is empty (bytes32(0)).
 * @custom:error NikNeedRegistered  - Thrown when the provided NIK is not registered.
 * @custom:error RequestNotFound    - Thrown when a delegation request is missing.
 * @custom:error RequestAlreadyExist - Thrown when attempting to create a request that already exists in PENDING status.
 * @custom:error ProviderNotEligible - Thrown when the provider is not in an APPROVED status for a debtor.
 * @custom:error InvalidStatusApproveRequest - Thrown when trying to approve/reject a non-pending request.
 */

pragma solidity ^0.8.20;

import {Delegation} from "./core/Delegation.sol";
import {MetaTransaction, EIP712, Ownable} from "./core/MetaTransaction.sol";

/**
 * @title DataSharing
 * @notice Manages the high-level interactions for registration and delegation of debtors and creditors,
 *         while emitting metadata-driven events for tracking and auditing.
 * @dev Inherits from `Delegation` (which itself extends `Registration`) and `Ownable`.
 */
contract DataSharing is Delegation, MetaTransaction {
    // ------------------------------------------------------------------------
    //                          State Variables
    // ------------------------------------------------------------------------
    /**
     * @dev The platform address allowed to perform sensitive registration
     *      and management functions.
     */
    address private _platform;

    // ------------------------------------------------------------------------
    //                         Constructor & Modifiers
    // ------------------------------------------------------------------------

    /**
     * @dev Sets the initial platform address and initializes `Ownable` with the contract deployer.
     * @param _setNewPlatform The address of the platform authorized for special operations.
     * @param _domain         The domain name for EIP712.
     * @param _version        The contract version for EIP712.
     */
    constructor(
        address _setNewPlatform,
        string memory _domain,
        string memory _version
    ) Ownable(msg.sender) EIP712(_domain, _version) {
        setPlatform(_setNewPlatform);
    }

    /**
     * @dev Restricts function calls to the current platform address.
     *      Reverts with `AddressNotEligible` if the caller is not `_platform`.
     */
    modifier onlyPlatform() {
        if (_msgSender() != _platform) revert AddressNotEligible();
        _;
    }

    // ------------------------------------------------------------------------
    //                                Events
    // ------------------------------------------------------------------------
    /**
     * @notice Emitted when a new platform address is change or set.
     * @param platform          The unique identifier (hashed) for the creditor.
     */
    event SetNewAddressPlatform(address indexed platform);

    /**
     * @notice Emitted when a new creditor is added with supplemental metadata.
     * @param creditorCode      The unique identifier (hashed) for the creditor.
     * @param institutionCode   A string code representing the creditor institution.
     * @param institutionName   The human-readable name of the creditor institution.
     * @param approvalDate      The date on which the creditor was approved.
     * @param signerName        The name of the person who signed or approved.
     * @param signerPosition    The position or title of the signer.
     */
    event CreditorAddedWithMetadata(
        bytes32 indexed creditorCode,
        string institutionCode,
        string institutionName,
        string approvalDate,
        string signerName,
        string signerPosition
    );

    /**
     * @notice Emitted when a debtor is added for a specific creditor with metadata.
     * @param nik            The unique identifier (hashed) for the debtor.
     * @param name           The name of the debtor.
     * @param creditorCode   The hashed code of the creditor to whom the debtor is added.
     * @param creditorName   A human-readable name for the creditor.
     * @param applicationDate The date when the debtor applied or was introduced.
     * @param approvalDate    The date the debtor was approved for the creditor.
     * @param urlKTP          A URL reference (e.g., to an image or document) for the debtor’s KTP.
     * @param urlApproval     A URL reference for any approval document.
     */
    event DebtorAddedWithMetadata(
        bytes32 indexed nik,
        string name,
        bytes32 indexed creditorCode,
        string creditorName,
        string applicationDate,
        string approvalDate,
        string urlKTP,
        string urlApproval
    );

    /**
     * @notice Emitted when a delegation request is made, with additional request metadata.
     * @param nik                  The unique identifier (hashed) for the debtor.
     * @param requestId            A unique identifier for the request transaction.
     * @param creditorConsumerCode The code of the creditor acting as consumer.
     * @param creditorProviderCode The code of the creditor acting as provider.
     * @param transactionId        An external transaction ID for reference.
     * @param referenceId          An external reference ID (e.g., from another system).
     * @param requestDate          The date the request was initiated.
     */
    event DelegationRequestedMetadata(
        bytes32 indexed nik,
        string requestId,
        bytes32 creditorConsumerCode,
        bytes32 creditorProviderCode,
        string transactionId,
        string referenceId,
        string requestDate
    );

    /**
     * @notice Emitted when a package is purchased, containing relevant metadata.
     * @param institutionCode A code representing the purchasing institution.
     * @param purchaseDate    The date the package was purchased.
     * @param invoiceNumber   The invoice number for the transaction.
     * @param packageId       The identifier of the purchased package.
     * @param quantity        The quantity of packages purchased.
     * @param startDate       The start date of the package validity.
     * @param endDate         The end date of the package validity.
     * @param quota           A numeric quota or usage limit associated with the package.
     */
    event PackagePurchased(
        string institutionCode,
        string purchaseDate,
        string invoiceNumber,
        uint256 packageId,
        uint256 quantity,
        string startDate,
        string endDate,
        uint256 quota
    );

    // ------------------------------------------------------------------------
    //                             Registration
    // ------------------------------------------------------------------------
    /**
     * @dev Adds a new debtor to the system. Only callable by the platform.
     * @param nik           The unique identifier (hashed) for the debtor.
     * @param debtorAddress The Ethereum address of the debtor.
     * @notice Reverts if the debtor already exists or if the given data is invalid.
     */
    function addDebtor(
        bytes32 nik,
        address debtorAddress
    ) external onlyPlatform {
        _addDebtor(nik, debtorAddress);
    }

    /**
     * @dev Adds a new creditor to the system. Only callable by the platform.
     * @param creditorCode    The unique identifier (hashed) for the creditor.
     * @param creditorAddress The Ethereum address of the creditor.
     * @notice Reverts if the creditor already exists or if the given data is invalid.
     */
    function addCreditor(
        bytes32 creditorCode,
        address creditorAddress
    ) external onlyPlatform {
        _addCreditor(creditorCode, creditorAddress);
    }

    /**
     * @dev Adds a new creditor to the system and emits metadata. Only callable by the platform.
     * @param creditorAddress The Ethereum address of the creditor.
     * @param creditorCode    The unique identifier (hashed) for the creditor.
     * @param institutionCode A string code representing the creditor institution.
     * @param institutionName The human-readable name of the creditor institution.
     * @param approvalDate    The date on which the creditor was approved.
     * @param signerName      The name of the person who signed or approved.
     * @param signerPosition  The position or title of the signer.
     * @notice Reverts if the creditor already exists or if the given data is invalid.
     */
    function addCreditor(
        address creditorAddress,
        bytes32 creditorCode,
        string memory institutionCode,
        string memory institutionName,
        string memory approvalDate,
        string memory signerName,
        string memory signerPosition
    ) external onlyPlatform {
        _addCreditor(creditorCode, creditorAddress);
        emit CreditorAddedWithMetadata(
            creditorCode,
            institutionCode,
            institutionName,
            approvalDate,
            signerName,
            signerPosition
        );
    }

    /**
     * @dev Removes a creditor from the system. Only callable by the platform.
     * @param creditorCode The unique identifier (hashed) of the creditor to remove.
     * @notice Reverts if the creditor does not exist or if data is invalid.
     */
    function removeCreditor(bytes32 creditorCode) external onlyPlatform {
        _removeCreditor(creditorCode);
    }

    /**
     * @dev Removes a debtor from the system. Only callable by the platform.
     * @param nik The unique identifier (hashed) of the debtor to remove.
     * @notice Reverts if the debtor does not exist or if data is invalid.
     */
    function removeDebtor(bytes32 nik) external onlyPlatform {
        _removeDebtor(nik);
    }

    /**
     * @dev Retrieves the address of a creditor based on its code.
     * @param codeCreditor The unique identifier (hashed) for the creditor.
     * @return The Ethereum address of the creditor, or address(0) if not found.
     */
    function getCreditor(bytes32 codeCreditor) external view returns (address) {
        return _creditors[codeCreditor];
    }

    /**
     * @dev Retrieves the address of a debtor based on its NIK.
     * @param nik The unique identifier (hashed) for the debtor.
     * @return The Ethereum address of the debtor, or address(0) if not found.
     */
    function getDebtor(bytes32 nik) external view returns (address) {
        return _debtors[nik];
    }

    // ------------------------------------------------------------------------
    //                               Delegation
    // ------------------------------------------------------------------------
    /**
     * @dev Requests a delegation from one creditor (consumer) to another (provider) for a debtor (NIK).
     * @param nik      The unique identifier (hashed) of the debtor.
     * @param consumer The code (hashed) of the creditor acting as consumer.
     * @param provider The code (hashed) of the creditor acting as provider.
     * @notice Reverts if the caller is not the consumer or if an identical request is already pending.
     */
    function requestDelegation(
        bytes32 nik,
        bytes32 consumer,
        bytes32 provider
    ) external {
        _requestDelegation(_msgSender(), nik, consumer, provider);
    }

    /**
     * @dev Overloaded version that also emits additional metadata for the delegation request.
     * @param nik          The unique identifier (hashed) of the debtor.
     * @param consumer    The code (hashed) of the creditor acting as consumer.
     * @param provider    The code (hashed) of the creditor acting as provider.
     * @param requestId    A unique request ID.
     * @param transactionId A reference to an external transaction.
     * @param referenceId   Another external reference ID.
     * @param requestDate   The date the request is made.
     */
    function requestDelegation(
        bytes32 nik,
        bytes32 consumer,
        bytes32 provider,
        string memory requestId,
        string memory transactionId,
        string memory referenceId,
        string memory requestDate
    ) external {
        _requestDelegation(_msgSender(), nik, consumer, provider);
        emit DelegationRequestedMetadata(
            nik,
            requestId,
            consumer,
            provider,
            transactionId,
            referenceId,
            requestDate
        );
    }

    /**
     * @dev Allows a provider to approve or reject a delegation request.
     * @param nik      The unique identifier (hashed) of the debtor.
     * @param consumer The code (hashed) of the creditor acting as consumer.
     * @param provider The code (hashed) of the creditor acting as provider.
     * @param status   The final status for the request (APPROVED or REJECTED).
     * @notice Reverts if the caller is not the provider or if the request is not pending.
     */
    function delegate(
        bytes32 nik,
        bytes32 consumer,
        bytes32 provider,
        Status status
    ) external {
        _delegate(_msgSender(), nik, consumer, provider, status);
    }

    /**
     * @dev Assigns a debtor to a creditor with an APPROVED status,
     *      then emits metadata for the new relationship.
     * @param nik             The unique identifier (hashed) for the debtor.
     * @param creditor        The code (hashed) of the creditor.
     * @param name            The name of the debtor.
     * @param creditorName    A human-readable name for the creditor.
     * @param applicationDate The date the debtor applied or was introduced.
     * @param approvalDate    The date on which the debtor was approved for this creditor.
     * @param urlKTP          A URL reference for the debtor’s KTP (if any).
     * @param urlApproval     A URL reference for the approval document (if any).
     * @notice Reverts if `msg.sender` is not the platform or if data is invalid.
     */
    function addDebtorToCreditor(
        bytes32 nik,
        bytes32 creditor,
        string memory name,
        string memory creditorName,
        string memory applicationDate,
        string memory approvalDate,
        string memory urlKTP,
        string memory urlApproval
    ) external onlyPlatform {
        _addCreditorForDebtor(nik, creditor);
        emit DebtorAddedWithMetadata(
            nik,
            name,
            creditor,
            creditorName,
            applicationDate,
            approvalDate,
            urlKTP,
            urlApproval
        );
    }

    /**
     * @dev Retrieves all creditors for a given debtor, along with their respective statuses.
     * @param nik The unique identifier (hashed) for the debtor.
     * @return An array of creditor addresses and an array of corresponding statuses.
     * @notice Reverts if `_nik` is not registered.
     */
    function getDebtorDataActiveCreditors(
        bytes32 nik
    ) external view returns (address[] memory, Status[] memory) {
        (
            address[] memory creditorList,
            Status[] memory statusList
        ) = _getDebtorStatuses(nik);
        return (creditorList, statusList);
    }

    /**
     * @dev Returns the list of creditor addresses for a given debtor that match a specific status.
     * @param nik    The unique identifier (hashed) for the debtor.
     * @param status The status to filter (REJECTED, APPROVED, or PENDING).
     * @return An array of creditor addresses matching the given status.
     * @notice Reverts if `_nik` is not registered.
     */
    function getActiveCreditorsByStatus(
        bytes32 nik,
        Status status
    ) external view returns (address[] memory) {
        return _getActiveCreditorsByStatus(nik, status);
    }

    /**
     * @dev Retrieves the status of a specific creditor for a given debtor status (APPROVED, REJECTED, or PENDING).
     * @param nik      The unique identifier (hashed) for the debtor.
     * @param creditor The unique identifier (hashed) for the creditor.
     * @return status  An status from request delegation.
     */
    function getStatusRequest(
        bytes32 nik,
        bytes32 creditor
    ) external view returns (Status) {
        return _getStatusRequest(nik, creditor);
    }

    // ------------------------------------------------------------------------
    //                              Purchases
    // ------------------------------------------------------------------------
    /**
     * @dev Emitted when a package is purchased. Does not store any data, only emits the event.
     * @param institutionCode A string representing the purchasing institution code.
     * @param purchaseDate    The date of the purchase.
     * @param invoiceNumber   The invoice reference number.
     * @param packageId       The ID of the purchased package.
     * @param quantity        The quantity purchased.
     * @param startDate       The start date for the package usage.
     * @param endDate         The end date for the package usage.
     * @param quota           The usage quota associated with the package.
     */
    function purchasePackage(
        string memory institutionCode,
        string memory purchaseDate,
        string memory invoiceNumber,
        uint256 packageId,
        uint256 quantity,
        string memory startDate,
        string memory endDate,
        uint256 quota
    ) external {
        // Emit event without storing data on-chain
        emit PackagePurchased(
            institutionCode,
            purchaseDate,
            invoiceNumber,
            packageId,
            quantity,
            startDate,
            endDate,
            quota
        );
    }

    // ------------------------------------------------------------------------
    //                             Admin Functions
    // ------------------------------------------------------------------------
    /**
     * @dev Updates the platform address authorized to perform special operations.
     *      Restricted to the contract owner (via `onlyOwner`).
     * @param setNewPlatform The new platform address.
     */
    function setPlatform(address setNewPlatform) public onlyOwner {
        if (setNewPlatform == address(0)) revert InvalidAddress();
        _platform = setNewPlatform;
        emit SetNewAddressPlatform(setNewPlatform);
    }

    // ------------------------------------------------------------------------
    //                             EIP712 Functions
    // ------------------------------------------------------------------------
    /**
     * @dev This function is used to execute a meta transaction.
     * @param from         The sender of the meta transaction.
     * @param nonce        The nonce associated with the meta transaction.
     * @param functionCall The function call associated with the meta transaction.
     * @param signature    The signature of the meta transaction.
     *
     * @notice This function uses the `verify` function from the `EIP712` library to verify the signature.
     *         It is a public function that can be called by any address.
     *         It takes in four parameters: the sender, nonce, function call, and signature.
     *         It emits a `MetaTransactionExecuted` event.
     */
    function executeMetaTransaction(
        address from,
        uint256 nonce,
        bytes calldata functionCall,
        bytes calldata signature
    ) external onlyPlatform {
        _executeMetaTransaction(from, nonce, functionCall, signature);
    }
}
