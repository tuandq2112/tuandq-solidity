const readXlsxFile = require("read-excel-file/node");

const ClaimToken = artifacts.require("ClaimToken");
const IvirseToken = artifacts.require("IvirseToken");
const configDeploySmcInvestor = {
  path: {
    window:
      "C:\\Users\\Admin\\Desktop\\IVIRSE_Time line release token Ivirse_Allocate 05.07.2022.xlsx",
    linux: "/home/tuandoquoc/Desktop/test1.xlsx",
  },
  coinAddress: false
    ? "0xdA51E97887640322185A5B8C015CDc3685C982e7"
    : "0x4f730f7a5acebA1CdBf6EB5aAeB8686D8eA37680",
  idCol: 2,
  addressCol: 3,
};

const Time = {
  past: "2019/11",
  now: "2020/05",
  future: "2022/06",
};

function isAddress(address) {
  return address ? address.match(/^0x[a-fA-F0-9]{40}$/) : false;
}

const strDate = Time.past;
module.exports = async function (deployer) {
  let successArr = [];
  let errorArr = [];

  async function getSheet1Data() {
    let rows = await readXlsxFile(configDeploySmcInvestor.path.window, {
      sheet: 2,
    });
    return rows;
  }

  async function getSheet2Data(idCol, addressCol) {
    let rows = await readXlsxFile(configDeploySmcInvestor.path.window, {
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
        .slice(4, 35)
        .map((item) => Math.round(item));
      let private = (
        privateData.find((arr) => arr[colIdAllData - 1] == item.id) || []
      )
        .slice(4, 35)
        .map((item) => Math.round(item));
      let total = [...seed, ...private].reduce((a, b) => a + b, 0);
      return { ...item, seed, private, total };
    });
  }

  let sheet1Data = await getSheet1Data();
  let sheet2Data = await getSheet2Data(
    configDeploySmcInvestor.idCol,
    configDeploySmcInvestor.addressCol
  );
  let data = convertData(sheet2Data, sheet1Data, 3, 4, 6, 9, 11);
  let currentDate = new Date(strDate);
  let times = Array.from(new Array(31), (el, index) => {
    return Math.round(
      new Date(strDate).setMonth(currentDate.getMonth() + index) / 1000
    );
  });
  console.log(times);

  console.log(data);
  for (let i = 0; i < data.length; i++) {
    let item = data[i];
    let id = item.id;
    let newOwner = item.address;
    let seedCoin = item.seed;
    let privateCoin = item.private;

    let allToken = [...seedCoin, ...privateCoin].reduce((a, b) => a + b, 0);

    await deployer
      .deploy(
        ClaimToken,
        configDeploySmcInvestor.coinAddress,
        times,
        seedCoin,
        privateCoin
      )
      .then(async (res) => {
        console.log(
          i + 1,
          id,
          `===================================================Deploy success===========================================================\n ${res.address}`
        );
        let ivi = await IvirseToken.at(configDeploySmcInvestor.coinAddress);
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
