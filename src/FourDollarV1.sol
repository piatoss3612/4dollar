// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {IFourDollarV1} from "./interfaces/IFourDollarV1.sol";
import {ISimpleOracle} from "./interfaces/ISimpleOracle.sol";
import {IFourDollarNFT} from "./interfaces/IFourDollarNFT.sol";
import {FourDollarNFT} from "./FourDollarNFT.sol";
import {AggregatorV3Interface} from "./interfaces/AggregatorV3Interface.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract FourDollarV1 is IFourDollarV1, Initializable, OwnableUpgradeable, UUPSUpgradeable, ReentrancyGuard {
    error OnlyOwnerOfToken();
    error SoulBound();
    error OwnableTransferNotAllowed();

    uint256 public constant MAX_LEVEL_STEP = 10;
    uint256 public constant USD_DECIMALS = 8;
    uint256 public constant FOUR_DOLLAR_DENOMINATOR = 4 * 10 ** USD_DECIMALS;

    ISimpleOracle public oracle;
    IFourDollarNFT public nft;

    uint8[10] private _levels;
    string[10] private _uris;
    uint8 private _levelsLength;

    mapping(address donator => uint256 amount) private _donationAmountsInUSD;

    constructor() {
        _disableInitializers();
    }

    /*
    ==============================
    ||    Public functions      ||
    ==============================
    */

    function initialize(
        string memory _name,
        string memory _symbol,
        uint8[] memory levels_,
        string[] memory uris_,
        ISimpleOracle _oracle
    ) public initializer {
        __Ownable_init(msg.sender);
        __UUPSUpgradeable_init();

        uint256 levelsLength = levels_.length;
        uint256 urisLength = uris_.length;

        if (levelsLength == 0) {
            revert InvalidConstructorArguments("Levels must not be empty");
        }

        if (levelsLength != urisLength) {
            revert InvalidConstructorArguments("Levels and URIs must have the same length");
        }

        if (levelsLength > MAX_LEVEL_STEP) {
            revert InvalidConstructorArguments("Length of levels should be less than or equal to MAX_LEVEL_COUNT");
        }

        if (address(_oracle) == address(0)) {
            revert InvalidConstructorArguments("Oracle address must not be zero");
        }

        oracle = _oracle;
        _levelsLength = uint8(levelsLength);

        _levels[0] = levels_[0];
        _uris[0] = uris_[0];

        if (levelsLength > 1) {
            uint256 i = 1;
            for (i; i < levelsLength;) {
                if (levels_[i] <= levels_[i - 1]) {
                    revert InvalidConstructorArguments("Levels must be in ascending order");
                }

                _levels[i] = levels_[i];
                _uris[i] = uris_[i];
                unchecked {
                    i += 1;
                }
            }
        }

        nft = new FourDollarNFT(_name, _symbol);

        emit Initialize(msg.sender, levelsLength);
    }

    function version() external pure override returns (string memory) {
        return "v1";
    }

    function donationAmountInUSD(address _donator) external view override returns (uint256) {
        return _donationAmountsInUSD[_donator];
    }

    function currentLevel(uint256 tokenId_) external view override returns (uint8 level) {
        address owner = nft.ownerOf(tokenId_);
        level = _calculateLevel(owner);
    }

    function levelToTokenURI(uint8 _level) external view override returns (string memory) {
        if (_level >= _levelsLength) {
            return _uris[_levelsLength - 1];
        }

        return _uris[_level];
    }

    function levelToDonationCount(uint8 _level) external view override returns (uint256) {
        if (_level >= _levelsLength) {
            return _levels[_levelsLength - 1];
        }
        return _levels[_level];
    }

    function setTokenURI(uint256 tokenId_, uint8 _level) external {
        address owner = nft.ownerOf(tokenId_);
        if (owner != msg.sender) {
            revert OnlyOwnerOfToken();
        }

        if (_level >= _levelsLength) {
            _level = uint8(_levelsLength - 1);
        }

        if (_level > _calculateLevel(owner)) {
            revert LevelNotReached(_level);
        }

        nft.setTokenURI(tokenId_, _uris[_level]);
    }

    function calculateBaseAssetAmountInUSD(uint256 _amount) public view returns (uint256 amountInUSD) {
        (uint256 priceInUSD, uint8 decimals) = oracle.latestBaseAssetPrice();
        amountInUSD = ((_amount * priceInUSD / 10 ** 18) * 10 ** USD_DECIMALS) / 10 ** decimals;
    }

    function donate() external payable {
        _donate();
    }

    function withdraw(address _to, uint256 _amount) external override onlyOwner nonReentrant {
        if (_to == address(0)) {
            revert ZeroAddress();
        }

        if (address(this).balance < _amount) {
            revert InsufficientBalance();
        }

        payable(_to).transfer(_amount);

        emit Transfer(_to, _amount);
    }

    function call(address _to, uint256 _amount, bytes calldata _data)
        external
        override
        onlyOwner
        nonReentrant
        returns (bytes memory)
    {
        if (_to == address(0)) {
            revert ZeroAddress();
        }

        if (address(this).balance < _amount) {
            revert InsufficientBalance();
        }

        (bool success, bytes memory result) = _to.call{value: _amount}(_data);
        if (!success) {
            revert CallFailed();
        }

        emit Transfer(_to, _amount);

        return result;
    }

    /*
    ==============================
    ||    Internal functions    ||
    ==============================
    */
    function _calculateLevel(address _owner) internal view returns (uint8) {
        uint256 _amount = _donationAmountsInUSD[_owner];
        uint256 count = _amount / FOUR_DOLLAR_DENOMINATOR;

        uint8 i = 0;
        uint256 levelsLength = _levelsLength;

        for (i; i < levelsLength;) {
            if (count < _levels[i]) {
                break;
            }

            unchecked {
                i += 1;
            }
        }
        return i;
    }

    function _donate() internal {
        uint256 amount = msg.value;

        if (amount == 0) {
            revert ZeroAmount();
        }

        uint256 amountInUSD = calculateBaseAssetAmountInUSD(amount);

        uint256 donationAmountInUSDBefore = _donationAmountsInUSD[msg.sender];
        uint256 donationAmountInUSDAfter = donationAmountInUSDBefore + amountInUSD;

        _donationAmountsInUSD[msg.sender] = donationAmountInUSDAfter;

        uint256 donationCountBefore = donationAmountInUSDBefore / FOUR_DOLLAR_DENOMINATOR;
        uint256 donationCountAfter = donationAmountInUSDAfter / FOUR_DOLLAR_DENOMINATOR;

        if (donationCountBefore == 0 && donationCountAfter > 0) {
            _mint(msg.sender);
        }

        emit Donate(msg.sender, address(0), amount, amountInUSD);
    }

    function _mint(address _to) internal {
        string memory uri = _uris[0];
        nft.mint(_to, uri);
    }

    function _authorizeUpgrade(address) internal virtual override onlyOwner {}

    function _transferOwnership(address _newOwner) internal virtual override {
        if (owner() != address(0)) {
            revert OwnableTransferNotAllowed();
        }
        super._transferOwnership(_newOwner);
    }

    /*
    ==============================
    ||    Fallback functions    ||
    ==============================
    */

    receive() external payable {
        _donate();
    }

    fallback() external payable {
        _donate();
    }
}
