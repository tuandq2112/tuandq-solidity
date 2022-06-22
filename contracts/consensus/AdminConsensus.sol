// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";

/**
 *@author tuan.dq
 *@title smart contract for features admin consensus
 */

contract AdminConsensus {
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
  event AdminAcceptAdd(address indexed admin, address newAdmin);

  /***
    @dev  Emitted when `account` is rejected consent.
   */
  event AdminRejectAdd(address indexed admin, address newAdmin);

  /***
    @dev  Emitted when `account` is accepted consent.
   */
  event AdminAcceptRevoke(address indexed admin, address oldAdmin);

  /***
    @dev  Emitted when `account` is rejected consent.
   */
  event AdminRejectRevoke(address indexed admin, address oldAdmin);

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

  function addAdmin(address account) public onlyAdmin {
    adminConsentAccept[account][msg.sender] = true;
    emit AdminAcceptAdd(msg.sender, account);
    _checkAcceptConsensus(account);
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

  function revokeAdminRole(address account) public onlyAdmin {
    adminConsentReject[account][msg.sender] = true;
    emit AdminRejectRevoke(msg.sender, account);
    _checkRevokeConsensus(account);
    _removeAdmin(account);
    _resetRejectConsensus(account);
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
    _resetRejectConsensus(msg.sender);
  }

  /***
    @dev  Admin consent.
   */
  function adminAcceptAdd(address newAdmin) public onlyAdmin {
    adminConsentAccept[newAdmin][msg.sender] = true;
    emit AdminAcceptAdd(msg.sender, newAdmin);
  }

  /***
    @dev  Admin reject.
   */
  function adminRejectAdd(address newAdmin) public onlyAdmin {
    adminConsentAccept[newAdmin][msg.sender] = true;
    emit AdminRejectAdd(msg.sender, newAdmin);
  }

  /***
    @dev  Admin consent.
   */
  function adminAcceptRevoke(address oldAdmin) public onlyAdmin {
    adminConsentReject[oldAdmin][msg.sender] = true;
    emit AdminAcceptRevoke(msg.sender, oldAdmin);
  }

  /***
    @dev  Admin reject.
   */
  function adminRejectRevoke(address oldAdmin) public onlyAdmin {
    adminConsentReject[oldAdmin][msg.sender] = true;
    emit AdminRejectRevoke(msg.sender, oldAdmin);
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
    _resetAcceptConsensus(_account);
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

  function _checkAcceptConsensus(address _newAdmin) public view {
    uint64 totalConsensus = 0;
    uint256 adminsLength = _admins.length;
    for (uint256 i = 0; i < adminsLength; i++) {
      if (adminConsentAccept[_newAdmin][_admins[i]]) {
        totalConsensus++;
      }
    }
    require(totalConsensus * 2 > adminsLength, "Not enough consensus!");
  }

  function _checkRevokeConsensus(address _oldAdmin) public view {
    uint64 totalConsensus = 0;
    uint256 adminsLength = _admins.length;
    for (uint256 i = 0; i < adminsLength; i++) {
      if (adminConsentReject[_oldAdmin][_admins[i]]) {
        totalConsensus++;
      }
    }
    require(totalConsensus * 2 > adminsLength - 1, "Not enough consensus!");
  }
}
