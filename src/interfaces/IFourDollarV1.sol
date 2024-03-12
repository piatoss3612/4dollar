// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

interface IFourDollarV1 {
    error ZeroAddress();
    error ZeroAmount();
    error InsufficientBalance();
    error InvalidConstructorArguments(string message);
    error InvalidLevel(uint8 level);
    error LevelNotReached(uint8 level);
    error CallFailed();

    event Initialize(address indexed owner, uint256 totalLevels);
    event LevelUp(address indexed owner, uint8 indexed level);
    event Donate(address indexed donator, address indexed asset, uint256 assetAmount, uint256 usdAmount);
    event Transfer(address indexed to, uint256 amount);

    function version() external pure returns (string memory);
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
