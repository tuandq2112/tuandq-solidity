// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./consensus/AdminConsensus.sol";

/**
 *@author tuan.dq
 *@title Smart contract for batchs
 */

contract CampaignManagement is AdminConsensus {
  /**
   *  @dev  Emitted when `account` is accepted consent.
   */
  event AdminAcceptRelease(address indexed account, string indexed batch);

  /**
   *  @dev  Emitted when `account` is rejected consent.
   */
  event AdminRejectRelease(address indexed account, string indexed batch);

  /**
   * @dev ERC20 token for this smart contract
   */
  IERC20 private _token;

  using SafeERC20 for IERC20;

  using SafeMath for uint256;

  struct Participant {
    address account;
    uint256 amount;
  }

  struct Batch {
    Participant[] participants;
    bool isClaimed;
    uint256 claimTime;
  }

  string[] private _campaignNames;

  mapping(string => Batch) private _batchs;

  mapping(string => mapping(address => bool)) private _adminConsents;

  mapping(address => bool) public isParticipant;

  uint256 private _totalAmountOwed = 0;

  constructor(IERC20 token_) {
    _token = token_;
  }

  function createBatch(
    string memory name,
    address[] memory accounts,
    uint256[] memory amounts,
    uint256 claimTime
  ) public onlyAdmin {
    require(!_isExist(name), "participants already exists");
    require(
      accounts.length > 0 && accounts.length == amounts.length,
      "Input invalid"
    );
    Participant[] storage participants = _batchs[name].participants;
    _batchs[name].claimTime = claimTime;
    for (uint256 i = 0; i < accounts.length; i++) {
      Participant memory newParticipant = Participant(accounts[i], amounts[i]);
      participants.push(newParticipant);
      isParticipant[accounts[i]] = true;
    }
  }

  function releaseToken(string memory name, bool passive) public onlyAdmin {
    Batch memory batch = _batchs[name];

    require(_checkAdminConsents(name), "Not enough consensus!");
    require(block.timestamp >= batch.claimTime, "It is not time yet!");

    Participant[] memory participants = batch.participants;
    bool isClaimed = batch.isClaimed;

    if (passive) {
      for (uint256 i = 0; i < participants.length; i++) {
        Participant memory participant = participants[i];
        _token.safeTransfer(participant.account, participant.amount);
      }
    } else {
      for (uint256 i = 0; i < participants.length; i++) {
        Participant memory participant = participants[i];
        _token.safeIncreaseAllowance(participant.account, participant.amount);
      }
    }

    isClaimed = true;
  }

  /**
   *  @dev  Admin accept for batch release token.
   */
  function adminAcceptRelease(string memory name) public onlyAdmin {
    _adminConsents[name][msg.sender] = true;
    emit AdminAcceptRelease(msg.sender, name);
  }

  /**
   *  @dev  Admin reject for batch release token.
   */
  function adminRejectRelease(string memory name) public onlyAdmin {
    _adminConsents[name][msg.sender] = false;
    emit AdminRejectRelease(msg.sender, name);
  }

  function _isExist(string memory _name) private view returns (bool) {
    for (uint256 i = 0; i < _campaignNames.length; i++) {
      if (keccak256(bytes(_campaignNames[i])) == keccak256(bytes(_name))) {
        return true;
      }
    }
    return false;
  }

  function _checkAdminConsents(string memory name) private view returns (bool) {
    uint256 adminLength = _admins.length;
    uint256 count = 0;
    for (uint256 i = 0; i < adminLength; i++) {
      if (_adminConsents[name][_admins[i]]) {
        count++;
      }
    }
    uint256 minNumber = adminLength.div(2) + 1;
    return count >= minNumber;
  }
}
