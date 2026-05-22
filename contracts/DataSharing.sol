/*
 * SPDX-License-Identifier: MIT
 *
 * @title DataSharing Contract
 * @dev This contract extends the `Delegation` contract to manage data sharing
 *      and delegation approvals among creditors and debtors. It leverages
 *      mapping-based storage for efficient lookups and includes metadata
 *      emission for tracking important actions.
 *
 * ## Features:
 * - Integrates with the `Delegation` system for creditor-debtor relationships.
 * - Supports adding and removing debtors/creditors with associated metadata.
 * - Includes event emission for purchase packages and delegation approvals.
 * - Allows only the platform address (and contract owner for platform updates) to perform
 *   certain registration and removal functions.
 *
 * @custom:error AddressNotEligible - Thrown when `msg.sender` is not the expected address (e.g., `_platform`).
 * @custom:error InvalidHash        - Thrown when a provided identifier is empty (bytes32(0)).
 * @custom:error NikNeedRegistered  - Thrown when the provided NIK is not registered.
 * @custom:error ProviderNotEligible - Thrown when the provider is not in an APPROVED status for a debtor.
 */

pragma solidity 0.8.28;

import {Ownable, Context} from "@openzeppelin/contracts/access/Ownable.sol";
import {Delegation} from "./core/Delegation.sol";
import {MetaTransaction} from "./core/MetaTransaction.sol";

/**
 * @title DataSharing
 * @notice Manages the high-level interactions for registration and delegation of debtors and creditors,
 *         while emitting metadata-driven events for tracking and auditing.
 * @dev Inherits from `Delegation` (which itself extends `Registration`) and `Ownable`.
 */
contract DataSharing is Delegation, MetaTransaction, Ownable {
    error AddressNotEligible();

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

    constructor() Ownable(msg.sender) {
        setPlatform(msg.sender);
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
     * @notice Emitted when a debtor is registered through the plain addDebtor path.
     * @param nik           The unique identifier (hashed) for the debtor.
     * @param debtorAddress The Ethereum address assigned to the debtor.
     */
    event DebtorAdded(bytes32 indexed nik, address indexed debtorAddress);

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
    event DelegationMetadata(
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

    /**
     * @param nik                   The unique identifier (hashed) for the debtor.
     * @param consumer              The code (hashed) of the creditor acting as consumer.
     * @param provider              The code (hashed) of the creditor acting as provider.
     * @param metadata              Additional metadata for the action request.
     */
    event ProcessAction(
        bytes32 indexed nik,
        bytes32 indexed consumer,
        bytes32 indexed provider,
        string metadata
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
        emit DebtorAdded(nik, debtorAddress);
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
     * @dev Approves a delegation and emits additional metadata for the relationship.
     * @param nik          The unique identifier (hashed) of the debtor.
     * @param consumer    The code (hashed) of the creditor acting as consumer.
     * @param provider    The code (hashed) of the creditor acting as provider.
     * @param requestId    A unique request ID.
     * @param transactionId A reference to an external transaction.
     * @param referenceId   Another external reference ID.
     * @param requestDate   The date the request is made.
     */
    function delegate(
        bytes32 nik,
        bytes32 consumer,
        bytes32 provider,
        string memory requestId,
        string memory transactionId,
        string memory referenceId,
        string memory requestDate
    ) external onlyPlatform {
        _delegate(nik, consumer, provider);
        emit DelegationMetadata(
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
     * @dev Approves a delegation relationship.
     * @param nik      The unique identifier (hashed) of the debtor.
     * @param consumer The code (hashed) of the creditor acting as consumer.
     * @param provider The code (hashed) of the creditor acting as provider.
     * @notice Reverts if the provider is not already approved for the debtor or the delegation already exists.
     */
    function delegate(
        bytes32 nik,
        bytes32 consumer,
        bytes32 provider
    ) external onlyPlatform {
        _delegate(nik, consumer, provider);
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

    // combine function delegate with addDebtorToCreditor
    function processAction(
        bytes32 nik,
        bytes32 consumer,
        bytes32 provider,
        string memory metadata
    ) external onlyPlatform {
        _processAction(nik, consumer, provider);
        emit ProcessAction(nik, consumer, provider, metadata);
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
     * @return An array of creditor addresses matching the given status.
     * @notice Reverts if `_nik` is not registered.
     */
    function getActiveCreditors(
        bytes32 nik
    ) external view returns (address[] memory) {
        return _getActiveCreditors(nik);
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
    ) external onlyPlatform {
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

    // ------------------------------------------------------------------
    //  MetaTransaction Implementation
    // ------------------------------------------------------------------

    /// @dev EIP-712 domain name and version for meta-transaction verification.
    function _domainNameAndVersion()
        internal
        view
        virtual
        override
        returns (string memory name, string memory version)
    {
        name = "Data-Sharing-MetaTransaction";
        version = "1.0";
    }

    /**
     * @notice Executes a meta-transaction on behalf of `from` after validating
     *         the EIP-712 signature and nonce.
     * @param from         The original signer whose intent is being relayed.
     * @param nonce        Must match the current nonce for `from`.
     * @param functionCall ABI-encoded function call to execute on this contract.
     * @param signature    EIP-712 signature produced by `from` over the payload.
     */
    function executeMetaTransaction(
        address from,
        uint256 nonce,
        bytes calldata functionCall,
        bytes calldata signature
    ) external {
        _executeMetaTransaction(from, nonce, functionCall, signature);
    }

    /**
     * @notice Returns the actual sender of the transaction, supporting meta-transactions
     * @dev Overrides both MetaTransaction and Context versions to prioritize meta-transaction logic.
     *      This enables gasless transactions where a relayer can submit transactions on behalf of users.
     * @return sender The actual transaction sender (may differ from msg.sender in meta-transactions)
     */
    function _msgSender()
        internal
        view
        override(MetaTransaction, Context)
        returns (address sender)
    {
        return MetaTransaction._msgSender();
    }
}
