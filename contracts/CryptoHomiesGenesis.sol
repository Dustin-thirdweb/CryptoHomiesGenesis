// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "./CommonERC721.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./CryptoHomiesCommon.sol";

contract CryptoHomiesGenesis is Ownable, CommonERC721, EIP712 {
    string private constant SIGNING_DOMAIN = "CryptoHomiesGenesis";
    string private constant SIGNATURE_VERSION = "1";

    bool public teamMinted;
    bool public allowlistOnly = false;
    address validSigner;

    struct Voucher {
        uint16 id;
        address recipient;
        bytes signature;
    }

    mapping(uint16 => bool) redeemedVouchers;

    CryptoHomiesCommon public commonContract;

    mapping(address => uint256) private withdrawalPercentages;
    address[] private withdrawalAddresses;

    constructor(
        string memory _contractURI,
        string memory _commonContractURI,
        address _validSigner
    )
        CommonERC721(
            "CryptoHomiesGenesis",
            "CHG",
            4848,
            0.1 ether,
            _contractURI
        )
        EIP712(SIGNING_DOMAIN, SIGNATURE_VERSION)
    {
        commonContract = new CryptoHomiesCommon(msg.sender, _commonContractURI);
        validSigner = _validSigner;
    }

    function redeem(Voucher calldata _voucher) public payable {
        address _redeemer = msg.sender;
        address _signer = _verify(_voucher);

        require(
            _signer != address(0),
            "Unable to recover signer from signature"
        );
        require(_signer == validSigner, "Invalid Voucher");
        require(
            _redeemer == _voucher.recipient,
            "This Voucher doesn't belong to you"
        );
        require(
            !redeemedVouchers[_voucher.id],
            "This Voucher was already redeemed"
        );
        _mint();
        redeemedVouchers[_voucher.id] = true;
    }

    function mint() public payable {
        require(!allowlistOnly, "Can only mint through allow list");
        _mint();
    }

    function _mint() internal {
        uint16 _tokenId = tokenIdCount + 1;
        require(saleActive, "Sale not active");
        require(_tokenId <= MAX_SUPPLY, "No more items left");
        require(msg.value >= mintRate, "Not enough ether sent");
        require(
            !mintedUsers[currentStage][msg.sender],
            "User has minted already"
        );

        _safeMint(msg.sender, _tokenId);
        commonContract.mintWithGenesis(msg.sender);

        tokenIdCount = _tokenId;
        mintedUsers[currentStage][msg.sender] = true;
    }

    function setAllowlistOnly(bool _allowlistOnly) public onlyOwner {
        allowlistOnly = _allowlistOnly;
    }

    function setValidSigner(address _validSigner) public onlyOwner {
        validSigner = _validSigner;
    }

    // Whitelist help functions

    function _hash(Voucher calldata pass) internal view returns (bytes32) {
        return
            _hashTypedDataV4(
                keccak256(
                    abi.encode(
                        keccak256("Voucher(uint16 id,address recipient)"),
                        pass.id,
                        pass.recipient
                    )
                )
            );
    }

    function _verify(Voucher calldata pass) internal view returns (address) {
        bytes32 digest = _hash(pass);
        return ECDSA.recover(digest, pass.signature);
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(owner()).transfer(balance);
    }
}
