// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./IAdminConsensus.sol";

/**
 *@author tuan.dq
 *@title smart contract for features admin consensus
 */

contract AdminConsensus is IAdminConsensus {
  /**
   *@dev Using safe math library for uint256.
   */
  using SafeMath for uint256;

  /**
   *  @dev Variables for admin
   */
  /***
 
  /***
    @dev array save all admin address.
   */
  address[] internal _admins;

  /***
    @dev Mapping from address to admin or not.
   */
  mapping(address => bool) public isAdmin;

  /***
    @dev Mapping from address to admin consent or not.
   */
  mapping(address => mapping(address => bool)) public adminConsentAccept;

  /***
    @dev Mapping from address to admin consent or not.
   */
  mapping(address => mapping(address => bool)) public adminConsentReject;

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
    require(isAdmin[msg.sender], "The sender is not admin!");
    _;
  }

  // modifier isAdmin(address account) {
  //   require(isAdmin[account], "Account is not a admin!");
  //   _;
  // }

  modifier notAdmin(address account) {
    require(!isAdmin[account], "Account was a admin!");
    _;
  }

  modifier confirmedAdd(address account) {
    require(
      adminConsentAccept[account][msg.sender],
      "Account not already confirmed add!"
    );
    _;
  }
  modifier notConfirmedAdd(address account) {
    require(
      !adminConsentAccept[account][msg.sender],
      "Account already confirmed add!"
    );
    _;
  }
  modifier confirmedRevoke(address account) {
    require(
      adminConsentReject[account][msg.sender],
      "Account not already confirmed revoke!"
    );
    _;
  }
  modifier notConfirmedRevoke(address account) {
    require(
      !adminConsentReject[account][msg.sender],
      "Account already confirmed revoke!"
    );
    _;
  }

  modifier enoughAcceptConsensus(address account) {
    _adminAcceptAdd(account);
    uint64 totalConsensus = 0;
    uint256 adminsLength = _admins.length;
    for (uint256 i = 0; i < adminsLength; i++) {
      if (adminConsentAccept[account][_admins[i]]) {
        totalConsensus++;
      }
    }
    require(totalConsensus * 2 > adminsLength, "Not enough consensus!");
    _;
    _resetAcceptConsensus(account);
  }

  modifier enoughRevokeConsensus(address account) {
    _adminAcceptRevoke(account);
    uint64 totalConsensus = 0;
    uint256 adminsLength = _admins.length;
    for (uint256 i = 0; i < adminsLength; i++) {
      if (adminConsentReject[account][_admins[i]]) {
        totalConsensus++;
      }
    }
    require(totalConsensus * 2 > adminsLength - 1, "Not enough consensus!");
    _;
    _resetRejectConsensus(account);
  }

  function addAdmin(address account)
    public
    override
    onlyAdmin
    enoughAcceptConsensus(account)
  {
    _addAdmin((account));
  }

  /**
   *   @dev
   * The sender actively gives up admin rights.
   * Requirements:
   *
   * - `msg.sender` has admin role.
   *
   */

  function renounceAdminRole() public override onlyAdmin {
    _renounceAdminRole();
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
    override
    onlyAdmin
    enoughRevokeConsensus(account)
  {
    _revokeAdminRole(account);
  }

  /***
    @dev  Admin consent.
   */
  function adminAcceptAdd(address account)
    public
    override
    onlyAdmin
    notConfirmedAdd(account)
  {
    _adminAcceptAdd(account);
  }

  /***
    @dev  Admin reject.
   */
  function adminRejectAdd(address account)
    public
    override
    onlyAdmin
    confirmedAdd(account)
  {
    _adminRejectAdd(account);
  }

  /***
    @dev  Admin consent.
   */
  function adminAcceptRevoke(address account)
    public
    override
    onlyAdmin
    notConfirmedRevoke(account)
  {
    _adminAcceptRevoke(account);
  }

  /***
    @dev  Admin reject.
   */
  function adminRejectRevoke(address account)
    public
    override
    onlyAdmin
    confirmedRevoke(account)
  {
    _adminRejectRevoke(account);
  }

  /**
   *@dev set all admin consent is false.
   */
  function _resetAcceptConsensus(address persion) private {
    for (uint256 i = 0; i < _admins.length; i++) {
      adminConsentAccept[persion][_admins[i]] = false;
    }
  }

  function _resetRejectConsensus(address persion) private {
    for (uint256 i = 0; i < _admins.length; i++) {
      adminConsentReject[persion][_admins[i]] = false;
    }
  }

  /**
   *@dev push account to list admin and set account is a admin
   */
  function _addAdmin(address _account) private {
    _admins.push(_account);
    isAdmin[_account] = true;
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
    require(isAdmin[_account], "Account is not a admin!");
    require(adminsLength > 1, "You are last administrator!");
    for (uint256 i = 0; i < adminsLength; i++) {
      if (_admins[i] == _account) {
        _admins[i] = _admins[adminsLength - 1];
        _admins.pop();
        isAdmin[_account] = false;
        break;
      }
    }
    emit RemoveAdmin(msg.sender, _account);
  }

  function _revokeAdminRole(address _account) private {
    _removeAdmin(_account);
  }

  function _renounceAdminRole() private {
    _removeAdmin(msg.sender);
    _resetRejectConsensus(msg.sender);
  }

  /***
    @dev  Admin consent.
   */
  function _adminAcceptAdd(address _account) private {
    adminConsentAccept[_account][msg.sender] = true;
    emit AdminAcceptAdd(msg.sender, _account);
  }

  /***
    @dev  Admin reject.
   */
  function _adminRejectAdd(address _account) private {
    adminConsentAccept[_account][msg.sender] = false;
    emit AdminRejectAdd(msg.sender, _account);
  }

  /***
    @dev  Admin consent.
   */
  function _adminAcceptRevoke(address _account) private {
    adminConsentReject[_account][msg.sender] = true;
    emit AdminAcceptRevoke(msg.sender, _account);
  }

  /***
    @dev  Admin reject.
   */
  function _adminRejectRevoke(address _account) private {
    adminConsentReject[_account][msg.sender] = false;
    emit AdminRejectRevoke(msg.sender, _account);
  }

  function getAdmins() public view returns (address[] memory) {
    return _admins;
  }
}
