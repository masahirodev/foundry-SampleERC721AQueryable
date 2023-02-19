// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "erc721a/contracts/extensions/ERC721AQueryable.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "operator-filter-registry/DefaultOperatorFilterer.sol";

import "./SaleInfoData.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract SampleERC721AQueryable is Ownable, ERC721AQueryable, ERC2981, DefaultOperatorFilterer, SaleInfoData {
    using Strings for uint256;

    uint256 private constant FALSE = 1;
    uint256 private constant TRUE = 2;
    uint256 private constant MAX_PER_TX = 10;
    uint256 private MAX_SUPPLY;

    uint8 private salePhase;

    uint256 private isRevealed = FALSE;
    string private unRevealedURI;
    string private baseURI;
    string private baseExtension;

    /*//////////////////////////////////////////////////////////////////////////////////////////////////
                                                CONSTRUCTOR
    //////////////////////////////////////////////////////////////////////////////////////////////////*/

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _unRevealedURI,
        string memory baseURI_,
        string memory _baseExtension,
        uint96 _royaltyFee,
        uint256 _maxSupply,
        address[] memory constructorMintTos,
        uint256[] memory constructorMintQuantities
    ) ERC721A(_name, _symbol) {
        MAX_SUPPLY = _maxSupply;
        unRevealedURI = _unRevealedURI;
        baseURI = baseURI_;
        baseExtension = _baseExtension;
        _setDefaultRoyalty(msg.sender, _royaltyFee);

        // constructor mint
        if (constructorMintTos.length != 0 && constructorMintTos.length == constructorMintQuantities.length) {
            for (uint256 i = 0; i < constructorMintTos.length;) {
                _mintERC2309(constructorMintTos[i], constructorMintQuantities[i]);
                unchecked {
                    i++;
                }
            }
        }
    }

    /*//////////////////////////////////////////////////////////////////////////////////////////////////
                                                  MODIFIER
    //////////////////////////////////////////////////////////////////////////////////////////////////*/

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    /*//////////////////////////////////////////////////////////////////////////////////////////////////
                                                    SALE
    //////////////////////////////////////////////////////////////////////////////////////////////////*/

    function setSalePhase(uint8 _newSalePhase) external onlyOwner {
        salePhase = _newSalePhase;
    }

    /*//////////////////////////////////////////////////////////////////////////////////////////////////
                                                    MINT
    //////////////////////////////////////////////////////////////////////////////////////////////////*/

    function mint(uint16 _mintAmount, uint16 _maxMintAmount, bytes32[] calldata _merkleProof)
        public
        payable
        callerIsUser
    {
        if (SaleInfos[salePhase].merkleRoot != 0x00) {
            checkMerkleProof(_maxMintAmount, _merkleProof);
        }
        checkMint(_mintAmount, _maxMintAmount);

        // mintChecker[mintCheckerKey] += _mintAmount;
        _safeMint(msg.sender, _mintAmount);
    }

    function checkMint(uint16 _mintAmount, uint16 _maxMintAmount) internal {
        uint256 maxSupply = Math.min(MAX_SUPPLY, SaleInfos[salePhase].maxSupply);

        //safeMath for testing
        uint256 cost = SafeMath.mul(SaleInfos[salePhase].cost, _mintAmount);

        require(salePhase != 0, "Not sale");
        require(_mintAmount > 0, "Not 0 mint");
        require(msg.value >= cost, "Not enough");
        require(_mintAmount < MAX_PER_TX + 1, "Exceeds the volume");
        require(totalSupply() + _mintAmount < maxSupply + 1, "Sold out");

        uint256 _mintedInfo = ERC721A._getAux(msg.sender);

        uint256 _mintedAmount = _mintedInfo & ((1 << 16) - 1);
        if (_mintedInfo >> 16 & (1 << 8) - 1 == salePhase) {
            require(_mintedAmount + _mintAmount < _maxMintAmount + 1, "Over the limit");
        }
        uint256 newMintedInfo = (uint256(salePhase) << 16) | (_mintAmount + _mintedAmount);

        ERC721A._setAux(msg.sender, uint64(newMintedInfo));
    }

    function checkMerkleProof(uint256 _maxMintAmount, bytes32[] calldata _merkleProof) internal view {
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender, _maxMintAmount));
        require(MerkleProof.verify(_merkleProof, SaleInfos[salePhase].merkleRoot, leaf), "Invalid Merkle Proof");
    }

    function ownerMint(address _address, uint256 _mintAmount) external onlyOwner {
        require(totalSupply() + _mintAmount < MAX_SUPPLY + 1, "Exceeds the volume");
        _safeMint(_address, _mintAmount);
    }

    /*//////////////////////////////////////////////////////////////////////////////////////////////////
                                                TOKEN COUNTING
    //////////////////////////////////////////////////////////////////////////////////////////////////*/

    function _startTokenId() internal pure override returns (uint256) {
        return 1300;
    }

    function setBaseURI(string memory _newBaseURI) external onlyOwner {
        baseURI = _newBaseURI;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function setRevealed() external onlyOwner {
        isRevealed = TRUE;
    }

    function tokenURI(uint256 _tokenId) public view override(ERC721A, IERC721A) returns (string memory) {
        require(_exists(_tokenId), "Not exist token");

        if (isRevealed == FALSE) {
            return unRevealedURI;
        }

        return string(abi.encodePacked(ERC721A.tokenURI(_tokenId), baseExtension));
    }

    /*//////////////////////////////////////////////////////////////////////////////////////////////////
                                                    OTHER
    //////////////////////////////////////////////////////////////////////////////////////////////////*/

    function setDefaultRoyalty(address _royaltyAddress, uint96 _royaltyFee) external onlyOwner {
        _setDefaultRoyalty(_royaltyAddress, _royaltyFee);
    }

    function withdraw() external onlyOwner {
        require(payable(msg.sender).send(address(this).balance));
    }

    /*//////////////////////////////////////////////////////////////////////////////////////////////////
                                    OpenSea operator-filter-registry
    //////////////////////////////////////////////////////////////////////////////////////////////////*/

    function setApprovalForAll(address operator, bool approved)
        public
        override(ERC721A, IERC721A)
        onlyAllowedOperatorApproval(operator)
    {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId)
        public
        payable
        override(ERC721A, IERC721A)
        onlyAllowedOperatorApproval(operator)
    {
        super.approve(operator, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId)
        public
        payable
        override(ERC721A, IERC721A)
        onlyAllowedOperator(from)
    {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId)
        public
        payable
        override(ERC721A, IERC721A)
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        payable
        override(ERC721A, IERC721A)
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    /*//////////////////////////////////////////////////////////////////////////////////////////////////
                                                IERC165
    //////////////////////////////////////////////////////////////////////////////////////////////////*/

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC2981, ERC721A, IERC721A)
        returns (bool)
    {
        return ERC721A.supportsInterface(interfaceId) || ERC2981.supportsInterface(interfaceId);
    }
}
