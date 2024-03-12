// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import "../../src/interfaces/ISimpleOracle.sol";

contract MockSimpleOracle is ISimpleOracle {
    mapping(address => address) public priceFeeds;

    function setPriceFeed(address _asset, address _priceFeed) external {
        priceFeeds[_asset] = _priceFeed;
    }

    function priceFeed(address _asset) external view returns (address) {
        return priceFeeds[_asset];
    }

    function latestBaseAssetPrice() external pure returns (uint256 _price, uint8 _decimals) {
        return (123456789, 8);
    }

    function latestAssetPrice(address) external pure returns (uint256, uint8) {
        revert("Not implemented");
    }
}
