## summary

This repository will be fondry tested on the subject of standard NFT projects with ERC721A as the main subject.
However, since the testing time is very long, I limit the number of tests as much as possible (especially ffi).

| test   | number |    time |
| :----- | :----: | ------: |
| normal | 31 + 3 | 8s + 1s |
| fork   |   1    |     60s |
| ffi    |   2    |    900s |

Therefore, for the mint test, please add tests according to the sales case you expect.
In addition, logic tests for inherited contracts are assumed to be performed for each contract, and only tests for inheritance are implemented.

<br>

Note: The address used for constructorMint (ERC2309) has not been completely eliminated.
If an error occurs, try to verify it by running the test that produced the error alone.

<br>

### Sub test

The operation of merkleProof is confirmed by FfiTest.
For OpenSea operator-filter-registry, the blacklist operation is confirmed by forking mainnet in ForkTest.

<br>

## Folder Structure

### contracts

Main：SampleERC721AQueryable.sol

Sale：SaleInfoData.sol
(Since the data should not be stored in the contract, it is recommended that the data be overwritten at each sale, rather than using this contract.)

<br>

### tests

Main：SampleERC721AQueryable.t.sol

Sale：SaleInfoData.t.sol

MerkleProof：Ffi.t.sol

OpenSea operator-filter-registry（on-chain）：Fork.t.sol

Helper：ConstructorDatas.t.sol / InternalFunction.t.sol / TestHelpers.t.sol

<br>

## HOW TO USE

### Normal test preparation

```jsx
forge install
```

### Ffi test preparation

```jsx
npm i
npm run compile
```

Change the contents of ts-src/merkle/allowlist.json as necessary.

### Fork test preparation

Add the following to `.env` in the root folder.

```jsx
MAINNET_RPC_URL = https://mainnet.infura.io/v3/{API_KEY}
```

###　 Comprehensive test (all tests will be administered)

```jsx
forge test --ffi
```

<br>

## Method vs Test

### write method

| method            | section           | test name                                                        |
| :---------------- | :---------------- | :--------------------------------------------------------------- |
| approve           | write contract    | testApprove                                                      |
| mint              | mint              | testNotAllowMint/testMerkleProofMint/testMerkleProofMultipleMint |
| ownerMint         | mint              | testOwnerMint                                                    |
| renounce          | write contract    | testRenounce                                                     |
| safeTransferFrom  | write contract    | testSafeTransferFrom/testOperaterSafeTransferFrom                |
| setApprovalForAll | write contract    | testSetApprovalForAll/testCancelSetApprovalForAll                |
| setBaseURI        | tokenURI          | testTokenURI                                                     |
| setDefaultRoyalty | setDefaultRoyalty | testSetDefaultRoyalty/testNotSetDefaultRoyalty                   |
| setRevealed       | setRevealed       | testSetRevealed                                                  |
| setSaleInfo       | SALE              | testSetSaleInfo                                                  |
| setSalePhase      | SALE              | testSetSalePhase                                                 |
| transferFrom      | write contract    | testTransferFrom/testOperaterTransferFrom                        |
| transferOwnership | write contract    | testTransferOwnership                                            |
| withdraw          | withdraw          | testWithdraw                                                     |

<br>

### read method

| method                        | section           | test name               |
| :---------------------------- | :---------------- | :---------------------- |
| balanceOf                     | read contract     | testBalanceOf           |
| explicitOwnershipOf           | read contract     | testExplicitOwnershipOf |
| getApproved                   | write contract    | testApprove             |
| getSaleInfo                   | SALE              | testSetSaleInfo         |
| isApprovedForAll              | write contract    | testSetApprovalForAll   |
| name                          | metadata          | testCheckMetaData       |
| owner                         | metadata          | testCheckMetaData       |
| ownerOf                       | read contract     | testReadOwnerOf         |
| royaltyInfo                   | setDefaultRoyalty | testSetDefaultRoyalty   |
| SaleInfos                     | SALE              | testSetSaleInfo         |
| supportsInterface             | IERC165           | testSupportsInterface   |
| symbol                        | metadata          | testCheckMetaData       |
| tokenOfOwner / tokenOfOwnerIn | read contract     | testReadOwnerOf         |
| tokenURI                      | tokenURI          | testTokenURI            |
| totalSupply                   | read contract     | testReadTotalSupply     |
