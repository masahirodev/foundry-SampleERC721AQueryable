import { ethers } from "ethers";
import { createMerkleTree } from "./createMerkleTree";
import { createAllowLists } from "./createLeaves";
import { outputJson } from "./output";

const isTest = true;

const allowLists = createAllowLists(isTest);
const { root, proofs } = createMerkleTree(allowLists);

export const outputMerkleDatas = () => {
  const merkleDatas: { address: string; amount: number; proofs: string[] }[] =
    allowLists.map((allowList, i) => {
      return {
        ...allowList,
        proofs: proofs[i],
      };
    });

  outputJson(merkleDatas, "merkleDatas.json");
  return merkleDatas;
};
const merkleDatas = outputMerkleDatas();

const createHashMerkleDatas = () => {
  const hashMerkleDatas = ethers.utils.defaultAbiCoder.encode(
    ["bytes32 root", "tuple(address address,uint16 amount,bytes32[] proofs)[]"],
    [root, merkleDatas]
  );

  return hashMerkleDatas;
};

console.log(createHashMerkleDatas());
