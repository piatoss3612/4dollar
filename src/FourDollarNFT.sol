// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {IFourDollarNFT} from "./interfaces/IFourDollarNFT.sol";
import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {ERC721URIStorage} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract FourDollarNFT is IFourDollarNFT, ERC721, ERC721URIStorage, Ownable {
    error OnlyOwnerOfToken();
    error SoulBound();
    error OwnableTransferNotAllowed();

    uint256 private _tokenId;

    constructor(string memory _name, string memory _symbol) ERC721(_name, _symbol) Ownable(msg.sender) {}

    /*
    ==============================
    ||    Public functions      ||
    ==============================
    */

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(IERC165, ERC721, ERC721URIStorage)
        returns (bool)
    {
        return interfaceId == type(IFourDollarNFT).interfaceId || super.supportsInterface(interfaceId);
    }

    function tokenURI(uint256 tokenId) public view virtual override(ERC721, ERC721URIStorage) returns (string memory) {
        return super.tokenURI(tokenId);
    }

    function mint(address to, string memory _uri) public override onlyOwner returns (uint256) {
        return _mint(to, _uri);
    }

    function setTokenURI(uint256 tokenId_, string memory _uri) external override onlyOwner {
        _setTokenURI(tokenId_, _uri);
    }

    /*
    ==============================
    ||   SoulBound functions    ||
    ==============================
    */

    function transferFrom(address, address, uint256) public override(IERC721, ERC721) {
        revert SoulBound();
    }

    function safeTransferFrom(address, address, uint256, bytes memory) public override(IERC721, ERC721) {
        revert SoulBound();
    }

    function approve(address, uint256) public override(IERC721, ERC721) {
        revert SoulBound();
    }

    /*
    ==============================
    ||    Internal functions    ||
    ==============================
    */
    function _mint(address to, string memory _uri) internal virtual returns (uint256) {
        uint256 tokenId_ = _tokenId++;
        _mint(to, tokenId_);
        _setTokenURI(tokenId_, _uri);
        return tokenId_;
    }

    function _transferOwnership(address) internal virtual override(Ownable) {
        revert OwnableTransferNotAllowed();
    }
}