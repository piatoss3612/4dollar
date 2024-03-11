// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

interface ISimpleOracle {
    error PriceFeedAlreadySet(address asset);
    error InvalidPriceFeed(address asset);

    event PriceFeedSet(address indexed asset, address indexed priceFeed);

    function setPriceFeed(address _asset, address _priceFeed) external;
    function priceFeed(address _asset) external view returns (address);
    function latestBaseAssetPrice() external view returns (uint256 _price, uint8 _decimals);
    function latestAssetPrice(address _asset) external view returns (uint256 _price, uint8 _decimals);
}
