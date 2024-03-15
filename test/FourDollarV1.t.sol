// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import "forge-std/Test.sol";
import {IFourDollarV1} from "../src/interfaces/IFourDollarV1.sol";
import {FourDollarNFT} from "../src/FourDollarNFT.sol";
import {FourDollarV1} from "../src/FourDollarV1.sol";
import {FourDollarProxy} from "../src/FourDollarProxy.sol";
import {MockSimpleOracle} from "./mock/MockSimpleOracle.sol";

contract FourDollarV1Test is Test {
    error InvalidInitialization();
    error ZeroAmount();
    error ZeroAddress();
    error InsufficientBalance();
    error OnlyOwnerOfToken();
    error LevelNotReached(uint8 level);
    error OwnableUnauthorizedAccount(address account);
    error OwnableTransferNotAllowed();

    FourDollarV1 public impl;
    FourDollarProxy public proxy;
    MockSimpleOracle public oracle;

    string public name;
    string public symbol;
    uint8[] public levels;
    string[] public uris;

    Account public owner;
    Account public donator;

    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    function setUp() public {
        owner = makeAccount("owner");
        donator = makeAccount("donator");
        vm.deal(donator.addr, 100 ether);

        vm.startPrank(owner.addr);

        oracle = new MockSimpleOracle();
        impl = new FourDollarV1();

        for (uint8 i = 0; i < 5; i++) {
            levels.push(i + 1);
            uris.push(string(abi.encodePacked("ipfs://ipfs.io/", keccak256(abi.encodePacked(i)))));
        }

        name = "FourDollarTest";
        symbol = "FDT";

        bytes memory data = abi.encodeWithSelector(impl.initialize.selector, name, symbol, levels, uris, oracle);

        proxy = new FourDollarProxy(address(impl), data);

        vm.stopPrank();

        FourDollarV1 instance = FourDollarV1(payable(address(proxy)));

        assertEq(instance.owner(), owner.addr);
        assertEq(address(instance.oracle()), address(oracle));
        assertEq(instance.version(), "v1");
        assertEq(instance.donationAmountInUSD(donator.addr), 0);
        assertEq(instance.levelToTokenURI(0), uris[0]);
        assertEq(instance.levelToTokenURI(10), uris[levels.length - 1]);
        assertEq(instance.levelToDonationCount(0), levels[0]);
        assertEq(instance.levelToDonationCount(10), levels[levels.length - 1]);

        FourDollarNFT nft = FourDollarNFT(address(instance.nft()));

        assertEq(nft.name(), name);
        assertEq(nft.symbol(), symbol);
    }

    function test_RevertInitializeByTryingReinitialization() public {
        FourDollarV1 instance = FourDollarV1(payable(address(proxy)));

        uint8[] memory newLevels = new uint8[](5);
        string[] memory newUris = new string[](5);

        for (uint8 i = 0; i < 5; i++) {
            newLevels[i] = i + 1;
            newUris[i] = string(abi.encodePacked("ipfs://ipfs.io/", i + 1));
        }

        vm.expectRevert(InvalidInitialization.selector);

        vm.prank(owner.addr);
        instance.initialize(name, symbol, newLevels, newUris, oracle);
    }

    function test_DonateMoreThan4Dollar() public {
        FourDollarV1 instance = FourDollarV1(payable(address(proxy)));

        uint256 amount = 4 ether;
        uint256 usdAmount = instance.calculateBaseAssetAmountInUSD(amount);

        vm.expectEmit(true, true, true, true);
        emit Transfer(address(0), donator.addr, 1);
        vm.expectEmit(true, true, true, true);
        emit IFourDollarV1.LevelUp(donator.addr, 1);
        vm.expectEmit(true, true, true, true);
        emit IFourDollarV1.Donate(donator.addr, address(0), amount, usdAmount);

        vm.prank(donator.addr);
        instance.donate{value: amount}();

        assertEq(instance.donationAmountInUSD(donator.addr), usdAmount);
        assertEq(instance.nft().balanceOf(donator.addr), 1);
        assertEq(instance.nft().ownerOf(1), donator.addr);
        assertEq(instance.currentLevel(1), 1);
        assertEq(instance.nft().tokenURI(1), uris[1]);
    }

    function test_DonateMoreThan4DollarViaReceive() public {
        FourDollarV1 instance = FourDollarV1(payable(address(proxy)));

        uint256 amount = 4 ether;
        uint256 usdAmount = instance.calculateBaseAssetAmountInUSD(amount);

        vm.expectEmit(true, true, true, true);
        emit Transfer(address(0), donator.addr, 1);
        vm.expectEmit(true, true, true, true);
        emit IFourDollarV1.LevelUp(donator.addr, 1);
        vm.expectEmit(true, true, true, true);
        emit IFourDollarV1.Donate(donator.addr, address(0), amount, usdAmount);

        vm.prank(donator.addr);
        (bool ok,) = address(instance).call{value: amount}("");
        assertTrue(ok);

        assertEq(instance.donationAmountInUSD(donator.addr), usdAmount);
        assertEq(instance.nft().balanceOf(donator.addr), 1);
        assertEq(instance.nft().ownerOf(1), donator.addr);
        assertEq(instance.currentLevel(1), 1);
        assertEq(instance.nft().tokenURI(1), uris[1]);
    }

    function test_DonateMoreThan4DollarViaFallback() public {
        FourDollarV1 instance = FourDollarV1(payable(address(proxy)));

        uint256 amount = 4 ether;
        uint256 usdAmount = instance.calculateBaseAssetAmountInUSD(amount);

        vm.expectEmit(true, true, true, true);
        emit Transfer(address(0), donator.addr, 1);
        vm.expectEmit(true, true, true, true);
        emit IFourDollarV1.LevelUp(donator.addr, 1);
        vm.expectEmit(true, true, true, true);
        emit IFourDollarV1.Donate(donator.addr, address(0), amount, usdAmount);

        vm.prank(donator.addr);
        (bool ok,) = address(instance).call{value: amount}("fallback!");
        assertTrue(ok);

        assertEq(instance.donationAmountInUSD(donator.addr), usdAmount);
        assertEq(instance.nft().balanceOf(donator.addr), 1);
        assertEq(instance.nft().ownerOf(1), donator.addr);
        assertEq(instance.currentLevel(1), 1);
        assertEq(instance.nft().tokenURI(1), uris[1]);
    }

    function test_DonateTwiceAndIssueNFT() public {
        FourDollarV1 instance = FourDollarV1(payable(address(proxy)));

        uint256 amount = 2 ether;
        uint256 usdAmount = instance.calculateBaseAssetAmountInUSD(amount);

        vm.expectEmit(true, true, true, true);
        emit IFourDollarV1.Donate(donator.addr, address(0), amount, usdAmount);

        vm.startPrank(donator.addr);
        instance.donate{value: amount}();

        vm.expectEmit(true, true, true, true);
        emit Transfer(address(0), donator.addr, 1);
        vm.expectEmit(true, true, true, true);
        emit IFourDollarV1.LevelUp(donator.addr, 1);
        vm.expectEmit(true, true, true, true);
        emit IFourDollarV1.Donate(donator.addr, address(0), amount, usdAmount);

        instance.donate{value: amount}();

        vm.stopPrank();

        assertEq(instance.donationAmountInUSD(donator.addr), usdAmount * 2);
        assertEq(instance.nft().balanceOf(donator.addr), 1);
        assertEq(instance.nft().ownerOf(1), donator.addr);
        assertEq(instance.currentLevel(1), 1);
        assertEq(instance.nft().tokenURI(1), uris[1]);
    }

    function test_DonateAndDowngradeNFT() public {
        FourDollarV1 instance = FourDollarV1(payable(address(proxy)));

        uint256 amount = 4 ether;

        vm.startPrank(donator.addr);
        instance.donate{value: amount}();

        uint256 tokenId = instance.nft().ownedToken(donator.addr);

        assertEq(instance.nft().tokenURI(tokenId), uris[1]);

        uint8 level = instance.currentLevel(tokenId);

        assertGt(level, 0);

        instance.setTokenURI(tokenId, 0);

        assertEq(instance.nft().tokenURI(tokenId), uris[0]);
    }

    function test_DonateAndUpgradeToMaxLevel() public {
        FourDollarV1 instance = FourDollarV1(payable(address(proxy)));

        uint256 amount = 50 ether;

        vm.startPrank(donator.addr);
        instance.donate{value: amount}();

        uint256 tokenId = instance.nft().ownedToken(donator.addr);

        uint8 level = instance.currentLevel(tokenId);

        assertGe(level, levels.length);

        instance.setTokenURI(tokenId, level);

        assertEq(instance.nft().tokenURI(tokenId), uris[levels.length - 1]);
    }

    function test_RevertDonateByZeroValue() public {
        FourDollarV1 instance = FourDollarV1(payable(address(proxy)));

        vm.expectRevert(ZeroAmount.selector);

        vm.prank(donator.addr);
        instance.donate{value: 0}();
    }

    function test_Withdraw() public {
        FourDollarV1 instance = FourDollarV1(payable(address(proxy)));

        uint256 amount = 4 ether;

        vm.prank(donator.addr);
        instance.donate{value: amount}();

        uint256 balance = address(instance).balance;

        assertEq(balance, amount);

        vm.expectEmit(true, true, true, true);
        emit IFourDollarV1.Transfer(owner.addr, 4 ether);

        vm.prank(owner.addr);
        instance.withdraw(owner.addr, balance);

        assertEq(address(instance).balance, 0);
        assertEq(owner.addr.balance, balance);
    }

    function test_RevertWithdrawByZeroAddress() public {
        FourDollarV1 instance = FourDollarV1(payable(address(proxy)));

        vm.expectRevert(ZeroAddress.selector);

        vm.prank(owner.addr);
        instance.withdraw(address(0), 4 ether);
    }

    function test_RevertWithdrawByInsufficientBalance() public {
        FourDollarV1 instance = FourDollarV1(payable(address(proxy)));

        vm.expectRevert(InsufficientBalance.selector);

        vm.prank(owner.addr);
        instance.withdraw(owner.addr, 4 ether);
    }

    function test_Call() public {
        FourDollarV1 instance = FourDollarV1(payable(address(proxy)));

        uint256 amount = 4 ether;

        vm.prank(donator.addr);
        instance.donate{value: amount}();

        vm.prank(owner.addr);
        instance.call(owner.addr, amount, "");

        assertEq(address(instance).balance, 0);
        assertEq(owner.addr.balance, amount);
    }

    function test_RevertCallByZeroAddress() public {
        FourDollarV1 instance = FourDollarV1(payable(address(proxy)));

        vm.expectRevert(ZeroAddress.selector);

        vm.prank(owner.addr);
        instance.call(address(0), 4 ether, "");
    }

    function test_RevertCallByInsufficientBalance() public {
        FourDollarV1 instance = FourDollarV1(payable(address(proxy)));

        vm.expectRevert(InsufficientBalance.selector);

        vm.prank(owner.addr);
        instance.call(owner.addr, 4 ether, "");
    }

    function test_RevertSetTokenURIByNonOwner() public {
        FourDollarV1 instance = FourDollarV1(payable(address(proxy)));

        uint256 amount = 4 ether;

        vm.prank(donator.addr);
        instance.donate{value: amount}();

        vm.expectRevert(OnlyOwnerOfToken.selector);

        vm.prank(owner.addr);
        instance.setTokenURI(1, 1);
    }

    function test_RevertSetTokenURIByLevelNotReached() public {
        FourDollarV1 instance = FourDollarV1(payable(address(proxy)));

        uint256 amount = 4 ether;

        vm.prank(donator.addr);
        instance.donate{value: amount}();

        vm.expectRevert(abi.encodePacked(LevelNotReached.selector, abi.encode(levels.length - 1)));

        vm.prank(donator.addr);
        instance.setTokenURI(1, 10);
    }

    function test_UpgradeToAndCall() public {
        FourDollarV1 newImpl = new FourDollarV1();

        FourDollarV1 instance = FourDollarV1(payable(address(proxy)));

        vm.prank(owner.addr);
        instance.upgradeToAndCall(address(newImpl), "");
    }

    function test_RevertUpgradeToAndCallByNonOwner() public {
        FourDollarV1 newImpl = new FourDollarV1();

        FourDollarV1 instance = FourDollarV1(payable(address(proxy)));

        vm.expectRevert(abi.encodeWithSelector(OwnableUnauthorizedAccount.selector, donator.addr));

        vm.prank(donator.addr);
        instance.upgradeToAndCall(address(newImpl), "");
    }

    function test_RevertTransferOwnership() public {
        FourDollarV1 instance = FourDollarV1(payable(address(proxy)));

        vm.expectRevert(OwnableTransferNotAllowed.selector);

        vm.prank(owner.addr);
        instance.transferOwnership(donator.addr);
    }
}
