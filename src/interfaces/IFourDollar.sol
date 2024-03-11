// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

interface IFourDollar {
    error InvalidConstructorArguments(string message);
    error InvalidLevel(uint8 level);
    error ZeroAddress();
    error PriceFeedAlreadySet(address asset);
    error InvalidPriceFeed(address asset);
    error OnlyOwnerOfToken();
    error LevelNotReached(uint8 level);

    event FourDollarCreated(address indexed owner, uint256 totalLevels);
    event PriceFeedSet(address indexed asset, address indexed priceFeed);
    event Upgrade(address indexed owner, uint256 indexed tokenId, uint8 indexed level);
    event Donation(address indexed donator, address indexed asset, uint256 amount);

    function setPriceFeed(address _asset, address _priceFeed) external;
    function priceFeed(address _asset) external view returns (address);
    function currentLevel(uint256 _tokenId) external view returns (uint8);
    function donationAmount(address _donator) external view returns (uint256);
    function levelToTokenURI(uint8 _level) external view returns (string memory);
    function levelToDonationCount(uint8 _level) external view returns (uint256);
    function setTokenURI(uint256 tokenId_, uint8 _level) external;
    function donate(address _asset, uint256 _amount) external;
}
