// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

/**
 *@author tuandq
 *@title this smart contract as a marketplace. Users can buy and sell nft by IVI tokens.
 */
contract IVIRSENFT is ERC721, ERC721URIStorage, Ownable {
  ///@notice tự tăng id theo biến này
  using Counters for Counters.Counter;
  Counters.Counter private _tokenIdCounter;

  ///@notice từ tokenId -> địa chỉ người sở hữu
  mapping(uint256 => address) private _customOwners;

  ///@notice list để đẩy vào khi bán và remove khi mua
  uint256[] private publicStore;

  ///@notice nfts của 1 địa chỉ
  mapping(address => uint256[]) private _nfts;

  ///@notice giá tiền của nft
  mapping(uint256 => uint256) private _tokenIdToPrice;

  ///@notice loại tiền sử dụng để mua bán
  ///@dev có thể mở rộng thành 1 array để mua bán bằng nhiều loại tiền
  IERC20 private _token;

  ///@notice event khi bán nft
  event NftSelled(address _seller, uint256 _tokenId);

  ///@notice event khi mua nft
  event NftBought(address _from, address _to, uint256 _tokenId);

  ///@notice event khi thêm minter
  event MinterAdded(address indexed _minterAddr);

  ///@notice event khi xóa minter
  event MinterRemoved(address indexed _minterAddr);

  ///@notice check địa chỉ mà minter
  mapping(address => bool) public minter;

  ///@notice Check tokenId trong store hay không
  mapping(uint256 => bool) private _inStore;

  ///@notice list lưu lại các minter
  address[] private minterList;

  ///@notice throw exception khi msg.sender không phải minter
  modifier onlyMinter() {
    require(minter[msg.sender], "Only-minter");
    _;
  }

  ///@dev thêm khi địa chỉ không phải là minter
  function _addMinter(address _minterAddr) private onlyOwner {
    require(!minter[_minterAddr], "Is minter");
    minterList.push(_minterAddr);
    minter[_minterAddr] = true;
    emit MinterAdded(_minterAddr);
  }

  ///@notice thêm minter chỉ có người sở hữu mới có thể thêm
  function addMinter(address minterAddr) public onlyOwner {
    _addMinter(minterAddr);
  }

  ///@notice check minter
  function isMinter(address minterAddress) public view returns (bool) {
    return minter[minterAddress];
  }

  /// @return trả lại list minter
  function getMinters() public view returns (address[] memory) {
    return minterList;
  }

  function removeMinter(address _minterAddr) public onlyOwner {
    require(minter[_minterAddr], "Not minter");
    minter[_minterAddr] = false;
    // minterConsent[_minterAddr] = true;
    emit MinterRemoved(_minterAddr);

    uint256 i = 0;
    address _minter;
    while (i < minterList.length) {
      _minter = minterList[i];
      if (!minter[_minter]) {
        minterList[i] = minterList[minterList.length - 1];
        minterList.pop();
        break;
      } else {
        i++;
      }
    }
  }

  /***
  @notice set loại tiền mua bán nft và thêm người deploy là minter
  @param IERC20 token đầu vào là 1 địa chỉ
  */
  constructor(IERC20 token) ERC721("IVIRSENFT", "IFT") {
    _token = token;
    addMinter(msg.sender);
  }

  ///@notice tự tăng id khi mint, set quyền sở hữu của nft cho người mint.
  ///@dev uri là 1 đường dẫn ảnh hoặc 1 url get trả về dữ liệu của nft
  function safeMint(address to, string memory uri) public onlyMinter {
    uint256 tokenId = _tokenIdCounter.current();
    _tokenIdCounter.increment();
    _safeMint(to, tokenId);
    _setTokenURI(tokenId, uri);
    _customOwners[tokenId] = to;
    _addItem(tokenId, to);
    _inStore[tokenId] = false;
  }

  function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
    super._burn(tokenId);
  }

  function tokenURI(uint256 tokenId)
    public
    view
    override(ERC721, ERC721URIStorage)
    returns (string memory)
  {
    return super.tokenURI(tokenId);
  }

  ///@notice đổi loại token mua bán nft
  function setToken(IERC20 newToken) public onlyOwner {
    _token = newToken;
  }

  ///@return trả về list nft đang được bán
  function getPublicStore() public view returns (uint256[] memory) {
    return publicStore;
  }

  ///@dev thêm vào nft để bán
  function _addToStore(uint256 _tokenId) internal {
    publicStore.push(_tokenId);
  }

  ///@notice bán nft nếu là người sở hữu nft, giá tiền phải > 0 và nft chưa được bán
  function sellNft(uint256 tokenId, uint256 amount) public {
    require(msg.sender == _customOwners[tokenId], "Address is not owner");
    require(_inStore[tokenId], "Token had been sell");
    _addToStore(tokenId);
    _tokenIdToPrice[tokenId] = amount;
    _inStore[tokenId] = true;

    emit NftSelled(msg.sender, tokenId);
  }

  ///@notice mua nếu token được ủy quyển = giá của nft
  ///@dev giá của nft lấy trong _tokenIdToPrice được set giá khi mua
  function purchase(uint256 tokenId) public {
    require(!_inStore[tokenId], "Token had been bought");
    require(
      _token.allowance(msg.sender, address(this)) >= _tokenIdToPrice[tokenId],
      "Not enough token"
    );

    uint256 i = 0;
    uint256 removeId;
    uint256 storeLength = publicStore.length;
    while (i < storeLength) {
      removeId = publicStore[i];
      if (removeId == tokenId) {
        publicStore[i] = publicStore[storeLength - 1];
        publicStore.pop();
        address tokenOwner = _customOwners[tokenId];
        _token.transferFrom(msg.sender, tokenOwner, _tokenIdToPrice[tokenId]);
        _changeOwner(tokenId, tokenOwner, msg.sender);
        _inStore[tokenId] = false;
        emit NftBought(tokenOwner, msg.sender, tokenId);
        break;
      } else {
        i++;
      }
    }
  }

  ///@notice thay đổi nfts từ from sang to sửa customowner
  function _changeOwner(
    uint256 _tokenId,
    address _from,
    address _to
  ) internal {
    uint256[] storage listNft = _nfts[_from];
    uint256 nftLength = listNft.length;
    for (uint256 i = 0; i < nftLength; i++) {
      if (listNft[i] == _tokenId) {
        listNft[i] = listNft[nftLength - 1];
        _nfts[_from].pop();
        _addItem(_tokenId, _to);
        _customOwners[_tokenId] = _to;
        break;
      }
    }
  }

  ///@notice thêm token vào list khi truy suất theo điaj chỉa của mapping nfts
  function _addItem(uint256 _tokenId, address _address) internal {
    _nfts[_address].push(_tokenId);
  }

  ///@return lấy tokenId của địa chỉ
  function getNftOwners(address wallet) public view returns (uint256[] memory) {
    return _nfts[wallet];
  }

  ///@return lấy giá tiền của nft
  function getPrice(uint256 tokenId) public view returns (uint256) {
    return _tokenIdToPrice[tokenId];
  }

  ///@return lấy owner của nft
  function getOwnerById(uint256 tokenId) public view returns (address) {
    return _customOwners[tokenId];
  }
}
