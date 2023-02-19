// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import "forge-std/Test.sol";
import "contracts/SampleERC721AQueryable.sol";

import {TestHelpers} from "./TestHelpers.t.sol";
import {InternalFunction} from "./InternalFunction.t.sol";
import {ConstructorDatas} from "./ConstructorDatas.t.sol";

import "@openzeppelin/contracts/utils/Strings.sol";

//forge test --match-contract ForkTest --match-test testOSoperatorFilterRegistry -vvvvv

contract ForkTest is Test, TestHelpers, InternalFunction, ConstructorDatas {
    SampleERC721AQueryable public token;

    uint256 mainnetFork;
    address blackListAddress = 0xf42aa99F011A1fA7CDA90E5E98b277E306BcA83e;

    function setUp() public onlyOwner {
        mainnetFork = vm.createFork(vm.envString("GOERLI_RPC_URL"));
        vm.selectFork(mainnetFork);

        if (isConstructorMint) {
            token = new SampleERC721AQueryable(_name,_symbol,_unRevealedURI,baseURI_,
            _baseExtension,_royaltyFee,MAX_SUPPLY,constructorMintTos,constructorMintQuantities);
        } else {
            token = new SampleERC721AQueryable(_name,_symbol,_unRevealedURI,baseURI_,_baseExtension,
            _royaltyFee,MAX_SUPPLY,noConstructorMintTos,noConstructorMintQuantities);
        }
    }

    /*//////////////////////////////////////////////////////////////////////////////////////////////////
                                    OpenSea operator-filter-registry
    //////////////////////////////////////////////////////////////////////////////////////////////////*/

    function testOSoperatorFilterRegistry(
        // uint256 tokenId,
        uint16 _mintAmount1,
        address user1,
        address user2
    ) public {
        vm.assume(user1 != address(0) && user2 != address(0) && user1 != user2);
        vm.assume(0 < _mintAmount1 && _mintAmount1 < 10);
        // vm.assume(START_TOKENID <= tokenId && tokenId < START_TOKENID + _mintAmount1);

        uint256 tokenId = START_TOKENID + _mintAmount1 - 1;

        // mint
        vm.startPrank(owner);
        token.ownerMint(user1, _mintAmount1);
        vm.stopPrank();

        // setApprovalForAll
        vm.startPrank(user1);
        vm.expectRevert();
        token.setApprovalForAll(blackListAddress, true);

        // approve
        vm.expectRevert();
        token.approve(blackListAddress, tokenId);
        vm.stopPrank();

        // not allow all transfers by blackListAddress because not set blackListAddress
    }
}
