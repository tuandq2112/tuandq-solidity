const TimeLockWithAmount = artifacts.require("TimeLockWithAmount");
const oneMonth = 60 * 60 * 24 * 30;
const oneMinute = 60;
module.exports = function (deployer) {
  deployer.deploy(
    TimeLockWithAmount,
    "0xD205C35e8667E2b63eb43388f154bfc22f48Abe1",
    [1000, 2000, 3000, 1000, 3500, 1000],
    [
      oneMinute * 5,
      oneMinute * 10,
      oneMinute * 15,
      oneMinute * 20,
      oneMinute * 25,
      oneMinute * 30,
    ],
    [3000, 1000, 3500, 1000, 2000],
    [oneMonth * 1, oneMonth * 1, oneMonth * 6, oneMonth * 3, oneMonth * 18]
  );
};
