// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import "forge-std/Script.sol";
import {SimpleOracleChainlink} from "../src/SimpleOracleChainlink.sol";
import {FourDollarV1} from "../src/FourDollarV1.sol";
import {FourDollarProxy} from "../src/FourDollarProxy.sol";
import {Configs} from "../src/configs/Configs.sol";

contract FourDollarV1Script is Script {
    function setUp() public {}

    function run() public {
        uint256 privateKey = vm.envUint("PRIVATE_KEY");
        uint256 chainid = block.chainid;

        address priceFeed;

        if (chainid == 80001) {
            // mumbai testnet
            priceFeed = Configs.CHAINLINK_MATIC_USD_MUMBAI_ADDRESS;
        } else if (chainid == 137) {
            // polygon mainnet
            priceFeed = Configs.CHAINLINK_MATIC_USD_POLYGON_ADDRESS;
        } else if (chainid == 11155111) {
            // sepolia testnet
            priceFeed = Configs.CHAINLINK_ETH_USD_SEPOLIA_ADDRESS;
        } else {
            revert("Unsupported chainid");
        }

        uint8[] memory levels = new uint8[](4);
        string[] memory uris = new string[](4);

        levels[0] = 1;
        levels[1] = 3;
        levels[2] = 5;
        levels[3] = 10;

        uris[0] = "ipfs://QmaYDcSmzD63DQ8Ccio1ijiQnWvxnY4TDgZUEMH51RQiWW";
        uris[1] = "ipfs://Qme1RRc4Wnf7fS72T3cpshDHN1u14uk4c9SZ3y55mtj58p";
        uris[2] = "ipfs://QmbgruwjEoUZfM1hLzNDNvELLWAprpzxaxJkdWHxrbLqKP";
        uris[3] = "ipfs://QmQmnkLwCX5n6ZWntXRGtdLDappyPtdQS8XfXFKCvp4c4J";

        string memory name = "PIATOSS";
        string memory symbol = "PTS";

        vm.startBroadcast(privateKey);

        SimpleOracleChainlink oracle = new SimpleOracleChainlink(priceFeed);

        console.log("Deployed SimpleOracleChainlink at", address(oracle));

        FourDollarV1 impl = new FourDollarV1();

        bytes memory data = abi.encodeWithSelector(impl.initialize.selector, name, symbol, levels, uris, oracle);

        FourDollarProxy proxy = new FourDollarProxy(address(impl), data);

        console.log("Deployed FourDollarV1Proxy at", address(proxy));

        vm.stopBroadcast();
    }
}

contract WithdrawScript is Script {
    function setUp() public {}

    function run() public {
        uint256 privateKey = vm.envUint("PRIVATE_KEY");
        uint256 chainid = block.chainid;

        address proxy;

        if (chainid == 80001) {
            // mumbai testnet
            proxy = 0x99eb4FA25e0a3a4Eb8E7b53370D74ca76AF4b575;
        } else if (chainid == 137) {
            // polygon mainnet
        } else if (chainid == 11155111) {
            // sepolia testnet
            proxy = 0x203A36744dD130f1De981EC72c2144862aECE6AA;
        } else {
            revert("Unsupported chainid");
        }

        vm.startBroadcast(privateKey);

        FourDollarV1 proxyContract = FourDollarV1(payable(proxy));

        uint256 amountToWithdraw = proxy.balance;

        proxyContract.withdraw(vm.addr(privateKey), amountToWithdraw);

        vm.stopBroadcast();

        console.log("Withdrawn", amountToWithdraw, "ETH from", address(proxy));
    }
}
