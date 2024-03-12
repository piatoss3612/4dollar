// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {IFourDollar} from "./interfaces/IFourDollar.sol";
import {ISimpleOracle} from "./interfaces/ISimpleOracle.sol";
import {AggregatorV3Interface} from "./interfaces/AggregatorV3Interface.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {ERC721URIStorage} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract FourDollar is IFourDollar, ERC721, ERC721URIStorage, Ownable, ReentrancyGuard {
    error OnlyOwnerOfToken();
    error SoulBound();
    error OwnableTransferNotAllowed();

    uint256 public constant MAX_LEVEL_STEP = 10;
    uint256 public constant USD_DECIMALS = 8;
    uint256 public constant FOUR_DOLLAR_DENOMINATOR = 4 * 10 ** USD_DECIMALS;

    ISimpleOracle public immutable oracle;

    uint8[] private _levels;
    string[] private _uris;

    mapping(address donator => uint256 amount) private _donationAmountsInUSD;
    uint256 private _tokenId;

    constructor(
        string memory _name,
        string memory _symbol,
        uint8[] memory levels_,
        string[] memory uris_,
        ISimpleOracle _oracle
    ) ERC721(_name, _symbol) Ownable(msg.sender) {
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

        _levels.push(levels_[0]);
        _uris.push(uris_[0]);

        if (levelsLength == 1) {
            emit Creation(msg.sender, levelsLength);
            return;
        }

        uint256 i = 1;
        for (i; i < levelsLength;) {
            if (levels_[i] <= levels_[i - 1]) {
                revert InvalidConstructorArguments("Levels must be in ascending order");
            }

            _levels.push(levels_[i]);
            _uris.push(uris_[i]);
            unchecked {
                i += 1;
            }
        }

        emit Creation(msg.sender, levelsLength);
    }

    /*
    ==============================
    ||    Public functions      ||
    ==============================
    */

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721, ERC721URIStorage)
        returns (bool)
    {
        return interfaceId == type(IFourDollar).interfaceId || super.supportsInterface(interfaceId);
    }

    function tokenURI(uint256 tokenId) public view virtual override(ERC721, ERC721URIStorage) returns (string memory) {
        return super.tokenURI(tokenId);
    }

    function donationAmountInUSD(address _donator) external view override returns (uint256) {
        return _donationAmountsInUSD[_donator];
    }

    function currentLevel(uint256 tokenId_) external view override returns (uint8 level) {
        address owner = ownerOf(tokenId_);
        level = _calculateLevel(owner);
    }

    function levelToTokenURI(uint8 _level) external view override returns (string memory) {
        if (_level >= _levels.length) {
            return _uris[_levels.length - 1];
        }

        return _uris[_level];
    }

    function levelToDonationCount(uint8 _level) external view override returns (uint256) {
        if (_level >= _levels.length) {
            return _levels[_levels.length - 1];
        }
        return _levels[_level];
    }

    function setTokenURI(uint256 tokenId_, uint8 _level) external {
        address owner = ownerOf(tokenId_);
        if (owner != msg.sender) {
            revert OnlyOwnerOfToken();
        }

        if (_level >= _levels.length) {
            _level = uint8(_levels.length - 1);
        }

        if (_level > _calculateLevel(owner)) {
            revert LevelNotReached(_level);
        }

        _setTokenURI(tokenId_, _uris[_level]);
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
        return result;
    }

    /*
    ==============================
    ||   SoulBound functions    ||
    ==============================
    */

    function transferFrom(address, address, uint256) public override(IERC721, ERC721) {
        revert SoulBound();
    }

    function safeTransferFrom(address, address, uint256, bytes memory) public override(IERC721, ERC721) {
        revert SoulBound();
    }

    function approve(address, uint256) public override(IERC721, ERC721) {
        revert SoulBound();
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
        uint256 levelsLength = _levels.length;

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

        emit Donation(msg.sender, address(0), amount);
    }

    function _mint(address to) internal virtual {
        uint256 tokenId_ = _tokenId++;
        _mint(to, tokenId_);
        _setTokenURI(tokenId_, _uris[0]);
    }

    function _transferOwnership(address) internal virtual override(Ownable) {
        revert OwnableTransferNotAllowed();
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
