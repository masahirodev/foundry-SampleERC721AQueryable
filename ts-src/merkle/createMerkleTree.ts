import { MerkleTree } from "merkletreejs";
import { ethers } from "ethers";
import { keccak256 } from "ethereum-cryptography/keccak";

type Leaf = {
  address: string;
  amount: number;
};

export const createMerkleTree = (leaves: Leaf[]) => {
  const hashleaves = leaves.map((x) =>
    ethers.utils.solidityKeccak256(
      ["address", "uint256"],
      [x.address, x.amount]
    )
  );

  const tree = new MerkleTree(hashleaves, keccak256, { sort: true });
  const proofs = hashleaves.map((leave) => tree.getHexProof(leave));
  const root = tree.getHexRoot();

  // for (let i = 0; i < 128; i++) {
  //   const check = tree.verify(proofs[i], hashleaves[i], root);
  //   console.log(check);
  // }

  return { root, proofs };
};
