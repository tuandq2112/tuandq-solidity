const readXlsxFile = require("read-excel-file/node");

const ClaimToken = artifacts.require("ClaimToken");
const IvirseToken = artifacts.require("IvirseToken");

function isAddress(address) {
  return address ? address.match(/^0x[a-fA-F0-9]{40}$/) : false;
}
const path = {
  window: "C:\\Users\\Admin\\Desktop\\import1.xlsx",
  linux: "/home/tuandoquoc/Desktop/tuanimport.xlsx",
};
module.exports = async function (deployer) {
  let successArr = [];
  let errorArr = [];
  let coinAddress = "0xD205C35e8667E2b63eb43388f154bfc22f48Abe1";

  async function getSheet1Data() {
    let rows = await readXlsxFile(path.window, {
      sheet: 2,
    });
    return rows;
  }

  async function getSheet2Data(idCol, addressCol) {
    let rows = await readXlsxFile(path.window, {
      sheet: 3,
    });
    return rows
      .map((row) => ({
        id: row[idCol],
        address: row[addressCol],
      }))
      .filter((item) => isAddress(item.address));
  }

  function convertData(
    idData,
    allData,
    colIdAllData = 1,
    startSeedLine,
    endSeedLine,
    startPrivateLine,
    endPrivateLine
  ) {
    let seedData = allData.slice(startSeedLine - 1, endSeedLine);
    let privateData = allData.slice(startPrivateLine - 1, endPrivateLine);
    return idData.map((item) => {
      let seed = (
        seedData.find((arr) => arr[colIdAllData - 1] == item.id) || []
      )
        .slice(2)
        .map((item) => Math.round(item));
      let private = (
        privateData.find((arr) => arr[colIdAllData - 1] == item.id) || []
      )
        .slice(2)
        .map((item) => Math.round(item));
      return { ...item, seed, private };
    });
  }

  let sheet1Data = await getSheet1Data();
  let sheet2Data = await getSheet2Data(1, 2);
  let data = convertData(sheet2Data, sheet1Data, 1, 4, 46, 50, 92);
  let currentDate = new Date("2021/07");
  let times = Array.from(new Array(31), (el, index) => {
    return Math.round(
      new Date("2021/07").setMonth(currentDate.getMonth() + index + 1) / 1000
    );
  });
  for (let i = 0; i < 1; i++) {
    let item = data[i];
    let id = item.id;
    // let newOwner = item.address;

    let newOwner = "0x26c404D5D4F429Ba54a51124637c783cfd45E3d0";
    let seedCoin = item.seed;
    let privateCoin = item.private;

    let allToken = [...seedCoin, ...privateCoin].reduce((a, b) => a + b, 0);

    await deployer
      .deploy(ClaimToken, coinAddress, times, seedCoin, privateCoin)
      .then(async (res) => {
        console.log(
          i + 1,
          id,
          `===================================================Deploy success===========================================================\n ${res.address}`
        );
        let ivi = await IvirseToken.at(coinAddress);
        let claimSmc = await IvirseToken.at(res.address);
        await ivi.transfer(res.address, BigInt(allToken * Math.pow(10, 18)));
        await claimSmc.transferOwnership(newOwner);
        successArr.push({ ...item, contractAddress: res.address });
      })
      .catch((err) => {
        console.log(err);
        errorArr.push(item);
      });
  }
  console.log("successArr", successArr);
  console.log("errorArr", errorArr);
  console.log(
    "Result: ",
    successArr.map((item) => item.contractAddress)
  );
};
