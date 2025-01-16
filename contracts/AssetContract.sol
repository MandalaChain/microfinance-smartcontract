// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {ERC721A} from "erc721a/contracts/ERC721A.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

error DataNotExist();
error DataAlreadyExists();
error InvalidTokenId();
error DataAlreadyRedeemed();
error DataExpired();
error TransferNotAllowed();
error TokenNotExists();
error DocumentNotApproved();
error DocumentAlreadyApproved();
error Unauthorized();

/**
 * @title AssetContract
 * @dev ERC721A contract for managing asset Datas as soulbound tokens.
 *      Datas are issued, verified, redeemed, and extended, ensuring uniqueness and immutability.
 */
contract AssetContract is ERC721A, Ownable {
    /**
     * @dev Enum representing the status of a asset Data.
     * @param Active    The Data is active and can be redeemed.
     * @param Redeemed  The Data has been redeemed and cannot be used again.
     * @param Expired   The Data has expired and is no longer valid.
     */
    enum AssetStatus {
        Active,
        Redeemed,
        Expired
    }

    /**
     * @dev Struct representing the details of a asset Data.
     * @param dataOwner         The address that owns the Data.
     * @param data              The data associated with the Data.
     * @param createdDated      The date the Data was created.
     * @param assetStatus       The current status of the Data.
     * @param onChainUrl        The on-chain URL of the Data.
     */
    struct Data {
        address dataOwner;
        string data;
        uint256 createdDated;
        AssetStatus assetStatus;
        string onChainUrl;
    }

    /// @notice Mapping from address to approved owner.
    mapping(address => bool) private _approveOwner;

    /// @notice Mapping from token ID to approved document types.
    mapping(bytes32 => bool) private _approceDocTypes;

    /// @notice Mapping from Data hash to token ID.
    mapping(bytes32 => uint256) private _dataHashes;

    /// @notice Mapping from token ID to Data details.
    mapping(uint256 => mapping(bytes32 => Data)) private _assetData;

    /**
     * @dev Emitted when a new Data is issued.
     * @param tokenId       The unique identifier for the issued Data token.
     * @param issuer        The address that issued the Data.
     * @param dataHash      The unique hash representing the Data data
     * @param createdDated  The date the Data was created.
     */
    event DataIssued(
        uint256 indexed tokenId,
        address issuer,
        bytes32 dataHash,
        bytes32 docType,
        uint256 createdDated
    );

    /**
     * @dev Emitted when a Data's on-chain URL is set.
     * @param tokenId        The unique identifier for the Data token.
     * @param onChainUrl     The on-chain URL of the Data.
     */
    event SetDataURL(uint256 indexed tokenId, string onChainUrl);

    /**
     * @dev Emitted when a Data is validated.
     * @param dataHash      The unique hash representing the Data data.
     * @param isValid       Indicates whether the Data is valid.
     */
    event DataValidated(bytes32 dataHash, bool isValid);

    /**
     * @dev Emitted when a Data is redeemed.
     * @param tokenId        The unique identifier for the redeemed Data token.
     * @param redeemedBy     The address that redeemed the Data.
     */
    event Redeemed(uint256 tokenId, address redeemedBy);

    /**
     * @dev Emitted when a Data's expiration date is extended.
     * @param dataHash      The unique hash representing the Data data.
     * @param extendDate    The new expiration date of the Data.
     */
    event DataExtended(bytes32 indexed dataHash, uint256 indexed extendDate);

    /**
     * @dev Emitted when a document type is approved.
     * @param docTypeHash   The unique hash representing the document type.
     */
    event DocumentApproved(bytes32 indexed docTypeHash);

    /**
     * @dev Initializes the contract by setting the token name and symbol.
     *      Also sets the deployer as the initial owner.
     */
    constructor(
        string memory _name,
        string memory _symbol
    ) ERC721A(_name, _symbol) Ownable(msg.sender) {}

    /**
     ** =============================================================================
     **                                 MODIFIERS
     ** =============================================================================
     */
    function _checkEligible(address _client) private view {
        if (!_approveOwner[_client]) {
            revert Unauthorized();
        }
    }

    function _checkDocTypeApproves(bytes32 docType) private view {
        if (!_approceDocTypes[docType]) {
            revert DocumentNotApproved();
        }
    }

    modifier _checkOwnerAndDocType(address _client, bytes32 docType) {
        _checkEligible(_client);
        _checkDocTypeApproves(docType);
        _;
    }

    /**
     ** =============================================================================
     **                               ADMIN FUNCTION
     ** =============================================================================
     */
    /**
     * @notice Approves a document type.
     * @dev Can only be called by the contract owner.
     * @param docType The unique identifier for the document type to be approved.
     *
     * Requirements:
     * - The document type must not already be approved.
     */
    function approveDocType(string memory docType) external onlyOwner {
        bytes32 _docTypeHash = keccak256(abi.encode(docType));
        if (_approceDocTypes[_docTypeHash]) {
            revert DocumentAlreadyApproved();
        }
        _approceDocTypes[_docTypeHash] = true;
        emit DocumentApproved(_docTypeHash);
    }

    /**
     * @notice Approves an owner.
     * @dev Can only be called by the contract owner.
     * @param _client The address of the owner to be approved.
     * @param status  The approval status of the owner.
     *
     * Requirements:
     * - The owner must not already be approved.
     */
    function setApproveClient(address _client, bool status) external onlyOwner {
        _approveOwner[_client] = status;
    }

    /**
     ** =============================================================================
     **                              EXTERNAL FUNCTION
     ** =============================================================================
     */

    /**
     * @notice Mints a new asset data.
     * @dev Can only be called by the contract owner.
     *      Generates a unique hash for the data and ensures no duplicates.
     *
     * @param dataHash      The unique hash representing the data data.
     * @param assetData     The user associated with the data.
     *
     * Requirements:
     * - The data hash must not already exist.
     */
    function mintData(
        bytes32 dataHash,
        bytes32 docType,
        string memory assetData
    ) external _checkOwnerAndDocType(msg.sender, docType) {
        // Check if the data already exists
        if (_dataHashes[dataHash] != 0) {
            revert DataAlreadyExists();
        }

        // Check docType is approve or not
        if (!_approceDocTypes[docType]) {
            revert DocumentNotApproved();
        }

        uint256 tokenId = _nextTokenId();
        _mint(owner(), 1);

        uint256 _timeCreated = block.timestamp;
        _dataHashes[dataHash] = tokenId;
        _assetData[tokenId][docType] = Data({
            dataOwner: msg.sender,
            data: assetData,
            createdDated: _timeCreated,
            assetStatus: AssetStatus.Active,
            onChainUrl: ""
        });

        emit DataIssued(tokenId, msg.sender, dataHash, docType, _timeCreated);
    }

    /**
     * @notice Verifies the validity of a data based on its hash.
     * @dev Returns true if the data exists, is not expired, and has not been redeemed.
     * @param dataHash The unique hash representing the data data.
     */
    function verifyData(bytes32 dataHash, bytes32 docType) external {
        (Data memory _data, ) = _getTokenData(dataHash, docType);
        if (_data.assetStatus == AssetStatus.Redeemed) {
            revert DataAlreadyRedeemed();
        }
        if (_data.assetStatus == AssetStatus.Expired) {
            revert DataExpired();
        }
        emit DataValidated(dataHash, true);
    }

    /**
     * @notice Sets the on-chain URL of a data.
     * @dev Can only be called by the contract owner.
     * @param dataHash  The unique hash representing the data data.
     * @param url       The on-chain URL of the data.
     *
     * Requirements:
     * - The data must exist.
     */
    function setOnChainURL(
        bytes32 dataHash,
        bytes32 docType,
        string memory url
    ) external _checkOwnerAndDocType(msg.sender, docType) {
        (, uint256 _tokenId) = _getTokenData(dataHash, docType);
        _assetData[_tokenId][docType].onChainUrl = url;
        emit SetDataURL(_tokenId, url);
    }

    /**
     * @notice Redeems a data by updating its status to Redeemed.
     * @dev Can only be called by the contract owner.
     * @param dataHash The unique identifier for the data token to be redeemed.
     *
     * Requirements:
     * - The data must exist.
     * - The data must not be expired.
     * - The data must not have been redeemed already.
     */
    function redeemData(
        bytes32 dataHash,
        bytes32 docType
    ) external _checkOwnerAndDocType(msg.sender, docType) {
        (Data memory _data, uint256 _tokenId) = _getTokenData(
            dataHash,
            docType
        );
        if (_data.assetStatus == AssetStatus.Redeemed) {
            revert DataAlreadyRedeemed();
        }

        // Update status to Redeemed
        _assetData[_tokenId][docType].assetStatus = AssetStatus.Redeemed;

        emit Redeemed(_tokenId, msg.sender);
    }

    /**
     * @notice Retrieves the data data associated with a specific hash.
     * @param dataHash The unique hash representing the data data.
     * @return data The data struct containing all data details.
     *
     * Requirements:
     * - The data must exist.
     * - The token ID associated with the hash must be valid.
     */
    function getAssetData(
        bytes32 dataHash,
        bytes32 docType
    ) external view returns (Data memory) {
        (Data memory _data, ) = _getTokenData(dataHash, docType);
        return _data;
    }

    /**
     * @notice Retrieves time created of the data data associated with a specific hash.
     * @param dataHash The unique hash representing the data data.
     * @return Time created of the data.
     *
     * Requirements:
     * - The data must exist.
     * - The token ID associated with the hash must be valid.
     */
    function getDateMintingData(
        bytes32 dataHash,
        bytes32 docType
    ) external view returns (uint256) {
        uint256 _tokenId = _dataHashes[dataHash];
        if (_tokenId == 0) revert DataNotExist();
        if (!_exists(_tokenId)) revert InvalidTokenId();
        return _assetData[_tokenId][docType].createdDated;
    }

    /**
     ** =============================================================================
     **                              INTERNAL FUNCTION
     ** =============================================================================
     */

    /**
     * @notice Retrieves the token ID associated with a given data hash.
     * @param _dataHash The unique hash representing the data data.
     * @return uint256 The token ID associated with the data hash and the data data.
     *
     * Requirements:
     * - The data must exist.
     * - Token must exist.
     */
    function _getTokenData(
        bytes32 _dataHash,
        bytes32 docType
    ) internal view returns (Data memory, uint256) {
        uint256 _tokenId = _dataHashes[_dataHash];
        if (_tokenId == 0) {
            revert DataNotExist();
        }
        if (!_exists(_tokenId)) {
            revert TokenNotExists();
        }

        return (_assetData[_tokenId][docType], _tokenId);
    }

    /**
     ** =============================================================================
     **                              SOULBOND TOKEN
     ** =============================================================================
     */

    /**
     * @dev Overrides the ERC721A hook to prevent token transfers, ensuring tokens are soulbound.
     * @param from          The address transferring the token.
     * @param to            The address receiving the token.
     * @param startTokenId  The ID of the token being transferred.
     * @param quantity      The number of tokens being transferred.
     *
     * Requirements:
     * - Tokens cannot be transferred between addresses after minting.
     */
    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal override {
        if (from != address(0) && to != address(0)) {
            revert TransferNotAllowed();
        }
        super._beforeTokenTransfers(from, to, startTokenId, quantity);
    }

    /**
     * @dev Overrides the ERC721A approve function to prevent approvals, maintaining the soulbound nature.
     * @param to        The address to approve.
     * @param tokenId   The ID of the token.
     *
     * Requirements:
     * - Approvals are not allowed for any token.
     */
    function approve(
        address to,
        uint256 tokenId
    ) public payable override onlyOwner {
        if (to != address(0) && tokenId == 0) {
            revert TransferNotAllowed();
        }
        revert TransferNotAllowed();
    }

    /**
     * @dev Overrides the ERC721A setApprovalForAll function to prevent approvals, maintaining the soulbound nature.
     * @param operator  The address to set as an operator.
     * @param approved  The approval status.
     *
     * Requirements:
     * - Operators cannot be approved for any tokens.
     */
    function setApprovalForAll(
        address operator,
        bool approved
    ) public pure override {
        if (operator != address(0) && approved == true) {
            revert TransferNotAllowed();
        }
        revert TransferNotAllowed();
    }

    /**
     * @dev Sets the starting token ID to 1 instead of the default 0.
     * @return uint256 The starting token ID.
     */
    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }
}
