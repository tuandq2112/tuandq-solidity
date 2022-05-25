const TuanToken = artifacts.require("TuanToken");
const {
  BN, // Big Number support
  constants, // Common constants, like the zero address and largest integers
  expectEvent, // Assertions for emitted events
  expectRevert,
  time, // Assertions for transactions that should fail
} = require("@openzeppelin/test-helpers");

const decimals = Math.pow(10, 18);
contract("TuanToken", (accounts) => {
  let token;
  before("Init smart contract", async () => {
    token = await TuanToken.deployed();
  });
  describe("Check role", () => {
    it("Mint if admin", async () => {
      let admin = accounts[0];
      let amount = BigInt(decimals * 100);
      await token.mint(admin, amount, { from: admin });
      let balanceOfAdmin = await token.balanceOf(admin);
      assert.equal(balanceOfAdmin, amount);
    });
    it("Mint if not admin", async () => {
      let user = accounts[1];
      let amount = BigInt(decimals * 100);
      await expectRevert.unspecified(
        token.mint(user, amount, { from: user }),
        "Unauthorized"
      );
    });
    it("User mint after grant admin role", async () => {
      let admin = accounts[0];
      let user = accounts[1];
      let amount = BigInt(decimals * 100);
      let DEFAULT_ADMIN_ROLE = await token.DEFAULT_ADMIN_ROLE();

      await expectRevert.unspecified(
        token.grantRole(DEFAULT_ADMIN_ROLE, user, { from: user }),
        "Missing role"
      );
      let hasRole = await token.hasRole(DEFAULT_ADMIN_ROLE, user);
      await token.grantRole(DEFAULT_ADMIN_ROLE, user, { from: admin });
      await token.mint(user, amount, { from: user });
      let balanceOfNewAdmin = await token.balanceOf(user);
      assert.equal(balanceOfNewAdmin, amount);
    });
    it("Add minter", async () => {
      let admin = accounts[1];
      let user = accounts[2];
      let amount = BigInt(decimals * 100);
      let MINTER_ROLE = await token.MINTER_ROLE();
      await expectRevert.outOfGas(
        token.grantRole(MINTER_ROLE, user, { from: user }),
        "Missing role"
      );
      await token.grantRole(MINTER_ROLE, user, { from: admin });
      await expectRevert.unspecified(
        token.mint(user, amount, { from: user }),
        "Unauthorized"
      );
      await token.minterConsensus({ from: user });
      await token.mintConsensus(user, amount, { from: user });
      let balanceOfMinter = await token.balanceOf(user);
      assert.equal(balanceOfMinter, amount);
    });
    it("Revoke role", async () => {
      let admin = accounts[1];
      let user = accounts[2];
      let MINTER_ROLE = await token.MINTER_ROLE();
      await token.grantRole(MINTER_ROLE, user, { from: admin });
      await token.revokeRole(MINTER_ROLE, user, { from: admin });
      let minters = await token.getMinters();
      let hasRole = await token.hasRole(MINTER_ROLE, user);
      console.log(minters, hasRole);
    });
    // it("Add minters", async () => {
    //   let admin = accounts[0];
    //   let users = accounts.slice(3, 10);
    //   Promise.all(users.map(item=>token.))
    // });
  });
});
