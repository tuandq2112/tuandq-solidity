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
    it("Set time and rate", async () => {
      await timeLock.setTimesAndRate(
        [20, 30, 50],
        [60 * 60 * 24 * 365, 60 * 60 * 24 * 365 * 2, 60 * 60 * 24 * 365 * 3]
      );
      let listTimeAndRate = await timeLock.getListTimeAndRate();
      console.log("listTimeAndRate", listTimeAndRate);
    });

    it("Set time and rate 2", async () => {
      await timeLock.setTimesAndRate(
        [10, 20, 70],
        [60 * 60 * 24 * 365, 60 * 60 * 24 * 365 * 3, 60 * 60 * 24 * 365 * 2]
      );
      let listTimeAndRate = await timeLock.getListTimeAndRate();
      console.log("listTimeAndRate", listTimeAndRate);
    });
  });
});
