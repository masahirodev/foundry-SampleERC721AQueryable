// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import "forge-std/Test.sol";
import "contracts/SampleERC721AQueryable.sol";

import {TestHelpers} from "./TestHelpers.t.sol";
import {InternalFunction} from "./InternalFunction.t.sol";
import {ConstructorDatas} from "./ConstructorDatas.t.sol";

import "@openzeppelin/contracts/utils/Strings.sol";

//forge test --match-contract SampleERC721AQueryable --match-test testSetSalePhase
//forge inspect SampleERC721AQueryable storage-layout --pretty

contract SampleERC721AQueryableTest is Test, TestHelpers, InternalFunction, ConstructorDatas {
    using stdStorage for StdStorage;

    SampleERC721AQueryable public token;

    function setUp() public onlyOwner {
        if (isConstructorMint) {
            token = new SampleERC721AQueryable(_name,_symbol,_unRevealedURI,baseURI_,
            _baseExtension,_royaltyFee,MAX_SUPPLY,constructorMintTos,constructorMintQuantities);
        } else {
            token = new SampleERC721AQueryable(_name,_symbol,_unRevealedURI,baseURI_,_baseExtension,
            _royaltyFee,MAX_SUPPLY,noConstructorMintTos,noConstructorMintQuantities);
        }
    }

    /*//////////////////////////////////////////////////////////////////////////////////////////////////
                                              constructorMint
    //////////////////////////////////////////////////////////////////////////////////////////////////*/

    function testConstructorMint() public {
        if (isConstructorMint) {
            for (uint256 i = 0; i < constructorMintQuantities.length;) {
                assertEq(token.balanceOf(constructorMintTos[i]), constructorMintQuantities[i]);
                unchecked {
                    i++;
                }
            }
        }
    }

    /*//////////////////////////////////////////////////////////////////////////////////////////////////
                                                  METADATA
    //////////////////////////////////////////////////////////////////////////////////////////////////*/

    function testCheckMetaData() public {
        assertEq(token.name(), _name);
        assertEq(token.symbol(), _symbol);
        assertEq(token.owner(), owner);
    }

    /*//////////////////////////////////////////////////////////////////////////////////////////////////
                                                  MODIFIER
    //////////////////////////////////////////////////////////////////////////////////////////////////*/

    function testCallerIsUser(uint16 _mintAmount, uint16 _maxMintAmount, bytes32[] calldata _merkleProof)
        public
        anotherContract
    {
        vm.expectRevert(bytes("The caller is another contract"));
        token.mint(_mintAmount, _maxMintAmount, _merkleProof);
    }

    function testOnlyOwner(
        uint8 _newSalePhase,
        address _address,
        uint256 _mintAmount,
        string memory _newBaseURI,
        address _royaltyAddress,
        uint96 royaltyFee_
    ) public nonOwner {
        vm.expectRevert(bytes("Ownable: caller is not the owner"));
        token.setSalePhase(_newSalePhase);

        vm.expectRevert(bytes("Ownable: caller is not the owner"));
        token.ownerMint(_address, _mintAmount);

        vm.expectRevert(bytes("Ownable: caller is not the owner"));
        token.setBaseURI(_newBaseURI);

        vm.expectRevert(bytes("Ownable: caller is not the owner"));
        token.setRevealed();

        vm.expectRevert(bytes("Ownable: caller is not the owner"));
        token.setDefaultRoyalty(_royaltyAddress, royaltyFee_);

        vm.expectRevert(bytes("Ownable: caller is not the owner"));
        token.withdraw();
    }

    /*//////////////////////////////////////////////////////////////////////////////////////////////////
                                                    SALE
    //////////////////////////////////////////////////////////////////////////////////////////////////*/

    function testSetSalePhase(uint8 _newSalePhase) public onlyOwner {
        token.setSalePhase(_newSalePhase);
        bytes32 data = vm.load(address(token), bytes32(uint256(13)));
        assertEq(uint256(data), _newSalePhase);
    }

    function testSetSaleInfo(uint8 salePhase, bytes32 merkleRoot, uint16 maxPhaseSupply, uint64 cost)
        public
        onlyOwner
    {
        token.setSaleInfo(salePhase, merkleRoot, maxPhaseSupply, cost);
        (bytes32 _merkleRoot, uint16 _maxPhaseSupply, uint64 _cost) = token.getSaleInfo(salePhase);
        assertEq(merkleRoot, _merkleRoot);
        assertEq(maxPhaseSupply, _maxPhaseSupply);
        assertEq(cost, _cost);
    }

    /*//////////////////////////////////////////////////////////////////////////////////////////////////
                                                    MINT
    //////////////////////////////////////////////////////////////////////////////////////////////////*/

    //not merkleProof
    function testNotAllowMint(
        uint16 _mintAmount,
        uint16 _maxMintAmount,
        bytes32[] calldata _merkleProof,
        address user1,
        address user2
    ) public {
        vm.assume(user1 != address(0) && user2 != address(0) && user1 != user2);

        //Check Not Sale
        vm.startPrank(user1, user1);
        vm.expectRevert(bytes("Not sale"));
        token.mint(_mintAmount, _maxMintAmount, _merkleProof);
        vm.stopPrank();

        //SaleInfo setup
        vm.startPrank(owner);
        uint8 salePhase = 1;
        bytes32 merkleRoot = 0x00;
        uint16 maxPhaseSupply = 500;
        uint64 cost = 0.001 ether;
        token.setSaleInfo(salePhase, merkleRoot, maxPhaseSupply, cost);
        token.setSalePhase(salePhase);
        vm.stopPrank();

        //handler setup
        vm.startPrank(user1, user1);
        vm.deal(user1, 100 ether);

        //Check Not 0 mint
        vm.expectRevert(bytes("Not 0 mint"));
        token.mint(0, _maxMintAmount, _merkleProof);

        //Check Not enough
        vm.assume(0 < _mintAmount);
        vm.expectRevert(bytes("Not enough"));
        token.mint(_mintAmount, _maxMintAmount, _merkleProof);

        //Check Exceeds the volume
        vm.assume(10 < _mintAmount && _mintAmount < 20);
        vm.expectRevert(bytes("Exceeds the volume"));
        token.mint{value: cost * _mintAmount}(_mintAmount, _maxMintAmount, _merkleProof);

        //Set totalSupply
        uint256 maxSupply = Math.min(MAX_SUPPLY, maxPhaseSupply);
        // set _currentIndex
        vm.store(address(token), bytes32(uint256(0)), bytes32(uint256(START_TOKENID + maxSupply)));
        assertEq(token.totalSupply(), maxSupply);

        //Check Sold out
        vm.expectRevert(bytes("Sold out"));
        _mintAmount = 10;
        token.mint{value: cost * _mintAmount}(_mintAmount, _maxMintAmount, _merkleProof);

        //Reset _currentIndex
        vm.store(address(token), bytes32(uint256(0)), bytes32(uint256(START_TOKENID)));

        //Set mintedAmount
        _maxMintAmount = 15;
        token.mint{value: cost * _mintAmount}(_mintAmount, _maxMintAmount, _merkleProof);
        assertEq(token.totalSupply(), _mintAmount);

        //Check Over the limit
        vm.expectRevert(bytes("Over the limit"));
        token.mint{value: cost * _mintAmount}(_mintAmount, _maxMintAmount, _merkleProof);

        assertEq(token.totalSupply(), _mintAmount);
        vm.stopPrank();

        //SaleInfo setup
        vm.startPrank(owner);
        merkleRoot = 0x0000000000000000000000000000000000000000000000000000000000000001;
        token.setSaleInfo(salePhase, merkleRoot, maxPhaseSupply, cost);
        vm.stopPrank();

        //Check Over the limit
        vm.startPrank(user2, user2);
        vm.deal(user2, 100 ether);

        vm.expectRevert(bytes("Invalid Merkle Proof"));
        token.mint{value: cost * _mintAmount}(_mintAmount, _maxMintAmount, _merkleProof);
    }

    function testOwnerMint(address _address, uint256 _mintAmount) public onlyOwner {
        vm.assume(_address != address(0) && 0 < _mintAmount && _mintAmount < MAX_SUPPLY);

        //Set totalSupply
        uint256 maxSupply = MAX_SUPPLY; //MAX_SUPPLY
        vm.store(address(token), bytes32(uint256(0)), bytes32(uint256(START_TOKENID + maxSupply)));
        assertEq(token.totalSupply(), maxSupply);

        //Check Exceeds the volume
        vm.expectRevert(bytes("Exceeds the volume"));
        token.ownerMint(_address, _mintAmount);

        // owner mint check
        //Set totalSupply
        vm.store(address(token), bytes32(uint256(0)), bytes32(uint256(START_TOKENID)));
        token.ownerMint(_address, _mintAmount);
        assertEq(token.balanceOf(_address), _mintAmount);
    }

    /*//////////////////////////////////////////////////////////////////////////////////////////////////
                                                TOKEN COUNTING
    //////////////////////////////////////////////////////////////////////////////////////////////////*/

    function testStartTokenId(address user, uint256 amount) public onlyOwner {
        uint256 constructorMintAmount = getConstructorMintAmount();

        vm.assume(user != zeroAddress);
        vm.assume(0 < amount && amount < 10);

        uint256 _currentIndex = uint256(vm.load(address(token), bytes32(uint256(0))));
        assertEq(START_TOKENID + constructorMintAmount, _currentIndex);

        token.ownerMint(user, amount);
        assertEq(token.totalSupply(), amount + constructorMintAmount);
        assertEq(token.ownerOf(START_TOKENID + constructorMintAmount + amount - 1), user);
    }

    /*//////////////////////////////////////////////////////////////////////////////////////////////////
                                                  tokenURI
    //////////////////////////////////////////////////////////////////////////////////////////////////*/

    function testNotExistTokenURI(uint256 amount, address user) public onlyOwner {
        uint256 constructorMintAmount = getConstructorMintAmount();

        vm.expectRevert(bytes("Not exist token"));
        token.tokenURI(START_TOKENID + constructorMintAmount);

        vm.assume(user != zeroAddress);
        vm.assume(0 < amount && amount <= MAX_SUPPLY);
        token.ownerMint(user, amount);

        vm.expectRevert(bytes("Not exist token"));
        token.tokenURI(START_TOKENID + constructorMintAmount + amount);
    }

    function testTokenURI(string memory _newBaseURI, uint256 amount, uint256 tokenId, address user) public onlyOwner {
        vm.assume(keccak256(bytes(_newBaseURI)) != keccak256(bytes("")));
        vm.assume(START_TOKENID <= tokenId && tokenId - START_TOKENID < amount && amount <= MAX_SUPPLY);
        vm.assume(user != zeroAddress);

        token.setBaseURI(_newBaseURI);
        token.setRevealed();

        token.ownerMint(user, amount);

        string memory newTokenUri = string(abi.encodePacked(_newBaseURI, _toString(tokenId), _baseExtension));
        string memory tokenUri = token.tokenURI(tokenId);

        assertEq(newTokenUri, tokenUri);
    }

    function testCheckUnRevealedURI(uint256 amount, uint256 tokenId, address user) public onlyOwner {
        vm.assume(user != zeroAddress);
        vm.assume(START_TOKENID <= tokenId && tokenId - START_TOKENID < amount && amount <= MAX_SUPPLY);
        token.ownerMint(user, amount);

        assertEq(token.tokenURI(tokenId), _unRevealedURI);
    }

    /*//////////////////////////////////////////////////////////////////////////////////////////////////
                                                setRevealed
    //////////////////////////////////////////////////////////////////////////////////////////////////*/

    function testSetRevealed() public onlyOwner {
        bytes32 result = vm.load(address(token), bytes32(uint256(14)));
        assertEq(uint256(result), 1);

        token.setRevealed();
        bytes32 newResult = vm.load(address(token), bytes32(uint256(14)));
        assertEq(uint256(newResult), 2);
    }

    /*//////////////////////////////////////////////////////////////////////////////////////////////////
                                                    OTHER
    //////////////////////////////////////////////////////////////////////////////////////////////////*/

    /*//////////////////////////////////////////////////////////////////////////////////////////////////
                                                setDefaultRoyalty
    //////////////////////////////////////////////////////////////////////////////////////////////////*/

    function testSetDefaultRoyalty(address _royaltyAddress, uint96 royaltyFee_, uint256 tokenId, uint256 salePrice)
        external
        onlyOwner
    {
        vm.assume(_royaltyAddress != zeroAddress && 0 < royaltyFee_ && royaltyFee_ < 10_000);
        vm.assume(tokenId < 100 && salePrice < 10_000);
        token.setDefaultRoyalty(_royaltyAddress, royaltyFee_);

        (address receiver, uint256 royaltyAmount) = token.royaltyInfo(tokenId, salePrice);

        assertEq(receiver, _royaltyAddress);
        assertEq(royaltyAmount, (salePrice * royaltyFee_) / 10_000);
    }

    function testNotSetDefaultRoyalty(address _royaltyAddress, uint96 royaltyFee_, uint256 tokenId, uint256 salePrice)
        external
        onlyOwner
    {
        vm.assume(_royaltyAddress != zeroAddress && 10_000 < royaltyFee_);
        vm.assume(tokenId < 100 && salePrice < 10_000);

        vm.expectRevert(bytes("ERC2981: royalty fee will exceed salePrice"));
        token.setDefaultRoyalty(_royaltyAddress, royaltyFee_);

        vm.expectRevert(bytes("ERC2981: invalid receiver"));
        token.setDefaultRoyalty(zeroAddress, 9_000);
    }

    /*//////////////////////////////////////////////////////////////////////////////////////////////////
                                                withdraw
    //////////////////////////////////////////////////////////////////////////////////////////////////*/

    function testWithdraw(uint96 amount) external onlyOwner {
        uint256 beforeBalance = address(owner).balance;

        vm.assume(amount < 100 ether);
        deal(address(token), amount);
        token.withdraw();

        uint256 afterBalance = address(owner).balance;

        assertEq(beforeBalance + amount, afterBalance);
        assertEq(address(token).balance, 0);
    }

    /*//////////////////////////////////////////////////////////////////////////////////////////////////
                                                IERC165
    //////////////////////////////////////////////////////////////////////////////////////////////////*/

    function testSupportsInterface() public {
        assertTrue(token.supportsInterface(type(IERC165).interfaceId));
        assertTrue(token.supportsInterface(type(IERC2981).interfaceId));
        // ERC721A - IERC721
        assertTrue(token.supportsInterface(0x80ac58cd));
        // ERC721A - ERC721Metadata
        assertTrue(token.supportsInterface(0x5b5e139f));
    }

    /*//////////////////////////////////////////////////////////////////////////////////////////////////
                                      inheritance contract methods
    //////////////////////////////////////////////////////////////////////////////////////////////////*/

    /*//////////////////////////////////////////////////////////////////////////////////////////////////
                                              write contract
    //////////////////////////////////////////////////////////////////////////////////////////////////*/

    function testApprove(
        address operator,
        // uint256 tokenId,
        uint16 _mintAmount1,
        bytes32[] calldata _merkleProof,
        address user1,
        address user2
    ) public {
        vm.assume(user1 != address(0) && user2 != address(0) && user1 != user2);
        vm.assume(0 < _mintAmount1 && _mintAmount1 < 10);
        // vm.assume(START_TOKENID <= tokenId && tokenId < START_TOKENID + _mintAmount1);

        uint256 constructorMintAmount = getConstructorMintAmount();
        uint256 tokenId = START_TOKENID + constructorMintAmount + _mintAmount1 - 1;

        setMint(_mintAmount1, _merkleProof, user1);

        assertEq(token.getApproved(tokenId), zeroAddress);

        vm.startPrank(user1, user1);
        token.approve(operator, tokenId);
        vm.stopPrank();

        vm.startPrank(user2, user2);
        vm.expectRevert();
        token.approve(operator, tokenId);
        vm.stopPrank();

        assertEq(token.getApproved(tokenId), operator);
    }

    function testRenounce() public {
        vm.startPrank(user1);
        vm.expectRevert();
        token.renounceOwnership();
        vm.stopPrank();

        vm.startPrank(owner);
        token.renounceOwnership();
        assertEq(token.owner(), zeroAddress);
        vm.stopPrank();
    }

    function testSafeTransferFrom(
        // uint256 tokenId,
        uint16 _mintAmount1,
        bytes32[] calldata _merkleProof,
        address user1,
        address user2
    ) public {
        vm.assume(user1 != address(0) && user2 != address(0) && user1 != user2);
        vm.assume(0 < _mintAmount1 && _mintAmount1 < 10);
        // vm.assume(START_TOKENID <= tokenId && tokenId < START_TOKENID + _mintAmount1);

        uint256 constructorMintAmount = getConstructorMintAmount();
        uint256 tokenId = START_TOKENID + constructorMintAmount + _mintAmount1 - 1;

        setMint(_mintAmount1, _merkleProof, user1);
        assertEq(token.ownerOf(tokenId), user1);

        // not token owner
        vm.startPrank(user2);
        vm.expectRevert();
        token.safeTransferFrom(user1, user2, tokenId);
        vm.stopPrank();

        vm.startPrank(user1);
        token.safeTransferFrom(user1, user2, tokenId);
        assertEq(token.ownerOf(tokenId), user2);
        vm.stopPrank();
    }

    function testOperaterSafeTransferFrom(
        address operator,
        // uint256 tokenId,
        uint16 _mintAmount1,
        bytes32[] calldata _merkleProof,
        address user1,
        address user2
    ) public {
        vm.assume(user1 != address(0) && user2 != address(0) && user1 != user2);
        vm.assume(operator != zeroAddress);
        vm.assume(0 < _mintAmount1 && _mintAmount1 < 10);
        // vm.assume(START_TOKENID <= tokenId && tokenId < START_TOKENID + _mintAmount1);

        uint256 constructorMintAmount = getConstructorMintAmount();
        uint256 tokenId = START_TOKENID + constructorMintAmount + _mintAmount1 - 1;

        setMint(_mintAmount1, _merkleProof, user1);
        assertEq(token.ownerOf(tokenId), user1);

        // set operator
        vm.startPrank(user1);
        token.approve(operator, tokenId);
        vm.stopPrank();

        vm.startPrank(operator);
        token.safeTransferFrom(user1, user2, tokenId);
        assertEq(token.ownerOf(tokenId), user2);
        vm.stopPrank();
    }

    function testSetApprovalForAll(
        address operator,
        // uint256 tokenId,
        uint16 _mintAmount1,
        bytes32[] calldata _merkleProof,
        address user1,
        address user2
    ) public {
        vm.assume(user1 != address(0) && user2 != address(0) && user1 != user2);
        vm.assume(operator != zeroAddress);
        vm.assume(0 < _mintAmount1 && _mintAmount1 < 10);
        // vm.assume(START_TOKENID <= tokenId && tokenId < START_TOKENID + _mintAmount1);

        uint256 constructorMintAmount = getConstructorMintAmount();
        uint256 tokenId = START_TOKENID + constructorMintAmount + _mintAmount1 - 1;

        setMint(_mintAmount1, _merkleProof, user1);
        assertEq(token.ownerOf(tokenId), user1);
        assertEq(token.isApprovedForAll(user1, operator), false);

        // set operator
        vm.startPrank(user1);
        token.setApprovalForAll(operator, true);
        assertEq(token.isApprovedForAll(user1, operator), true);
        vm.stopPrank();

        vm.startPrank(operator);
        token.transferFrom(user1, user2, tokenId);
        assertEq(token.ownerOf(tokenId), user2);
        vm.stopPrank();
    }

    function testCancelSetApprovalForAll(
        address operator,
        // uint256 tokenId,
        uint16 _mintAmount1,
        bytes32[] calldata _merkleProof,
        address user1,
        address user2
    ) public {
        vm.assume(user1 != address(0) && user2 != address(0) && user1 != user2);
        vm.assume(operator != zeroAddress);
        vm.assume(0 < _mintAmount1 && _mintAmount1 < 10);
        // vm.assume(START_TOKENID <= tokenId && tokenId < START_TOKENID + _mintAmount1);

        uint256 constructorMintAmount = getConstructorMintAmount();
        uint256 tokenId = START_TOKENID + constructorMintAmount + _mintAmount1 - 1;

        setMint(_mintAmount1, _merkleProof, user1);
        assertEq(token.ownerOf(tokenId), user1);

        // set operator
        vm.startPrank(user1);
        token.setApprovalForAll(operator, true);
        token.setApprovalForAll(operator, false);
        vm.stopPrank();

        vm.startPrank(operator);
        vm.expectRevert();
        token.transferFrom(user1, user2, tokenId);
        vm.stopPrank();
    }

    function testTransferFrom(
        // uint256 tokenId,
        uint16 _mintAmount1,
        bytes32[] calldata _merkleProof,
        address user1,
        address user2
    ) public {
        vm.assume(user1 != address(0) && user2 != address(0) && user1 != user2);
        vm.assume(0 < _mintAmount1 && _mintAmount1 < 10);
        // vm.assume(START_TOKENID <= tokenId && tokenId < START_TOKENID + _mintAmount1);

        uint256 constructorMintAmount = getConstructorMintAmount();
        uint256 tokenId = START_TOKENID + constructorMintAmount + _mintAmount1 - 1;

        setMint(_mintAmount1, _merkleProof, user1);
        assertEq(token.ownerOf(tokenId), user1);

        // not token owner
        vm.startPrank(user2);
        vm.expectRevert();
        token.transferFrom(user1, user2, tokenId);
        vm.stopPrank();

        vm.startPrank(user1);
        token.transferFrom(user1, user2, tokenId);
        assertEq(token.ownerOf(tokenId), user2);
        vm.stopPrank();
    }

    function testOperaterTransferFrom(
        address operator,
        // uint256 tokenId,
        uint16 _mintAmount1,
        bytes32[] calldata _merkleProof,
        address user1,
        address user2
    ) public {
        vm.assume(user1 != address(0) && user2 != address(0) && user1 != user2);
        vm.assume(operator != zeroAddress);
        vm.assume(0 < _mintAmount1 && _mintAmount1 < 10);
        // vm.assume(START_TOKENID <= tokenId && tokenId < START_TOKENID + _mintAmount1);

        uint256 constructorMintAmount = getConstructorMintAmount();
        uint256 tokenId = START_TOKENID + constructorMintAmount + _mintAmount1 - 1;

        setMint(_mintAmount1, _merkleProof, user1);
        assertEq(token.ownerOf(tokenId), user1);

        // set operator
        vm.startPrank(user1);
        token.approve(operator, tokenId);
        vm.stopPrank();

        vm.startPrank(operator);
        token.transferFrom(user1, user2, tokenId);
        assertEq(token.ownerOf(tokenId), user2);
        vm.stopPrank();
    }

    function testTransferOwnership(address newOwner) public {
        vm.assume(newOwner != zeroAddress);
        assertEq(token.owner(), owner);

        vm.expectRevert(bytes("Ownable: caller is not the owner"));
        token.transferOwnership(newOwner);

        vm.startPrank(owner);
        token.transferOwnership(newOwner);
        assertEq(token.owner(), newOwner);
        vm.stopPrank();
    }

    /*//////////////////////////////////////////////////////////////////////////////////////////////////
                                              read contract
    //////////////////////////////////////////////////////////////////////////////////////////////////*/

    function testBalanceOf(uint16 _mintAmount1, bytes32[] calldata _merkleProof, address user) public {
        vm.assume(user != address(0));
        vm.assume(
            user != makeAddr("constructor1") && user != makeAddr("constructor2") && user != makeAddr("constructor3")
        );
        vm.assume(0 < _mintAmount1 && _mintAmount1 < 10);

        setMint(_mintAmount1, _merkleProof, user);
        assertEq(token.balanceOf(user), _mintAmount1);
    }

    function testExplicitOwnershipOf(
        uint16 _mintAmount1,
        uint16 _mintAmount2,
        bytes32[] calldata _merkleProof,
        address user1,
        address user2
    ) public {
        vm.assume(user1 != address(0) && user2 != address(0) && user1 != user2);
        vm.assume(0 < _mintAmount1 && _mintAmount1 < 10);
        vm.assume(0 < _mintAmount2 && _mintAmount2 < 10);

        vm.assume(
            user1 != makeAddr("constructor1") && user1 != makeAddr("constructor2") && user1 != makeAddr("constructor3")
        );
        vm.assume(
            user2 != makeAddr("constructor1") && user2 != makeAddr("constructor2") && user2 != makeAddr("constructor3")
        );

        uint256 constructorMintAmount = getConstructorMintAmount();

        // beforeMint
        IERC721A.TokenOwnership memory beforeMintData = token.explicitOwnershipOf(_mintAmount1);

        assertEq(beforeMintData.addr, zeroAddress);
        assertEq(beforeMintData.startTimestamp, 0);
        assertEq(beforeMintData.burned, false);

        setMint(_mintAmount1, _merkleProof, user1);
        setMint(_mintAmount2, _merkleProof, user2);

        // afterMint
        IERC721A.TokenOwnership memory afterMintData1 =
            token.explicitOwnershipOf(START_TOKENID + constructorMintAmount + _mintAmount1 - 1);
        assertEq(afterMintData1.addr, user1);
        assertEq(afterMintData1.startTimestamp, block.timestamp);
        assertEq(afterMintData1.burned, false);

        IERC721A.TokenOwnership memory afterMintData2 =
            token.explicitOwnershipOf(START_TOKENID + constructorMintAmount + _mintAmount1 + _mintAmount2 - 1);
        assertEq(afterMintData2.addr, user2);
        assertEq(afterMintData2.startTimestamp, block.timestamp);
        assertEq(afterMintData2.burned, false);

        // not allow burn
    }

    function testTokensOfOwner(uint16 _mintAmount1, bytes32[] calldata _merkleProof, address user1) public {
        vm.assume(user1 != address(0));
        vm.assume(0 < _mintAmount1 && _mintAmount1 < 10);
        vm.assume(
            user1 != makeAddr("constructor1") && user1 != makeAddr("constructor2") && user1 != makeAddr("constructor3")
        );

        setMint(_mintAmount1, _merkleProof, user1);
        uint256[] memory data1 = token.tokensOfOwner(user1);
        assertEq(data1.length, _mintAmount1);
    }

    function testReadOwnerOf(
        uint16 _mintAmount1,
        uint16 _mintAmount2,
        bytes32[] calldata _merkleProof,
        address user1,
        address user2
    ) public {
        vm.assume(user1 != address(0) && user2 != address(0) && user1 != user2);
        vm.assume(0 < _mintAmount1 && _mintAmount1 < 10);
        vm.assume(0 < _mintAmount2 && _mintAmount2 < 10);

        setMint(_mintAmount1, _merkleProof, user1);
        setMint(_mintAmount2, _merkleProof, user2);

        uint256 constructorMintAmount = getConstructorMintAmount();
        assertEq(token.ownerOf(START_TOKENID + constructorMintAmount + _mintAmount1 - 1), user1);
        assertEq(token.ownerOf(START_TOKENID + constructorMintAmount + _mintAmount1 + _mintAmount2 - 1), user2);

        vm.expectRevert();
        token.ownerOf(START_TOKENID + constructorMintAmount + _mintAmount1 + _mintAmount2);
    }

    function testReadTotalSupply(
        uint16 _mintAmount1,
        uint16 _mintAmount2,
        bytes32[] calldata _merkleProof,
        address user1,
        address user2
    ) public {
        vm.assume(user1 != address(0) && user2 != address(0) && user1 != user2);
        vm.assume(0 < _mintAmount1 && _mintAmount1 < 10);
        vm.assume(0 < _mintAmount2 && _mintAmount2 < 10);

        setMint(_mintAmount1, _merkleProof, user1);
        setMint(_mintAmount2, _merkleProof, user2);

        uint256 constructorMintAmount = getConstructorMintAmount();
        assertEq(token.totalSupply(), constructorMintAmount + _mintAmount1 + _mintAmount2);
    }

    function setMint(uint16 _mintAmount, bytes32[] calldata _merkleProof, address user) public {
        uint16 _maxMintAmount = 10;

        //SaleInfo setup
        vm.startPrank(owner);
        uint8 salePhase = 1;
        bytes32 merkleRoot = 0x0000000000000000000000000000000000000000000000000000000000000000;
        uint16 maxPhaseSupply = 500;
        uint64 cost = 0.001 ether;
        token.setSaleInfo(salePhase, merkleRoot, maxPhaseSupply, cost);
        token.setSalePhase(salePhase);
        vm.stopPrank();

        //handler setup
        vm.startPrank(user, user);
        vm.deal(user, 100 ether);
        token.mint{value: cost * _mintAmount}(_mintAmount, _maxMintAmount, _merkleProof);
        vm.stopPrank();
    }

    function getConstructorMintAmount() public view returns (uint256) {
        uint256 x = 0;

        if (isConstructorMint) {
            for (uint256 i = 0; i < constructorMintQuantities.length;) {
                x = x + constructorMintQuantities[i];
                unchecked {
                    i++;
                }
            }
        }

        return x;
    }
}
