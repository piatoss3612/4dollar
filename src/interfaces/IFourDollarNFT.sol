// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface IFourDollarNFT is IERC721 {
    error ZeroAddress();
    error ZeroAmount();
    error InsufficientBalance();
    error InvalidConstructorArguments(string message);
    error InvalidLevel(uint8 level);
    error LevelNotReached(uint8 level);
    error CallFailed();

    function mint(address to, string memory _uri) external returns (uint256);
    function setTokenURI(uint256 tokenId_, string memory _uri) external;
    function tokenURI(uint256 tokenId) external view returns (string memory);
    function ownedToken(address owner) external view returns (uint256);
}
