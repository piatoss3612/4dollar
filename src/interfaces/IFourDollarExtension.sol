// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {IFourDollar} from "./IFourDollar.sol";

interface IFourDollarExtension is IFourDollar {
    function donateERC20(address _asset, uint256 _amount) external;
    function donateERC721(address _asset, uint256 _tokenId) external;
    function callWithAsset(address _asset, address _to, uint256 _amount, bytes calldata _data)
        external
        returns (bytes memory);
}
