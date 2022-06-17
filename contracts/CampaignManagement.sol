// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./consensus/AdminConsensus.sol";
import "./ICampaignManagement.sol";

/**
 *@author tuan.dq
 *@title Smart contract for campaigns
 */

contract CampaignManagement is ICampaignManagement, AdminConsensus {
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
   *  @dev array save all campaign name.
   */
  string[] private _campaignNames;

  /**
   *@dev data by times
   */
  DataByTime[] private _datas;

  /**
   *  @dev Mapping from campaign to participants.
   */
  mapping(string => Campaign) private _campaigns;

  /**
   *  @dev Mapping from campaign to participants.
   */
  mapping(string => mapping(address => bool)) private _adminConsents;

  /**
   *  @dev Mapping from address to participant or not.
   */
  mapping(address => bool) public isParticipant;

  /**
   *@dev total token released
   */

  uint256 private _issueToken;

  /**
   *  @dev Set address token. Deployer is a admin.
   */
  constructor(
    IERC20 token_,
    uint256[] memory times_,
    uint256[] memory amounts_
  ) {
    _token = token_;
    uint256 fractions = 10**uint256(18);
    _validateTimesAndAmounts(times_, amounts_);
    for (uint256 i = 0; i < amounts_.length; i++) {
      _datas.push(DataByTime(times_[i], amounts_[i] * fractions));
    }
  }

  /**
   *@dev Create campaign
   */
  function createCampaign(
    string memory campaignName,
    address[] memory accounts,
    uint256[] memory amounts,
    uint256 releaseTime
  ) public onlyAdmin {
    _createOrUpdateCampaign(
      campaignName,
      accounts,
      amounts,
      releaseTime,
      false
    );
  }

  /**
   *@dev Create campaign
   */
  function updateCampaign(
    string memory campaignName,
    address[] memory accounts,
    uint256[] memory amounts,
    uint256 releaseTime
  ) public onlyAdmin {
    _createOrUpdateCampaign(campaignName, accounts, amounts, releaseTime, true);
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

  /**
   *@dev Create campaign
   */
  function release(string memory campaignName, bool passive) public onlyAdmin {
    require(
      block.timestamp >= _campaigns[campaignName].releaseTime,
      "It's not time yet!"
    );

    require(!_campaigns[campaignName].isClaimed, "Campaign ended!");

    _checkConsensus(campaignName);
    Participant[] memory listParticipant = _campaigns[campaignName]
      .participants;
    for (uint256 i = 0; i < listParticipant.length; i++) {
      Participant memory participant = listParticipant[i];
      if (passive) {
        _token.safeIncreaseAllowance(participant.account, participant.amount);
      } else {
        _token.safeTransfer(participant.account, participant.amount);
      }
    }
    _campaigns[campaignName].isClaimed = true;
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
  function _validateTimesAndAmounts(
    uint256[] memory _unlockTimes,
    uint256[] memory _amounts
  ) private pure {
    uint256 numberOfTime = _unlockTimes.length;
    uint256 numberOfAmount = _amounts.length;
    require(
      numberOfTime > 0 && numberOfAmount > 0,
      "Times, accounts can't be zero!"
    );
    require(numberOfTime == numberOfAmount, "Times and accounts not match!");
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
   *@dev
   * Validate input.
   * Requirements:
   *
   * - `campaignName` must not exist.
   * - `_accounts.length` equal `_amounts.length`.
   *
   */
  function _validateAccountsAndAmounts(
    address[] memory _accounts,
    uint256[] memory _amounts
  ) private pure {
    uint256 numberOfAccount = _accounts.length;
    uint256 numberOfAmount = _amounts.length;
    require(
      numberOfAccount > 0 && numberOfAmount > 0,
      "Amounts, accounts can't be zero!"
    );
    require(numberOfAccount == numberOfAmount, "Amounts and times not match!");
  }

  /**
   *@dev Total token unlocked.
   */
  function _getTotalTokenUnlock() private view returns (uint256) {
    uint256 totalTokenUnlock = 0;
    uint256 currentTime = block.timestamp;
    for (uint256 i = 0; i < _datas.length; i++) {
      if (currentTime >= _datas[i].unlockTime) {
        totalTokenUnlock += _datas[i].amount;
      }
    }
    return totalTokenUnlock;
  }

  /**
   *@dev Total token in a campaign.
   */
  function _getTokensByName(string memory campaignName)
    private
    view
    returns (uint256)
  {
    uint256 totalToken = 0;
    Participant[] memory listParticipant = _campaigns[campaignName]
      .participants;

    for (uint256 i = 0; i < listParticipant.length; i++) {
      Participant memory participant = listParticipant[i];
      totalToken += participant.amount;
    }
    return totalToken;
  }

  /**
   *@dev Set a list of participant to a time and set this participant is true.
   */
  function _createOrUpdateCampaign(
    string memory _campaignName,
    address[] memory _accounts,
    uint256[] memory _amounts,
    uint256 releaseTime,
    bool _isUpdate
  ) private {
    bool isExist = _campaigns[_campaignName].participants.length > 0;
    require(
      (isExist && _isUpdate) || (!isExist && !_isUpdate),
      _isUpdate
        ? "Can't update campaign that doesn't exist!"
        : "Unable to create a new campaign that already exists!"
    );

    _validateAccountsAndAmounts(_accounts, _amounts);

    uint256 tokenUnlocked = _getTotalTokenUnlock();
    if (_isUpdate) {
      uint256 oldToken = _getTokensByName(_campaignName);
      _issueToken -= oldToken;

      delete _campaigns[_campaignName].participants;
    } else {
      _campaignNames.push(_campaignName);
    }
    uint256 tokenCanUse = tokenUnlocked - _issueToken;
    uint256 totalAmount = 0;
    for (uint256 i = 0; i < _amounts.length; i++) {
      totalAmount += _amounts[i];
    }

    require(tokenCanUse >= totalAmount, "Exceed the amount available!");

    Participant[] storage listParticipant = _campaigns[_campaignName]
      .participants;
    for (uint256 i = 0; i < _accounts.length; i++) {
      listParticipant.push(Participant(_accounts[i], _amounts[i]));
      isParticipant[_accounts[i]] = true;
    }
    _issueToken += totalAmount;
    _campaigns[_campaignName].releaseTime = releaseTime;

    emit ChangeCampaign(_campaignName, _accounts, _amounts, _isUpdate);
  }

  function getDatas() public view returns (DataByTime[] memory) {
    return _datas;
  }

  function getCampaigns() public view returns (string[] memory) {
    return _campaignNames;
  }

  function getCampaign(string memory campaignName)
    public
    view
    returns (Campaign memory)
  {
    return _campaigns[campaignName];
  }

  function getTotalTokenUnlock() public view returns (uint256) {
    return _getTotalTokenUnlock();
  }

  function getTotalCanUse() public view returns (uint256) {
    return _getTotalTokenUnlock() - _issueToken;
  }

}
