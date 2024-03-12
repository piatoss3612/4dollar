// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {ISimpleOracle} from "./interfaces/ISimpleOracle.sol";
import {AggregatorV3Interface} from "./interfaces/AggregatorV3Interface.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract SimpleOracleChainlink is ISimpleOracle, Ownable {
    AggregatorV3Interface private immutable _baseAssetPriceFeed;

    mapping(address asset => address priceFeed) private _priceFeeds;

    constructor(address _baseAssetPriceFeed_) Ownable(msg.sender) {
        _baseAssetPriceFeed = AggregatorV3Interface(_baseAssetPriceFeed_);
    }

    function setPriceFeed(address _asset, address _priceFeed) external override onlyOwner {
        if (_priceFeeds[_asset] != address(0)) {
            revert PriceFeedAlreadySet(_asset);
        }
        _priceFeeds[_asset] = _priceFeed;
        emit PriceFeedSet(_asset, _priceFeed);
    }

    function priceFeed(address _asset) external view override returns (address) {
        return _priceFeeds[_asset];
    }

    function latestBaseAssetPrice() external view override returns (uint256 _price, uint8 _decimals) {
        (, int256 price,,,) = _baseAssetPriceFeed.latestRoundData();
        if (price < 0) {
            revert InvalidPrice();
        }
        return (uint256(price), _baseAssetPriceFeed.decimals());
    }

    function latestAssetPrice(address _asset) external view override returns (uint256 _price, uint8 _decimals) {
        address assetPriceFeed = _priceFeeds[_asset];
        if (assetPriceFeed == address(0)) {
            revert InvalidPriceFeed(_asset);
        }

        AggregatorV3Interface target = AggregatorV3Interface(assetPriceFeed);

        (, int256 price,,,) = target.latestRoundData();
        if (price < 0) {
            revert InvalidPrice();
        }
        return (uint256(price), target.decimals());
    }
}
