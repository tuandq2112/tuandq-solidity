const Transfer = artifacts.require("Transfer");
contract("Transfer", (accounts) => {
  let ivi, owner;
  before("Init", async () => {
    ivi = await Transfer.deployed();
    owner = await ivi.owner();
    await ivi.mint(owner, 10000000000000000000000n);
  });
  describe("Return data to draw dashboard", async () => {
    it("Transfers", async () => {
      let data = [];
      for (let i = 0; i < 100; i++) {
        let users = accounts.slice(0, i + 1);
        let result = await ivi.transferToUsers(users, 1);

        data.push({ number: i + 1, gasUsed: result.receipt.gasUsed });
      }
    });
  });
});
