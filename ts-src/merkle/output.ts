import * as fs from "fs";

export const output = (data: string, fileName: string) => {
  const outputDirectory = "./data/";
  if (!fs.existsSync(outputDirectory)) {
    fs.mkdirSync(outputDirectory);
  }
  fs.writeFileSync(outputDirectory + fileName, data);
};

export const outputJson = (data: any[], fileName: string) => {
  const jsonData = JSON.stringify(data, null, " ");
  const outputDirectory = "./data/";
  if (!fs.existsSync(outputDirectory)) {
    fs.mkdirSync(outputDirectory);
  }
  fs.writeFileSync(outputDirectory + fileName, jsonData);
};
