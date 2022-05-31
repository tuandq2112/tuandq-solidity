// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./consensus/AdminConsensus.sol";

/**
 *@author tuan.dq
 *@title Smart contract for campaigns
 */

contract CampaignManagement is AdminConsensus {
  /**
   *@dev struct for a participant.
   */
  struct Participant {
    address account;
    uint256 amount;
    bool passive;
  }

  /**
   *@dev Using safe math library for uin256
   */
  using SafeMath for uint256;

  /**
   *@dev Using safe math library for uin256
   */
  using SafeERC20 for IERC20;

  /**
   *  @dev ERC20 token for this smart contract
   */
  IERC20 private _token;

  /**
   *  @dev  Emitted when `ADMIN` create campaign.
   */
  event CreateCampaign(
    string campaignName,
    address[] accounts,
    uint256[] amounts
  );

  /**
   *  @dev  Emitted when `account` is accepted consent.
   */
  event AdminAcceptRelease(address indexed account, string indexed campaign);

  /**
   *  @dev  Emitted when `account` is rejected consent.
   */
  event AdminRejectRelease(address indexed account, string indexed campaign);

  /**
   *  @dev  Emitted when `ADMIN` release token.
   */
  event Release(string campaignName);

  /**
   *  @dev array save all campaign name.
   */
  string[] public campaigns;

  /**
   *  @dev Mapping from campaign to participants.
   */
  mapping(string => Participant[]) private participants;

  /**
   *  @dev mapping from campaign to claimed.
   */
  mapping(string => bool) public isClaimed;

  /**
   *  @dev Mapping from campaign to participants.
   */
  mapping(string => mapping(address => bool)) private _adminConsents;

  /**
   *  @dev Mapping from address to participant or not.
   */
  mapping(address => bool) public isParticipant;

  /**
   *  @dev Set address token. Deployer is a admin.
   */
  constructor(IERC20 token_) {
    _token = token_;
  }

  /**
   *@dev Create campaign
   */
  function createCampaign(
    string memory campaignName,
    address[] memory accounts,
    uint256[] memory amounts,
    bool[] memory listPassive
  ) public onlyAdmin {
    _createCampaign(campaignName, accounts, amounts, listPassive);
  }

  /**
   *  @dev  Admin accept for campaign release token.
   */
  function adminAcceptRelease(string memory campaign) public onlyAdmin {
    _adminConsents[campaign][msg.sender] = true;
    emit AdminAcceptRelease(msg.sender, campaign);
  }

  /**
   *  @dev  Admin reject for campaign release token.
   */
  function adminRejectRelease(string memory campaign) public onlyAdmin {
    _adminConsents[campaign][msg.sender] = false;
    emit AdminRejectRelease(msg.sender, campaign);
  }

  function _checkConsensus(string memory _name) private view {
    uint256 totalCampaignConsensus = 0;
    uint256 adminsLength = _admins.length;
    for (uint256 i = 0; i < adminsLength; i++) {
      if (_adminConsents[_name][_admins[i]]) {
        totalCampaignConsensus++;
      }
    }
    uint256 haftVote = adminsLength.div(2) + 1;
    require(totalCampaignConsensus >= haftVote, "Not enough consensus!");
  }

  /**
   *@dev Create campaign
   */
  function release(string memory campaignName) public onlyAdmin {
    require(!isClaimed[campaignName], "Campaign ended!");
    _checkConsensus(campaignName);
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
