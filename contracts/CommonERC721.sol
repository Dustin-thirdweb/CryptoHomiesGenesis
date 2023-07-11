// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "./IERC2981.sol";

contract CommonERC721 is ERC721, Ownable, IERC2981 {
    uint16 internal tokenIdCount;

    uint16 internal currentStage = 0;
    bool public saleActive = false;

    uint256 public mintRate;
    uint16 public MAX_SUPPLY;

    string public baseURI =
        "ipfs://QmWiQE65tmpYzcokCheQmng2DCM33DEhjXcPB6PanwpAZo/";

    mapping(uint16 => mapping(address => bool)) mintedUsers;

    address public royaltyReceiver;
    uint256 public royalty;
    string public contractURI;

    constructor(
        string memory name,
        string memory symbol,
        uint16 maxSupply,
        uint256 _mintRate,
        string memory _contractURI
    ) ERC721(name, symbol) {
        MAX_SUPPLY = maxSupply;
        mintRate = _mintRate;
        royaltyReceiver = owner();
        royalty = 250;
        contractURI = _contractURI;
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(ERC721, IERC165) returns (bool) {
        return
            interfaceId == type(IERC2981).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function royaltyInfo(
        uint256,
        uint256 _salePrice
    ) external view virtual override returns (address, uint256) {
        uint256 royaltyAmount = (_salePrice * royalty) / 10000;

        return (royaltyReceiver, royaltyAmount);
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function totalSupply() public view returns (uint16) {
        return tokenIdCount;
    }

    function setMintRate(uint256 _mintRate) public onlyOwner {
        mintRate = _mintRate;
    }

    function setSaleActive(bool _saleActive) public onlyOwner {
        saleActive = _saleActive;
    }

    function resetMintedUsers() public onlyOwner {
        currentStage += 1;
    }

    function setRoyaltyReceiver(address royaltyReceiver_) public onlyOwner {
        royaltyReceiver = royaltyReceiver_;
    }

    function setRoyalty(uint256 _royalty) public onlyOwner {
        royalty = _royalty;
    }

    function setContractURI(string memory _contractURI) public onlyOwner {
        contractURI = _contractURI;
    }

    function changeBaseURI(string memory baseURI_) public onlyOwner {
        baseURI = baseURI_;
    }
}