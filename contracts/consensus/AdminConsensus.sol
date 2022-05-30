// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

/**
 *@author tuan.dq
 *@title smart contract for features admin consensus
 */

contract AdminConsensus is Pausable {
  /**
   *@dev Using safe math library for uint256.
   */
  using SafeMath for uint256;

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
    @dev struct for a participant.
   */
  struct Participant {
    address account;
    uint256 amount;
  }

  /***
    @dev Mapping from campaign to participants.
   */
  mapping(string => Participant[]) private _participants;

  /***
    @dev Set address token. Deployer is a admin.
   */
  constructor() {
    _addAdmin(msg.sender);
  }

  /**
   *@dev Throws if called by sender other than admin.
   */
  modifier onlyAdmin() {
    require(_isAdmin[msg.sender], "The sender is not admin!");
    _;
  }

  /**
   * @dev Throw if not more than half consensus.
   */
  modifier hasConsensus(bool isRevoke) {
    uint256 totalConsensus = 0;
    uint256 adminsLength = _admins.length;
    for (uint256 i = 0; i < adminsLength; i++) {
      if (adminConsent[_admins[i]]) {
        totalConsensus++;
      }
    }
    uint256 haftVote = adminsLength.div(2) + (!isRevoke ? 1 : 0);
    require(totalConsensus >= haftVote, "Not enough consensus!");
    _;
  }

  function addAdmin(address account) public onlyAdmin hasConsensus(false) {
    _addAdmin((account));
  }

  /**
   * @dev
   * The sender actively gives up admin rights.
   * Requirements:
   *
   * - `msg.sender` has admin role.
   *
   */

  function revokeAdminRole(address account)
    public
    onlyAdmin
    hasConsensus(true)
  {
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
    @dev Stop when an emergency occurs.
   */

  function pause() public onlyAdmin hasConsensus(false) {
    _pause();
    _resetConsensus();
  }

  /***
    @dev Continue to operate normally.
   */
  function unpause() public onlyAdmin hasConsensus(false) {
    _unpause();
    _resetConsensus();
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
    require(_isAdmin[_account], "Account is not a admin!");
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
}
