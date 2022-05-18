const CloneTimeLockWithAmount = artifacts.require("CloneTimeLockWithAmount");
const oneMonth = 60 * 60 * 24 * 30;
const oneMinute = 60;
module.exports = function (deployer) {
  deployer.deploy(
    CloneTimeLockWithAmount,
    "0xD205C35e8667E2b63eb43388f154bfc22f48Abe1",
    [100, 200, 200, 300, 400, 500],
    [
      oneMinute * 5 * 1,
      oneMinute * 5 * 2,
      oneMinute * 5 * 3,
      oneMinute * 5 * 4,
      oneMinute * 5 * 5,
      oneMinute * 5 * 6,
    ],
    [100, 100, 100, 100, 100, 100],
    [
      oneMinute * 7 * 1,
      oneMinute * 7 * 2,
      oneMinute * 7 * 3,
      oneMinute * 7 * 4,
      oneMinute * 7 * 5,
      oneMinute * 7 * 6,
    ]
  );
};
