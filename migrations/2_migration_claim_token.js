const readXlsxFile = require("read-excel-file/node");

const ClaimToken = artifacts.require("ClaimToken");
const IvirseToken = artifacts.require("IvirseToken");

const oneMonth = 60 * 60 * 24 * 30;
const oneMinute = 60;
module.exports = async function (deployer) {
  let coinAddress = "0xD205C35e8667E2b63eb43388f154bfc22f48Abe1";
  let successArr = [];
  let errorArr = [];
  await readXlsxFile("C:\\Users\\Admin\\Desktop\\import.xlsx")
    .then(async (rows) => {
      let data = rows.filter((item) => item.every((str) => str != null));
      for (let i = 0; i < data.length; i++) {
        let item = data[i];
        let name = item[0];
        let newOwner = item[1];
        let seedCoin = JSON.parse(item[2]);
        let privateCoin = JSON.parse(item[3]);
        let times = JSON.parse(item[4]).map(
          (item) => new Date(item).getTime() / 1000
        );
        let allToken = [...seedCoin, ...privateCoin].reduce((a, b) => a + b, 0);

        await deployer
          .deploy(ClaimToken, coinAddress, times, seedCoin, privateCoin)
          .then(async (res) => {
            console.log(
              i + 1,
              `===================================================Deploy success===========================================================\n ${res.address}`
            );
            let ivi = await IvirseToken.at(coinAddress);
            let claimSmc = await IvirseToken.at(res.address);
            await ivi.transfer(
              res.address,
              BigInt(allToken * Math.pow(10, 18))
            );
            await claimSmc.transferOwnership(newOwner);
            successArr.push({ ...item, contractAddress: res.address });
          })
          .catch((err) => {
            console.log(err);
            errorArr.push(item);
          });
      }
    })
    .catch((err) => {
      console.log(err);
    })
    .finally(() => {
      console.log("Result: ", successArr);
      console.log(
        "List addresses",
        successArr.map((item) => item.contractAddress).join(",")
      );
    });
};
