const TimeLockWithAmount = artifacts.require("TimeLockWithAmount");
const oneMonth = 60 * 60 * 24 * 30;
const oneCoin = Math.pow(10, 10);
module.exports = function (deployer) {
  deployer.deploy(
    TimeLockWithAmount,
    "0xD205C35e8667E2b63eb43388f154bfc22f48Abe1",
    [1000, 2000, 3000, 1000, 3500, 5222],
    [
      oneMonth * 3,
      oneMonth * 3,
      oneMonth * 6,
      oneMonth * 9,
      oneMonth * 12,
      oneMonth * 6,
    ],
    [3000, 1000, 3500, 1000, 2000],
    [oneMonth * 1, oneMonth * 1, oneMonth * 6, oneMonth * 3, oneMonth * 18]
  );
};
