// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import "forge-std/Test.sol";
import "contracts/SaleInfoData.sol";

import {TestHelpers} from "./TestHelpers.t.sol";
import {InternalFunction} from "./InternalFunction.t.sol";

contract Abstract is SaleInfoData {}

contract SaleInfoDataTest is Test, TestHelpers, InternalFunction {
    Abstract public token;

    struct SaleInfo {
        bytes32 merkleRoot;
        uint16 maxSupply;
        uint64 cost;
    }

    /*//////////////////////////////////////////////////////////////////////////////////////////////////
                                                CHECK DATAS
    //////////////////////////////////////////////////////////////////////////////////////////////////*/

    //NotSalePhase
    SaleInfo saleInfo0 = SaleInfo({
        merkleRoot: 0x0000000000000000000000000000000000000000000000000000000000000000,
        maxSupply: 0,
        cost: 0
    });

    //FreeMintPhase
    SaleInfo saleInfo1 = SaleInfo({
        merkleRoot: 0x0000000000000000000000000000000000000000000000000000000000000001,
        maxSupply: 2000,
        cost: 0
    });

    //AllowListSalePhase
    SaleInfo saleInfo2 = SaleInfo({
        merkleRoot: 0x0000000000000000000000000000000000000000000000000000000000000001,
        maxSupply: 6000,
        cost: 1 ether
    });

    //PublicSalePhase
    SaleInfo saleInfo3 = SaleInfo({
        merkleRoot: 0x0000000000000000000000000000000000000000000000000000000000000000,
        maxSupply: 10000,
        cost: 2 ether
    });

    /*//////////////////////////////////////////////////////////////////////////////////////////////////
                                                  TEST
    //////////////////////////////////////////////////////////////////////////////////////////////////*/

    function setUp() public onlyOwner {
        token = new Abstract();
    }

    /*//////////////////////////////////////////////////////////////////////////////////////////////////
                                                MODIFIER
    //////////////////////////////////////////////////////////////////////////////////////////////////*/

    function testOnlyOwner(uint8 salePhase, bytes32 merkleRoot, uint16 maxPhaseSupply, uint64 cost) public {
        vm.expectRevert(bytes("Ownable: caller is not the owner"));
        token.setSaleInfo(salePhase, merkleRoot, maxPhaseSupply, cost);
    }

    /*//////////////////////////////////////////////////////////////////////////////////////////////////
                                                GET / SET
    //////////////////////////////////////////////////////////////////////////////////////////////////*/

    function testCheckConstructor() public {
        uint8 salePhase = 0;
        (bytes32 _merkleRoot, uint16 _maxPhaseSupply, uint64 _cost) = token.getSaleInfo(salePhase);
        assertEq(saleInfo0.merkleRoot, _merkleRoot);
        assertEq(saleInfo0.maxSupply, _maxPhaseSupply);
        assertEq(saleInfo0.cost, _cost);
    }

    function testGetSetSaleInfo(uint8 salePhase, bytes32 merkleRoot, uint16 maxPhaseSupply, uint64 cost)
        public
        onlyOwner
    {
        token.setSaleInfo(salePhase, merkleRoot, maxPhaseSupply, cost);
        (bytes32 _merkleRoot, uint16 _maxPhaseSupply, uint64 _cost) = token.getSaleInfo(salePhase);

        assertEq(merkleRoot, _merkleRoot);
        assertEq(maxPhaseSupply, _maxPhaseSupply);
        assertEq(cost, _cost);
    }
}
