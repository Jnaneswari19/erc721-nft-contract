// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

contract NftCollection is Context, ERC165, IERC721, IERC721Metadata {
    // --- State Variables ---
    string private _name;
    string private _symbol;
    uint256 private _maxSupply;
    uint256 private _totalSupply;

    // Ownership and approvals
    mapping(uint256 => address) private _owners;
    mapping(address => uint256) private _balances;
    mapping(uint256 => address) private _tokenApprovals;
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // --- Metadata ---
    mapping(uint256 => string) private _tokenURIs;

    // --- Access Control ---
    address private _admin;
    bool private _paused;

    // --- Constructor ---
    constructor(string memory name_, string memory symbol_, uint256 maxSupply_) {
        _name = name_;
        _symbol = symbol_;
        _maxSupply = maxSupply_;
        _totalSupply = 0;
        _admin = _msgSender();
        _paused = false;
    }

    // --- Modifiers ---
    modifier onlyAdmin() {
        require(_msgSender() == _admin, "Only admin can call this");
        _;
    }

    modifier whenNotPaused() {
        require(!_paused, "Minting is paused");
        _;
    }

    // --- Admin Functions ---
    function pause() external onlyAdmin {
        _paused = true;
    }

    function unpause() external onlyAdmin {
        _paused = false;
    }

    function admin() external view returns (address) {
        return _admin;
    }

    function paused() external view returns (bool) {
        return _paused;
    }

    // --- Minting Logic ---
    function mint(address to, uint256 tokenId, string memory uri) external onlyAdmin whenNotPaused {
        require(to != address(0), "Cannot mint to zero address");
        require(_owners[tokenId] == address(0), "Token already minted");
        require(_totalSupply < _maxSupply, "Max supply reached");

        _owners[tokenId] = to;
        _balances[to] += 1;
        _totalSupply += 1;
        _tokenURIs[tokenId] = uri;

        emit Transfer(address(0), to, tokenId);
    }

    function totalSupply() external view returns (uint256) {
        return _totalSupply;
    }

    function maxSupply() external view returns (uint256) {
        return _maxSupply;
    }

    // --- ERC165 ---
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC165, IERC165)
        returns (bool)
    {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    // --- ERC721 Metadata ---
    function name() external view override returns (string memory) {
        return _name;
    }

    function symbol() external view override returns (string memory) {
        return _symbol;
    }

    function tokenURI(uint256 tokenId) external view override returns (string memory) {
        require(_owners[tokenId] != address(0), "Token does not exist");
        return _tokenURIs[tokenId];
    }

    // --- ERC721 Core ---
    function balanceOf(address owner) external view override returns (uint256) {
        require(owner != address(0), "Invalid address");
        return _balances[owner];
    }

    function ownerOf(uint256 tokenId) public view override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "Token does not exist");
        return owner;
    }

    // --- Approvals ---
    function approve(address to, uint256 tokenId) external override {
        address owner = ownerOf(tokenId);
        require(to != owner, "Approval to current owner");
        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "Not owner nor approved for all"
        );

        _tokenApprovals[tokenId] = to;
        emit Approval(owner, to, tokenId);
    }

    function getApproved(uint256 tokenId) external view override returns (address) {
        require(_owners[tokenId] != address(0), "Token does not exist");
        return _tokenApprovals[tokenId];
    }

    function setApprovalForAll(address operator, bool approved) external override {
        require(operator != _msgSender(), "Cannot set approval for self");
        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    function isApprovedForAll(address owner, address operator) public view override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    // --- Transfers ---
    function transferFrom(address from, address to, uint256 tokenId) public override {
        require(ownerOf(tokenId) == from, "Not token owner");
        require(to != address(0), "Cannot transfer to zero address");

        require(
            _msgSender() == from ||
            _msgSender() == _tokenApprovals[tokenId] ||
            isApprovedForAll(from, _msgSender()),
            "Not authorized to transfer"
        );

        _tokenApprovals[tokenId] = address(0);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) external override {
        transferFrom(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, ""), "Receiver not ERC721Receiver");
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external override {
        transferFrom(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, data), "Receiver not ERC721Receiver");
    }

    // --- Internal check for safe transfers ---
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) private returns (bool) {
        if (to.code.length > 0) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch {
                return false;
            }
        }
        return true;
    }
}
