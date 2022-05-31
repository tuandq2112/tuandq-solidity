// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/**
 *@author tuan.dq
 *@title Smart contract for campaigns
 */

contract CampaignManagement is Pausable {
  /**
   *@dev Using safe math library for uin256
   */
  using SafeMath for uint256;

  /**
   *@dev Using safe math library for uin256
   */
  using SafeERC20 for IERC20;

  /***
    @dev ERC20 token for this smart contract
   */
  IERC20 private _token;
  /***
    @notice Variables and events for admin
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
    @notice Variables and events for management campaign.
   */

  /***
    @dev  Emitted when `ADMIN` create campaign.
   */
  event CreateCampaign(
    string campaignName,
    address[] accounts,
    uint256[] amounts
  );

  /***
    @dev  Emitted when `ADMIN` release token.
   */
  event Release(string campaignName);
  /***
    @dev struct for a participant.
   */
  struct Participant {
    address account;
    uint256 amount;
    bool passive;
  }

  /***
    @dev array save all campaign name.
   */
  string[] public campaigns;

  /***
    @dev Mapping from campaign to participants.
   */
  mapping(string => Participant[]) private participants;

  /***
    @dev Mapping from address to participant or not.
   */
  mapping(address => bool) public isParticipant;

  /***
    @dev mapping from campaign to claimed.
   */
  mapping(string => bool) public isClaimed;

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

  /***
     @dev 
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
   *@dev Create campaign
   */
  function createCampaign(
    string memory campaignName,
    address[] memory accounts,
    uint256[] memory amounts,
    bool[] memory listPassive
  ) public onlyAdmin whenNotPaused {
    _createCampaign(campaignName, accounts, amounts, listPassive);
  }

  /**
   *@dev Create campaign
   */
  function release(string memory campaignName) public onlyAdmin whenNotPaused {
    require(!isClaimed[campaignName], "Campaign ended!");
    Participant[] memory listParticipant = participants[campaignName];
    for (uint256 i = 0; i < listParticipant.length; i++) {
      Participant memory participant = listParticipant[i];
      if (participant.passive) {
        _token.safeTransfer(participant.account, participant.amount);
      } else {
        _token.safeIncreaseAllowance(participant.account, participant.amount);
      }
    }
    isClaimed[campaignName] = true;
    emit Release(campaignName);
  }

  /**
   *@dev
   * Validate input.
   * Requirements:
   *
   * - `campaignName` must not exist.
   * - `_accounts.length` equal `_amounts.length`.
   *
   */

  function _validateCampaign(
    string memory _campaignName,
    address[] memory _accounts,
    uint256[] memory _amounts,
    bool[] memory _listPassive
  ) private view {
    bool isNotExist = participants[_campaignName].length == 0;
    uint256 numberOfAccount = _accounts.length;
    uint256 numberOfAmount = _amounts.length;
    uint256 numberOfPassive = _listPassive.length;

    require(isNotExist, "Can't set this time!");

    require(
      numberOfAccount > 0 && numberOfAmount > 0 && numberOfPassive > 0,
      "Amounts, accounts and list passive can't be zero!"
    );
    require(
      numberOfAccount == numberOfAmount && numberOfAmount == numberOfPassive,
      "Amounts and accounts not match!"
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
     * - `_account` is a admin
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

  /**
   *@dev Set a list of participant to a time and set this participant is true.
   */
  function _createCampaign(
    string memory _campaignName,
    address[] memory _accounts,
    uint256[] memory _amounts,
    bool[] memory _listPassive
  ) private {
    _validateCampaign(_campaignName, _accounts, _amounts, _listPassive);
    uint256 numberOfInvestor = _accounts.length;
    Participant[] storage listParticipant = participants[_campaignName];
    for (uint256 i = 0; i < numberOfInvestor; i++) {
      listParticipant.push(
        Participant(_accounts[i], _amounts[i], _listPassive[i])
      );
      isParticipant[_accounts[i]] = true;
    }
    campaigns.push(_campaignName);
    emit CreateCampaign(_campaignName, _accounts, _amounts);
  }
}
