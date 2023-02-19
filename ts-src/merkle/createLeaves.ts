import { ethers } from "ethers";
import { output } from "./output";
import { getRandomAddress, getRandomInt } from "../utils/random";

import importAllowLists = require("./allowlist.json");

export type Leaf = {
  address: string;
  amount: number;
};

// creates dummyDatas
export const createAllowLists = (isTest?: boolean) => {
  const allowLists: Leaf[] = importAllowLists;

  while (allowLists.length < 128) {
    const newAddress = getRandomAddress();
    if (allowLists.some((allowlist) => allowlist.address !== newAddress)) {
      allowLists.push({
        address: newAddress,
        amount: isTest === true ? getRandomInt(10) : 0,
      });
    }
  }

  return allowLists;
};

export const createLeaves = (isTest?: boolean) => {
  const allowLists = createAllowLists(isTest);

  const leaves = allowLists.map((x) =>
    ethers.utils.solidityKeccak256(
      ["address", "uint256"],
      [x.address, x.amount]
    )
  );

  return leaves;
};

export const createHashleaves = (isTest?: boolean) => {
  const allowLists = createAllowLists(isTest);

  const hashleaves = ethers.utils.defaultAbiCoder.encode(
    ["tuple(address address,uint256 amount)[]"],
    [allowLists]
  );

  return hashleaves;
};

export const outputLeaves = (isTest?: boolean) => {
  const hashleaves = createHashleaves(isTest);
  output(hashleaves, "hashleaves.json");
};
