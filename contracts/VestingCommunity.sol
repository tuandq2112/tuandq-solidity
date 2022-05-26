// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

contract VestingCommunity is Pausable {
  /***
    @dev ERC20 token for this smart contract
   */
  IERC20 private _token;
  /***
    @dev Variables and events for admin
   */

  /***
    @dev  Emitted when has new `ADMIN`.
   */
  event AddAdmin(address indexed performer, address indexed newAdmin);

  /***
    @dev  Emitted when remove a `ADMIN`.
   */
  event RemoveAdmin(address indexed performer, address indexed adminRemoved);
  /***
    @dev  Emitted when `account` is accepted consent.
   */
  event AdminAccept(address indexed account);

  /***
    @dev  Emitted when `account` is rejected consent.
   */
  event AdminReject(address indexed account);

  /***
    @dev  Emitted when `ADMIN` added investors.
   */
  event AddInvestors(
    address[] accounts,
    uint256[] amounts,
    uint256 indexed claimTime
  );

  /***
    @dev array save all admin address.
   */
  address[] private _admins;

  /***
    @dev Mapping from address to admin or not.
   */
  mapping(address => bool) private _isAdmin;

  /***
    @dev Mapping from address to admin consent or not.
   */
  mapping(address => bool) public adminConsent;

  /***
    @dev Variables and events for claim token.
   */
  event ClaimToken(uint256 indexed claimTime, uint256 indexed index);

  /***
    @dev struct for a investor.
   */
  struct Investor {
    address account;
    uint256 amount;
    bool isClaimed;
  }

  /***
    @dev Mapping from time to list investor.
   */
  mapping(uint256 => Investor[]) private _investors;

  /***
    @dev Mapping from `address` to investor or not.
   */
  mapping(address => bool) private _isInvestor;

  /***
    @dev Save list of all timelines .
   */
  uint256[] private _times;

  /***
    @dev Set address token. Deployer is a admin.
   */
  constructor(IERC20 token_) {
    _token = token_;
    _addAdmin(msg.sender);
  }

  /***
    @dev Throws if called by sender other than admin.
   */
  modifier onlyAdmin() {
    require(_isAdmin[msg.sender], "The sender is not admin!");
    _;
  }

  /***
    @dev Throws if called by sender other than admin.
   */
  modifier allAdminsConsensus() {
    for (uint256 i = 0; i < _admins.length; i++) {
      require(adminConsent[_admins[i]], "At least one admin has not accepted");
    }
    _;
  }

  function addAdmin(address account) public onlyAdmin allAdminsConsensus {
    _addAdmin((account));
  }

  /***
     @dev 
     * The sender actively gives up admin rights.
     * Requirements:
     *
     * - `msg.sender` has admin role.
     *
   */

  function revokeAdminRole(address account) public onlyAdmin {
    uint256 numberOfVotes = 0;
    for (uint256 i = 0; i < _admins.length; i++) {
      if (adminConsent[_admins[i]]) {
        numberOfVotes++;
      }
    }
    require(
      numberOfVotes + 1 >= _admins.length,
      "Need approval from all admins except the one removed"
    );
    _removeAdmin(account);
    _resetConsensus();
  }

  /***
     @dev 
     * The sender actively gives up admin rights.
     * Requirements:
     *
     * - `msg.sender` has admin role.
     *
   */

  function renounceAdminRole() public onlyAdmin {
    _removeAdmin(msg.sender);
  }

  /***
    @dev  Admin consent.
   */
  function adminAccept() public onlyAdmin {
    adminConsent[msg.sender] = true;
    emit AdminAccept(msg.sender);
  }

  /***
    @dev  Admin reject.
   */
  function adminReject() public onlyAdmin {
    adminConsent[msg.sender] = false;
    emit AdminReject(msg.sender);
  }

  /***
    @dev Add accounts for claim token.
   */
  function addAccounts(
    address[] memory accounts,
    uint256[] memory amounts,
    uint256 claimTime
  ) public whenNotPaused onlyAdmin {
    _addAccounts(accounts, amounts, claimTime);
  }

  /***
    @dev Stop when an emergency occurs.
   */

  function pause() public onlyAdmin allAdminsConsensus {
    _pause();
    _resetConsensus();
  }

  /***
    @dev Continue to operate normally.
   */
  function unpause() public onlyAdmin allAdminsConsensus {
    _unpause();
    _resetConsensus();
  }

  /***
     @dev 
     * `ERC20` transfer token to sender and change status `isClaimed`.
     * Requirements:
     *
     * - `claimTIme` must not exist.
     *
     * Emits a {ClaimToken} event.
   */
  function claimToken(uint256 claimTime, uint256 index) public whenNotPaused {
    _checkOwner(claimTime, index);
    address sender = msg.sender;
    Investor storage investor = _investors[claimTime][index];
    _token.transfer(sender, investor.amount);
    investor.isClaimed = true;
    emit ClaimToken(claimTime, index);
  }

  /***
    @dev Calculate total amount
   */
  function _reduce(uint256[] memory _amounts) private pure returns (uint256) {
    uint256 arrLength = _amounts.length;
    uint256 totalAmount = 0;
    for (uint256 i = 0; i < arrLength; i++) {
      totalAmount += _amounts[i];
    }
    return totalAmount;
  }

  /***
     @dev 
     * Validate input.
     * Requirements:
     *
     * - `claimTIme` must not exist.
     * - `_accounts.length` equal `_amounts.length`.
     * - `totalAmount` less or equal than balance of this address.
     *
   */
  function _validateInput(
    address[] memory _accounts,
    uint256[] memory _amounts,
    uint256 _claimTime
  ) private view {
    bool isNotExist = _investors[_claimTime].length == 0;
    uint256 numberOfAccount = _accounts.length;
    uint256 numberOfAmount = _amounts.length;
    uint256 totalAmount = _reduce(_amounts);

    require(isNotExist, "Can't set this time!");

    require(
      numberOfAccount > 0 && numberOfAmount > 0,
      "Amounts and accounts can't be zero!"
    );
    require(
      numberOfAccount == numberOfAmount,
      "Amounts and accounts not match!"
    );
    require(
      _token.balanceOf(address(this)) >= totalAmount,
      "Token quantity exceeded limit!"
    );
  }

  /**
   *@dev set all admin consent is false.
   */
  function _resetConsensus() private {
    for (uint256 i = 0; i < _admins.length; i++) {
      adminConsent[_admins[i]] = false;
    }
  }

  /**
   *@dev push account to list admin and set account is a admin
   */
  function _addAdmin(address _account) private {
    _admins.push(_account);
    _isAdmin[_account] = true;
    _resetConsensus();
    emit AddAdmin(msg.sender, _account);
  }

  /***
     @dev 
     * Remove _account from _admins. set `isAdmin` of account is false.
     * Requirements:
     *
     * - `adminsLength` is greater than or equal to 1.
     * - `_accounts.length` equal `_amounts.length`.
     * - `totalAmount` less or equal than balance of this address.
     *
     * Emits a {RemoveAdmin} event.
     *
   */
  function _removeAdmin(address _account) private {
    uint256 adminsLength = _admins.length;
    require(adminsLength > 1, "You are last administrator!");
    for (uint256 i = 0; i < adminsLength - 1; i++) {
      if (_admins[i] == _account) {
        _admins[i] = _admins[adminsLength - 1];
        _admins.pop();
        _isAdmin[_account] = false;
        emit RemoveAdmin(msg.sender, _account);
      }
    }
  }

  /**
   *@dev remove account from list admin and set account's admin role is false.
   */

  /**
   *@dev Set a list of investor to a time and set this investor is true.
   */
  function _addAccounts(
    address[] memory _accounts,
    uint256[] memory _amounts,
    uint256 _claimTime
  ) private {
    _validateInput(_accounts, _amounts, _claimTime);
    uint256 numberOfInvestor = _accounts.length;
    Investor[] storage listInvestor = _investors[_claimTime];
    for (uint256 i = 0; i < numberOfInvestor; i++) {
      listInvestor.push(Investor(_accounts[i], _amounts[i], false));
      _isInvestor[_accounts[i]] = true;
    }
    _times.push(_claimTime);
    emit AddInvestors(_accounts, _amounts, _claimTime);
  }

  function _checkOwner(uint256 _claimTime, uint256 _index) private view {
    address sender = msg.sender;
    require(
      _investors[_claimTime].length >= _index + 1,
      "Index out of bounds!"
    );
    Investor memory investor = _investors[_claimTime][_index];
    require(sender == investor.account, "Sender not match!");
    require(!investor.isClaimed, "Sender claimed token");
    require(block.timestamp >= _claimTime, "It is not time yet");
  }

  function getTimes() public view returns (uint256[] memory) {
    return _times;
  }

  function getInvestors(uint256 claimTime)
    public
    view
    returns (Investor[] memory)
  {
    return _investors[claimTime];
  }

  function getAdmins() public view returns (address[] memory) {
    return _admins;
  }

  function isAdmin() public view returns (bool) {
    return _isAdmin[msg.sender];
  }
}
