const ClaimToken = artifacts.require("ClaimToken");
const oneMonth = 60 * 60 * 24 * 30;
const oneMinute = 60;
module.exports = function (deployer) {
  deployer.deploy(
    ClaimToken,
    "0xD205C35e8667E2b63eb43388f154bfc22f48Abe1",
    [
      oneMinute * 5 * 1,
      oneMinute * 5 * 2,
      oneMinute * 5 * 3,
      oneMinute * 5 * 4,
      oneMinute * 5 * 5,
      oneMinute * 5 * 6,
    ],
    [100, 200, 200, 300, 400, 500],
    [100, 100, 100, 100, 100, 100]
  );
};
