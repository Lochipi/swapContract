import { loadFixture } from "@nomicfoundation/hardhat-toolbox/network-helpers";
import { anyValue } from "@nomicfoundation/hardhat-chai-matchers/withArgs";
import { expect } from "chai";
import hre from "hardhat";

describe("Swap", function () {
  // We define a fixture to reuse the same setup in every test.
  // We use loadFixture to run this setup once, snapshot that state,
  // and reset Hardhat Network to that snapshot in every test.
  async function deployOneYearLockFixture() {
    // Contracts are deployed using the first signer/account by default
    const [owner, otherAccount, fulfiller] = await hre.ethers.getSigners();

    const Swaping = await hre.ethers.getContractFactory("SwapToken");
    const swap = await Swaping.deploy();

    // deploy the swap contract
    const Token = await hre.ethers.getContractFactory("Token");
    const guzToken = await Token.deploy("Guz Token", "GUZ", hre.ethers.parseEther("1000"));
    const w3bToken = await Token.deploy("W3B Token", "W3B", hre.ethers.parseEther("1000"));

     // Fund other accounts with tokens for testing purposes
     await (guzToken as any).transfer(otherAccount.address, hre.ethers.parseEther("100"));
     await (w3bToken as any).transfer(fulfiller.address, hre.ethers.parseEther("100"));
 
     return { swap, guzToken, w3bToken, owner, otherAccount, fulfiller };
  }

  describe("Deployment", function () {
    it("Should set the right owner", async function () {
      const { owner } = await loadFixture(deployOneYearLockFixture);

      expect(await owner.address).to.equal(owner.address);
    });
  });
});

