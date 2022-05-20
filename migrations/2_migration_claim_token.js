const ClaimToken = artifacts.require("ClaimToken");
const IvirseToken = artifacts.require("IvirseToken");

const oneMonth = 60 * 60 * 24 * 30;
const oneMinute = 60;
module.exports = async function (deployer) {
  let coinAddress = "0xD205C35e8667E2b63eb43388f154bfc22f48Abe1";
  let seedCoin = [100, 100, 100, 100, 0, 100];
  let privateCoin = [100, 200, 0, 300, 400, 500];
  let allToken = [...seedCoin, ...privateCoin].reduce((a, b) => a + b, 0);
  deployer
    .deploy(
      ClaimToken,
      coinAddress,
      [
        oneMinute * 2 * 1,
        oneMinute * 2 * 2,
        oneMinute * 2 * 3,
        oneMinute * 2 * 4,
        oneMinute * 2 * 5,
        oneMinute * 2 * 6,
      ],
      seedCoin,
      privateCoin
    )
    .then(async (res) => {
      let ivi = await IvirseToken.at(coinAddress);
      await ivi.transfer(
        ClaimToken.address,
        BigInt(allToken * Math.pow(10, 18))
      );
    });
};
