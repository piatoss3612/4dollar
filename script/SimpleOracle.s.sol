// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import "forge-std/Script.sol";
import {SimpleOracleChainlink} from "../src/SimpleOracleChainlink.sol";
import {Configs} from "../src/configs/Configs.sol";

contract SimpleOracleScript is Script {
    function setUp() public {}

    function run() public {
        uint256 privateKey = vm.envUint("PRIVATE_KEY");
        uint256 chainid = block.chainid;

        console.log(chainid);

        address priceFeed;

        if (chainid == 80001) {
            // mumbai testnet
            priceFeed = Configs.CHAINLINK_MATIC_USD_MUMBAI_ADDRESS;
        } else if (chainid == 137) {
            // polygon mainnet
            priceFeed = Configs.CHAINLINK_MATIC_USD_POLYGON_ADDRESS;
        } else {
            revert("Unsupported chainid");
        }

        vm.startBroadcast(privateKey);

        SimpleOracleChainlink oracle = SimpleOracleChainlink(0x9F3CF7c78E024B94cd12F36f037ef8ab2aFab26c);

        (uint256 price, uint8 decimals) = oracle.latestBaseAssetPrice();

        console.log("Price:", price);
        console.log("Decimals:", decimals);

        vm.stopBroadcast();
    }
}
