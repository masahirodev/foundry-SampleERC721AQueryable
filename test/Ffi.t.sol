// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import "forge-std/Test.sol";
import "contracts/SampleERC721AQueryable.sol";

import {TestHelpers} from "./TestHelpers.t.sol";
import {InternalFunction} from "./InternalFunction.t.sol";
import {ConstructorDatas} from "./ConstructorDatas.t.sol";

import "@openzeppelin/contracts/utils/Strings.sol";

contract FfiTest is Test, TestHelpers, InternalFunction, ConstructorDatas {
    using stdStorage for StdStorage;

    // for ffi test
    struct merkleData {
        address addr;
        uint16 maxMintAmount;
        bytes32[] proofs;
    }

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
                                                    MINT
    //////////////////////////////////////////////////////////////////////////////////////////////////*/

    //merkleProof
    function testMerkleProofMint(uint16 _mintAmount, uint256 i) public {
        vm.assume(i < 128);

        string[] memory runJsInputs = new string[](2);
        runJsInputs[0] = "node";
        runJsInputs[1] = "ts-src/merkle/merkleFunction.js";

        bytes memory Result = vm.ffi(runJsInputs);
        (bytes32 jsRoot, merkleData[] memory data) = abi.decode(Result, (bytes32, merkleData[]));

        //SaleInfo setup
        vm.startPrank(owner);
        uint8 salePhase = 1;
        bytes32 merkleRoot = jsRoot;
        uint16 maxPhaseSupply = 500;
        uint64 cost = 0.001 ether;
        token.setSaleInfo(salePhase, merkleRoot, maxPhaseSupply, cost);
        token.setSalePhase(salePhase);
        vm.stopPrank();

        user1 = data[i].addr;

        //handler setup
        vm.startPrank(user1, user1);
        vm.deal(user1, 100 ether);

        // normal mint
        vm.assume(0 < _mintAmount && _mintAmount < data[i].maxMintAmount);
        token.mint{value: cost * _mintAmount}(_mintAmount, data[i].maxMintAmount, data[i].proofs);

        // add mint
        uint16 _addMintAmount = data[i].maxMintAmount - _mintAmount;
        token.mint{value: cost * _addMintAmount}(_addMintAmount, data[i].maxMintAmount, data[i].proofs);

        // more mint
        vm.expectRevert(bytes("Over the limit"));
        token.mint{value: cost * 1}(1, data[i].maxMintAmount, data[i].proofs);
    }

    //merkleProof
    function testMerkleProofMultipleMint(uint16 _mintAmount, uint256 i) public {
        vm.assume(i < 128);

        string[] memory runJsInputs = new string[](2);
        runJsInputs[0] = "node";
        runJsInputs[1] = "ts-src/merkle/merkleFunction.js";

        bytes memory Result = vm.ffi(runJsInputs);
        (bytes32 jsRoot, merkleData[] memory data) = abi.decode(Result, (bytes32, merkleData[]));

        //SaleInfo setup
        vm.startPrank(owner);
        uint8 salePhase = 1;
        bytes32 merkleRoot = jsRoot;
        uint16 maxPhaseSupply = 500;
        uint64 cost = 0.001 ether;
        token.setSaleInfo(salePhase, merkleRoot, maxPhaseSupply, cost);
        token.setSalePhase(salePhase);
        vm.stopPrank();

        user1 = data[i].addr;

        //handler setup
        vm.startPrank(user1, user1);
        vm.deal(user1, 100 ether);

        // normal mint
        vm.assume(0 < _mintAmount && _mintAmount < data[i].maxMintAmount);
        token.mint{value: cost * _mintAmount}(_mintAmount, data[i].maxMintAmount, data[i].proofs);

        // add mint
        uint16 _addMintAmount = data[i].maxMintAmount - _mintAmount;
        token.mint{value: cost * _addMintAmount}(_addMintAmount, data[i].maxMintAmount, data[i].proofs);

        // more mint
        vm.expectRevert(bytes("Over the limit"));
        token.mint{value: cost * 1}(1, data[i].maxMintAmount, data[i].proofs);
        vm.stopPrank();

        //SaleInfo setup
        vm.startPrank(owner);
        salePhase = 2;
        token.setSaleInfo(salePhase, merkleRoot, maxPhaseSupply, cost);
        token.setSalePhase(salePhase);
        vm.stopPrank();

        //handler setup
        vm.startPrank(user1, user1);
        vm.deal(user1, 100 ether);

        // normal mint
        vm.assume(0 < _mintAmount && _mintAmount < data[i].maxMintAmount);
        token.mint{value: cost * _mintAmount}(_mintAmount, data[i].maxMintAmount, data[i].proofs);
    }
}
