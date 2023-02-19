// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "../src/SampleERC721AQueryable.sol";

contract SampleERC721AQueryableScript is Script {
    SampleERC721AQueryable public token;

    string public _name = "MockAzuki";
    string public _symbol = "MA";
    string public _unRevealedURI = "unRevealedURI";
    string public baseURI_ = "baseURI";
    string public _baseExtension = "baseExtension";
    uint96 public _royaltyFee = 1_000;
    uint256 public _maxSupply = 10_000;

    // constructor mint
    address[] constructorMintTos;
    uint256[] constructorMintQuantities;

    function setUp() public {}

    function run() public {
        // uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        uint256 deployerPrivateKey = 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;
        vm.startBroadcast(deployerPrivateKey);

        token =
        new SampleERC721AQueryable(_name,_symbol,_unRevealedURI,baseURI_,_baseExtension,_royaltyFee,_maxSupply,constructorMintTos,constructorMintQuantities);

        vm.stopBroadcast();
    }
}

// forge script script/SampleERC721AQueryable.s.sol:SampleERC721AQueryableScript \
// --fork-url http://localhost:8545 \
// --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 \
// --broadcast
