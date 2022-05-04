// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract IVIRSENFT is ERC721, ERC721URIStorage, Ownable {
  using Counters for Counters.Counter;
  Counters.Counter private _tokenIdCounter;

  mapping(uint256 => address) private _customOwners;
  uint256[] private publicStore;
  mapping(address => uint256[]) private _nfts;
  mapping(uint256 => uint256) private _tokenIdToPrice;
  IERC20 private _token;
  // event SellNft(address _from, uint256 _tokenId);
  event NftEvent(address _from, address _to, uint256 _tokenId);

  event MinterAdded(address indexed _minterAddr);
  event MinterRemoved(address indexed _minterAddr);

  mapping(address => bool) public minter;
  address[] private minterList;

  /**
   * @dev Throws if called by any account other than the minter.
   */
  modifier onlyMinter() {
    require(minter[msg.sender], "Only-minter");
    _;
  }

  function _addMinter(address _minterAddr) private onlyOwner {
    require(!minter[_minterAddr], "Is minter");
    minterList.push(_minterAddr);
    minter[_minterAddr] = true;
    emit MinterAdded(_minterAddr);
  }

  function addMinter(address minterAddr) public onlyOwner {
    _addMinter(minterAddr);
  }

  function getMinters() public view returns (address[] memory) {
    return minterList;
  }

  constructor(IERC20 token) ERC721("IVIRSENFT", "IFT") {
    _token = token;
    addMinter(msg.sender);
  }

  function safeMint(address to, string memory uri) public onlyMinter {
    uint256 tokenId = _tokenIdCounter.current();
    _tokenIdCounter.increment();
    _safeMint(to, tokenId);
    _setTokenURI(tokenId, uri);
    _customOwners[tokenId] = to;
    _addItem(tokenId, to);
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

  //set another token
  function setToken(IERC20 newToken) public onlyOwner {
    _token = newToken;
  }

  //get nfts can buy
  function getPublicStore() public view returns (uint256[] memory) {
    return publicStore;
  }

  //mint -> _customOwners -> publicStore
  function _addItem(uint256 _tokenId) internal {
    publicStore.push(_tokenId);
  }

  //inside public store
  function _isInStore(uint256 _tokenId) private view returns (bool) {
    for (uint256 i = 0; i < publicStore.length; i++) {
      if (publicStore[i] == _tokenId) {
        return true;
      }
    }
    return false;
  }

  function sellNft(uint256 tokenId, uint256 amount) public {
    require(msg.sender == _customOwners[tokenId], "Address is not owner");
    require(!_isInStore(tokenId), "Token had been bought");
    require(amount > 0, "Amount invalid");

    _addItem(tokenId);
    _tokenIdToPrice[tokenId] = amount;
    emit NftEvent(msg.sender, msg.sender, tokenId);
  }

  function purchase(uint256 tokenId) public {
    require(_isInStore(tokenId), "Token had been bought");
    require(
      _token.allowance(msg.sender, address(this)) >= _tokenIdToPrice[tokenId],
      "Not enough eth"
    );
    for (uint256 i = 0; i < publicStore.length; i++) {
      if (publicStore[i] == tokenId) {
        publicStore[i] = publicStore[publicStore.length - 1];
        publicStore.pop();
        address tokenOwner = _customOwners[tokenId];
        _token.transferFrom(msg.sender, tokenOwner, _tokenIdToPrice[tokenId]);
        _changeOwner(tokenId, tokenOwner, msg.sender);
        emit NftEvent(tokenOwner, msg.sender, tokenId);
        tokenOwner = msg.sender;
        break;
      }
    }
  }

  function _changeOwner(
    uint256 _tokenId,
    address _from,
    address _to
  ) internal {
    for (uint256 i = 0; i < _nfts[_from].length; i++) {
      if (_nfts[_from][i] == _tokenId) {
        _nfts[_from][i] = _nfts[_from][_nfts[_from].length - 1];
        _nfts[_from].pop();
        _nfts[_from] = _nfts[_from];
        _addItem(_tokenId, _to);
        _customOwners[_tokenId] = _to;
        break;
      }
    }
  }

  function _addItem(uint256 _tokenId, address _address) internal {
    _nfts[_address].push(_tokenId);
  }

  function getNftOwners(address wallet) public view returns (uint256[] memory) {
    return _nfts[wallet];
  }

  function getPrice(uint256 tokenId) public view returns (uint256) {
    return _tokenIdToPrice[tokenId];
  }

  function getOwnerById(uint256 tokenId) public view returns (address) {
    return _customOwners[tokenId];
  }
}
