const TimeLockWithAmount = artifacts.require("TimeLockWithAmount");
const oneMonth = 60 * 60 * 24 * 30;
const oneCoin = Math.pow(10, 10);
module.exports = function (deployer) {
  deployer.deploy(
    TimeLockWithAmount,
    "0xD205C35e8667E2b63eb43388f154bfc22f48Abe1",
    [
      1000 * oneCoin,
      2000 * oneCoin,
      3000 * oneCoin,
      1000 * oneCoin,
      3500 * oneCoin,
    ],
    [oneMonth * 3, oneMonth * 3, oneMonth * 6, oneMonth * 9, oneMonth * 12],
    [
      3000 * oneCoin,
      1000 * oneCoin,
      3500 * oneCoin,
      1000 * oneCoin,
      2000 * oneCoin,
    ],
    [oneMonth * 1, oneMonth * 1, oneMonth * 6, oneMonth * 3, oneMonth * 18]
  );
};
