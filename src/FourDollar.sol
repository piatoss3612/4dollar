// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {IFourDollar} from "./interfaces/IFourDollar.sol";
import {AggregatorV3Interface} from "./interfaces/AggregatorV3Interface.sol";
import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {ERC721URIStorage} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract FourDollar is IFourDollar, ERC721, ERC721URIStorage, Ownable {
    uint256 public constant MAX_LEVEL_STEP = 10;
    uint256 public constant USD_DECIMALS = 6;
    uint256 public constant FOUR_DOLLAR_DENOMINATOR = 4 * 10 ** USD_DECIMALS;

    uint8[] private _levels;
    string[] private _uris;

    mapping(address donator => uint256 donationCount) private _donationAmounts;
    uint256 private _tokenId;

    constructor(string memory _name, string memory _symbol, uint8[] memory levels_, string[] memory uris_)
        ERC721(_name, _symbol)
        Ownable(msg.sender)
    {
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

    function donationAmount(address _donator) external view override returns (uint256) {
        return _donationAmounts[_donator];
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

    function donate() external payable {
        // TODO: Implement this function
    }

    function _calculateLevel(address _owner) internal view returns (uint8) {
        uint256 _amount = _donationAmounts[_owner];
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

    receive() external payable {
        // TODO: Implement this function
    }

    fallback() external payable {
        // TODO: Implement this function
    }
}
