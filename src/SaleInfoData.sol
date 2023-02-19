// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";

abstract contract SaleInfoData is Ownable {
    struct SaleInfo {
        bytes32 merkleRoot;
        uint16 maxSupply;
        uint64 cost;
    }

    mapping(uint8 => SaleInfo) public SaleInfos;

    /*//////////////////////////////////////////////////////////////////////////////////////////////////
                                                CONSTRUCTOR
    //////////////////////////////////////////////////////////////////////////////////////////////////*/

    constructor() {
        //NotSalePhase
        SaleInfos[0] = SaleInfo({merkleRoot: 0x00, maxSupply: 0, cost: 0});

        //FreeMintPhase
        SaleInfos[1] = SaleInfo({
            merkleRoot: 0x0000000000000000000000000000000000000000000000000000000000000001,
            maxSupply: 2000,
            cost: 0
        });

        //AllowListSalePhase
        SaleInfos[2] = SaleInfo({
            merkleRoot: 0x0000000000000000000000000000000000000000000000000000000000000001,
            maxSupply: 6000,
            cost: 1 ether
        });

        //PublicSalePhase
        SaleInfos[3] = SaleInfo({merkleRoot: 0x00, maxSupply: 10000, cost: 2 ether});
    }

    /*//////////////////////////////////////////////////////////////////////////////////////////////////
                                                GET / SET
    //////////////////////////////////////////////////////////////////////////////////////////////////*/
    function getSaleInfo(uint8 index) public view returns (bytes32 merkleRoot, uint16 maxSupply, uint64 cost) {
        merkleRoot = SaleInfos[index].merkleRoot;
        maxSupply = SaleInfos[index].maxSupply;
        cost = SaleInfos[index].cost;
    }

    function setSaleInfo(uint8 index, bytes32 merkleRoot, uint16 maxSupply, uint64 cost) public onlyOwner {
        SaleInfos[index].merkleRoot = merkleRoot;
        SaleInfos[index].maxSupply = maxSupply;
        SaleInfos[index].cost = cost;
    }
}
