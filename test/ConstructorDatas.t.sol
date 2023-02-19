// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import {TestHelpers} from "./TestHelpers.t.sol";

abstract contract ConstructorDatas is TestHelpers {
    // constructor
    string public _name = "MockAzuki";
    string public _symbol = "MA";
    string public _unRevealedURI = "unRevealedURI";
    string public baseURI_ = "baseURI";
    string public _baseExtension = "baseExtension";
    uint96 public _royaltyFee = 1_000;
    uint256 public MAX_SUPPLY = 8_701; //10_000;

    // MIN_TOKENID = START_TOKENID
    // MAX_TOKENID = START_TOKENID + totalSupply() - 1
    uint256 public START_TOKENID = 1_300; //1

    // for test
    bool isConstructorMint = true;

    // constructor mint
    address[] noConstructorMintTos;
    uint256[] noConstructorMintQuantities;

    address[] constructorMintTos = [makeAddr("constructor1"), makeAddr("constructor2"), makeAddr("constructor3")];
    uint256[] constructorMintQuantities = [1, 2, 3];
}
