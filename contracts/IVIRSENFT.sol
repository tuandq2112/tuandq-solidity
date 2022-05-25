// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

/**
 *@author tuandq
 *@title this smart contract as a marketplace. Users can buy and sell nft by IVI tokens.
 */
contract IVIRSENFT is ERC721, ERC721URIStorage, Ownable {
  ///@notice tự tăng id theo biến này
  using Counters for Counters.Counter;
  Counters.Counter private _tokenIdCounter;
  using SafeMath for uint256;

  enum RANKING {
    S,
    A,
    B,
    C,
    D
  }
  struct Pokemon {
    RANKING rank;
    uint256 attack;
    uint256 def;
    uint256 hp;
    string uri;
    bool isCreep;
  }
  Pokemon[] private _creeps;
  mapping(uint256 => Pokemon) private _pokemons;
  mapping(address => uint256) private _defenders;

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

  mapping(address => uint256) private _coolDownGetCreep;

  mapping(address => uint256) private _coolDownAttack;

  mapping(address => bool) private _isRegister;

  mapping(address => Pokemon) private _addressToCreep;

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
  function safeMint(
    address to,
    string memory uri,
    uint256 attack,
    uint256 defense
  ) public onlyMinter {
    _safeMint(to, uri, attack, defense, 0, false);
  }

  function addCreep(
    uint256 attack,
    uint256 defense,
    uint256 hp,
    string memory uri
  ) public onlyOwner {
    RANKING rank = _getRanking(attack, defense);
    _creeps.push(Pokemon(rank, attack, defense, hp, uri, true));
  }

  ///@notice tự tăng id khi mint, set quyền sở hữu của nft cho người mint.
  ///@dev uri là 1 đường dẫn ảnh hoặc 1 url get trả về dữ liệu của nft
  function _safeMint(
    address _to,
    string memory _uri,
    uint256 _attack,
    uint256 _defense,
    uint256 _hp,
    bool _isCreep
  ) private {
    uint256 tokenId = _tokenIdCounter.current();
    _tokenIdCounter.increment();
    _safeMint(_to, tokenId);
    _setTokenURI(tokenId, _uri);
    _customOwners[tokenId] = _to;
    _addItem(tokenId, _to);
    _inStore[tokenId] = false;
    RANKING rank = _getRanking(_attack, _defense);
    _pokemons[tokenId] = Pokemon(rank, _attack, _defense, _hp, "", _isCreep);
  }

  function _getRanking(uint256 _attack, uint256 _defense)
    private
    pure
    returns (RANKING)
  {
    uint256 totalPoint = _attack + _defense;
    if (totalPoint >= 8000) {
      return RANKING.S;
    } else if (totalPoint >= 6000 && totalPoint < 8000) {
      return RANKING.A;
    } else if (totalPoint >= 4000 && totalPoint < 6000) {
      return RANKING.B;
    } else if (totalPoint >= 2000 && totalPoint < 4000) {
      return RANKING.C;
    }
    return RANKING.D;
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

  // function setDefender(uint256 tokenId) public {
  //   require(_customOwners[tokenId] == msg.sender, "Sender must be the owner");
  //   _defenders[msg.sender] = tokenId;
  // }

  // function attackCreep(uint256 tokenId) public {
  //   // require(_defenders[enemy] > 0, "Your enemy doesn't have a defender yet!");
  //   require(_customOwners[tokenId] == msg.sender, "Sender must be the owner");
  //   Pokemon storage creep = _addressToCreep[msg.sender];
  //   Pokemon memory pokemon = _pokemons[tokenId];
  //   require(creep.hp > 0, "Monster deaded");
  //   if (creep.hp >= pokemon.attack) {
  //     creep.hp = creep.hp.sub(pokemon.attack);
  //   } else {
  //     creep.hp = 0;
  //   }
  // }

  // function getPokemon(uint256 tokenId) public view returns (Pokemon memory) {
  //   return _pokemons[tokenId];
  // }

  // function getCreep() public view returns (Pokemon memory) {
  //   return _addressToCreep[msg.sender];
  // }

  // function getRandomCreep() public {
  //   require(
  //     block.timestamp >= _coolDownGetCreep[msg.sender],
  //     "It's not time to shoot yet"
  //   );

  //   require(
  //     _addressToCreep[msg.sender].hp == 0,
  //     "the player needs to destroy the current monster"
  //   );
  //   uint256 modulo = _creeps.length - 1;
  //   _addressToCreep[msg.sender] = _creeps[
  //     modulo == 0 ? 0 : getRandomUint(modulo)
  //   ];
  // }

  // function register(string memory uri) public {
  //   address to = msg.sender;
  //   require(!_isRegister[to], "Sender was register");
  //   uint256 randomAtk = getRandomUint(1000);
  //   uint256 randomDef = getRandomUint(1000);
  //   _isRegister[to] = true;
  //   _coolDownGetCreep[to] = block.timestamp;
  //   _coolDownAttack[to] = block.timestamp;
  //   _isRegister[to] = true;
  //   _safeMint(to, uri, randomAtk, randomDef, 0, false);
  // }

  // function getRandomUint(uint256 modulo) public view returns (uint256) {
  //   return
  //     uint256(keccak256(abi.encodePacked(block.timestamp + block.difficulty))) %
  //     modulo;
  // }

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
