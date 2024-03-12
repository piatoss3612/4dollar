// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

interface IFourDollar {
    error ZeroAddress();
    error ZeroAmount();
    error InsufficientBalance();
    error InvalidConstructorArguments(string message);
    error InvalidLevel(uint8 level);
    error LevelNotReached(uint8 level);
    error CallFailed();

    event Creation(address indexed owner, uint256 totalLevels);
    event Upgrade(address indexed owner, uint256 indexed tokenId, uint8 indexed level);
    event Donation(address indexed donator, address indexed asset, uint256 amount);

    function currentLevel(uint256 _tokenId) external view returns (uint8);
    function donationAmountInUSD(address _donator) external view returns (uint256);
    function levelToTokenURI(uint8 _level) external view returns (string memory);
    function levelToDonationCount(uint8 _level) external view returns (uint256);
    function setTokenURI(uint256 tokenId_, uint8 _level) external;
    function calculateBaseAssetAmountInUSD(uint256 _amount) external view returns (uint256);
    function donate() external payable;
    function withdraw(address _to, uint256 _amount) external;
    function call(address _to, uint256 _amount, bytes calldata _data) external returns (bytes memory);
}
