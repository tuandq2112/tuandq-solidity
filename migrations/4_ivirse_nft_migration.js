const NFT = artifacts.require("NFT");
const Token = artifacts.require("Token");

module.exports = async function (deployer) {
  deployer.deploy(Token).then(() => {
    return deployer.deploy(NFT, Token.address);
  });
};
