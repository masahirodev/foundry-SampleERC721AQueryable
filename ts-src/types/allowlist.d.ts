declare module "*/allowlist.json" {
  interface Leaf {
    address: string;
    amount: number;
  }

  const value: Leaf[];
  export = value;
}
