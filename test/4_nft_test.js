const IVIRSE = artifacts.require("IVIRSE");
const IVIRSENFT = artifacts.require("IVIRSENFT");
const { expectRevert, expectEvent } = require("@openzeppelin/test-helpers");

contract("IVIRSENFT", (accounts) => {
  let ivi,
    nft,
    owner,
    count = 0,
    tenAccounts,
    allTokenOfOwner;

  users = [];
  const getURI = () => {
    return `URI ${count++}`;
  };
  before("Init", async () => {
    ivi = await IVIRSE.deployed();
    nft = await IVIRSENFT.deployed();
    owner = await nft.owner();
    accounts.shift();
    accounts.forEach((item) => {
      users.push(item);
    });
  });
  describe("Safe mint", () => {
    it("Safe mint from owner", async () => {
      let oldNfts = await nft.getNftOwners(owner);
      let newTokenURI = getURI();
      await nft.safeMint(owner, newTokenURI);
      let newNfts = await nft.getNftOwners(owner);
      assert.equal(oldNfts.length + 1, newNfts.length);
    });
    it("Safe mint not from owner", async () => {
      let newTokenURI = getURI();

      await expectRevert.unspecified(
        nft.safeMint(users[0], newTokenURI, { from: users[0] }),
        "Unauthorized"
      );
    });
    it("Check owner and token uri after mint", async () => {
      let account = users[0];
      let oldNfts = await nft.getNftOwners(account);
      let newTokenURI = getURI();
      await nft.safeMint(account, newTokenURI);
      let newNfts = await nft.getNftOwners(account);
      let notMatchToken = newNfts.filter((item) => !oldNfts.includes(item))[0];

      let ownerOfToken = await nft.getOwnerById(notMatchToken);
      let tokenURI = await nft.tokenURI(notMatchToken);
      assert.equal(account, ownerOfToken);
      assert.equal(newTokenURI, tokenURI);
    });
    it("Mint nft when User is not minter", async () => {
      let from = users[13];
      let newTokenURI = getURI();
      await expectRevert.unspecified(
        nft.safeMint(from, newTokenURI, { from }),
        "Unauthorized"
      );
    });
    it("Mint nft when User is a minter", async () => {
      let from = users[13];
      let newTokenURI = getURI();
      await expectRevert.unspecified(
        nft.safeMint(from, newTokenURI, { from }),
        "Unauthorized"
      );
      await nft.addMinter(from);
      await nft.safeMint(from, newTokenURI, { from });
    });
  });
  describe("Sell", async () => {
    before("Mint before test", async () => {
      tenAccounts = accounts.slice(0, 10);
      await Promise.all(
        Array.from(new Array(10), (_, index) => {
          let newTokenURI = getURI();
          return nft.safeMint(tenAccounts[index], newTokenURI);
        })
      );
      allTokenOfOwner = await Promise.all(
        Array.from(new Array(10), async (_, index) => {
          let tokenIds = await nft.getNftOwners(tenAccounts[index]);
          return { tokenIds, account: tenAccounts[index] };
        })
      );
    });
    it("Seller is owner of nft", async () => {
      let tokenId = allTokenOfOwner[0].tokenIds[0];
      let amount = 1;
      let tokenOwner = allTokenOfOwner[0].account;
      await nft.sellNft(tokenId, amount, { from: tokenOwner });
      let publicStore = await nft.getPublicStore();
      let tokenId2 = publicStore.find(
        (item) => item.toNumber() == tokenId.toNumber()
      );
      assert.equal(tokenId.toNumber(), tokenId2.toNumber());
    });
    it("Seller is not owner of nft", async () => {
      let tokenId = allTokenOfOwner[1].tokenIds[0];
      let amount = 1;
      let anotherClient = allTokenOfOwner[2].account;
      await expectRevert.unspecified(
        nft.sellNft(tokenId, amount, { from: anotherClient }),
        "Address is not owner"
      );
    });
    it("Owner sell twice", async () => {
      let tokenId = allTokenOfOwner[2].tokenIds[0];
      let amount = 1;
      let tokenOwner = allTokenOfOwner[2].account;
      await nft.sellNft(tokenId, amount, { from: tokenOwner }),
        await expectRevert.unspecified(
          nft.sellNft(tokenId, amount, { from: tokenOwner }),
          "Token had been bought"
        );
    });
    it("Owner sell with amount zero", async () => {
      let tokenId = allTokenOfOwner[3].tokenIds[0];
      let tokenOwner = allTokenOfOwner[3].account;
      let amount = 0;
      await expectRevert.unspecified(
        nft.sellNft(tokenId, amount, { from: tokenOwner }),
        "Token had been bought"
      );
    });
    it("Emit event when sell nft", async () => {
      let tokenId = allTokenOfOwner[4].tokenIds[0];
      let tokenOwner = allTokenOfOwner[4].account;
      let amount = 100000;
      let result = await nft.sellNft(tokenId, amount, { from: tokenOwner });

      expectEvent(result, "NftEvent", {
        _from: tokenOwner,
        _to: tokenOwner,
        _tokenId: tokenId,
      });
    });
  });
  describe("Purchase", () => {
    it("Purchase enough allowance and token in store", async () => {
      let accountSell = users[11];
      let amount = 100000;
      await ivi.mint(accountSell, amount);
      await ivi.approve(nft.address, amount, { from: accountSell });
      let publicStore = await nft.getPublicStore();
      let nftAndPrice = await Promise.all(
        publicStore.map(async (item) => {
          let tokenId = item.toNumber();
          let price = await nft.getPrice(tokenId);

          return { tokenId, price: price.toNumber() };
        })
      );
      console.log(nftAndPrice);
      let result = await nft.purchase(7, { from: accountSell });
      await expectEvent(result, "NftEvent");
    });
    it("Purchase nft but not enough ivi", async () => {
      let account = users[12];
      await expectRevert.unspecified(
        nft.purchase(1, { from: account }),
        "User hasn't ivi"
      );
    });
  });
});
