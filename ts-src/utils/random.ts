import { ethers } from "ethers";
import { privateToAddress } from "@ethereumjs/util";
import crypto from "crypto";

export const getRandomAddress = () => {
  return ethers.utils.getAddress(
    privateToAddress(crypto.randomBytes(32)).toString("hex")
  );
};

export const getRandomInt = (max: number) => {
  return Math.floor(Math.random() * (max - 1) + 1);
};
