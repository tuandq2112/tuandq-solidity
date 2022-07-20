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
  mapping(address => mapping(address => ConsentStatus)) public adminConsents;

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

  modifier notAdmin(address account) {
    require(!isAdmin[account], "Account was a admin!");
    _;
  }

  modifier hasRoleAdmin(address account) {
    require(isAdmin[account], "Account was a admin!");
    _;
  }

  modifier confirmed(address account) {
    require(
      adminConsents[account][msg.sender] != ConsentStatus.Reject,
      "Account not already confirmed !"
    );
    _;
  }
  modifier notConfirmed(address account) {
    require(
      adminConsents[account][msg.sender] != ConsentStatus.Accept,
      "Account already confirmed !"
    );
    _;
  }

  modifier enoughAcceptConsensus(address account) {
    uint256 totalConsensus = _getAdminConsensusByAddressAndStatus(
      account,
      ConsentStatus.Accept
    );
    uint256 adminsLength = _admins.length;
    require(totalConsensus * 2 > adminsLength, "Not enough consensus!");
    _;
    _resetConsensus(account);
  }

  modifier enoughRevokeConsensus(address account) {
    uint256 totalConsensus = _getAdminConsensusByAddressAndStatus(
      account,
      ConsentStatus.Reject
    );
    uint256 adminsLength = _admins.length;
    require(totalConsensus * 2 > adminsLength - 1, "Not enough consensus!");
    _;
    _resetConsensus(account);
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
    hasRoleAdmin(account)
  {
    _revokeAdminRole(account);
  }

  /***
    @dev  Admin consent.
   */
  function adminAccept(address account)
    public
    override
    onlyAdmin
    notConfirmed(account)
  {
    _adminAccept(account);
  }

  /***
    @dev  Admin reject.
   */
  function adminReject(address account)
    public
    override
    onlyAdmin
    confirmed(account)
  {
    _adminReject(account);
  }

  function getAdminConsensusByAddressAndStatus(
    address account,
    ConsentStatus status
  ) public view override returns (uint256) {
    return _getAdminConsensusByAddressAndStatus(account, status);
  }

  function getAdmins() public view override returns (address[] memory) {
    return _admins;
  }

  /**
   *@dev set all admin consent is false.
   */
  function _resetConsensus(address persion) private {
    for (uint256 i = 0; i < _admins.length; i++) {
      adminConsents[persion][_admins[i]] = ConsentStatus.NoAction;
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
    _resetConsensus(msg.sender);
  }

  /***
    @dev  Admin consent.
   */
  function _adminAccept(address _account) private {
    adminConsents[_account][msg.sender] = ConsentStatus.Accept;
    emit AdminAccept(msg.sender, _account);
  }

  /***
    @dev  Admin reject.
   */
  function _adminReject(address _account) private {
    adminConsents[_account][msg.sender] = ConsentStatus.Reject;
    emit AdminReject(msg.sender, _account);
  }

  function _getAdminConsensusByAddressAndStatus(
    address _account,
    ConsentStatus _status
  ) private view returns (uint256 totalConsensus) {
    uint256 adminsLength = _admins.length;

    for (uint256 i = 0; i < adminsLength; i++) {
      if (adminConsents[_account][_admins[i]] == _status) {
        totalConsensus++;
      }
    }
    return totalConsensus;
  }
}
