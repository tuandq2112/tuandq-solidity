const IVIRSE = artifacts.require("IVIRSE");
const TimeLock2 = artifacts.require("TimeLock2");
const { expectRevert, expectEvent } = require("@openzeppelin/test-helpers");

contract("Timelock2", (accounts) => {
  let ivi,
    timeLock,
    owner,
    investors = accounts.slice(0, 10);
  before("Init", async () => {
    ivi = await IVIRSE.deployed();
    timeLock = await TimeLock2.deployed();
    owner = await ivi.owner();
  });
  describe("Prepare phase", async () => {
    it("Add investor", async () => {
      await timeLock.addInvestor(
        investors,
        investors.map((item) => {
          return Math.floor(Math.random() * 10);
        })
      );
    });
    it("Add investor 2", async () => {
      expectRevert.unspecified(
        timeLock.addInvestor(
          investors.slice(0, 9),
          investors.map((item) => {
            return Math.floor(Math.random() * 10);
          })
        )
      );
    });
    it("Add investor 3", async () => {
      expectRevert.unspecified(
        timeLock.addInvestor(
          investors,
          investors
            .map((item) => {
              return Math.floor(Math.random() * 10);
            })
            .slice(0, 9)
        )
      );
    });
  });
});
