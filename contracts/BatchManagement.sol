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

contract BatchManagement is AdminConsensus {
  /**
   *  @dev  Emitted when `account` is accepted consent.
   */
  event AdminAcceptRelease(address indexed account, string indexed name);

  /**
   *  @dev  Emitted when `account` is rejected consent.
   */
  event AdminRejectRelease(address indexed account, string indexed name);

  /**
   *  @dev  Emitted when `admin` is created a batch.
   */
  event CreateBatch(
    address indexed performer,
    string indexed name,
    address[] accounts,
    uint256[] amounts,
    uint256 claimTime,
    uint256 indexed time
  );

  /**
   *  @dev  Emitted when `admin` is created a batch.
   */
  event Release(
    address indexed performer,
    string indexed name,
    uint256 indexed time
  );
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

  string[] private _batchNames;

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
    require(!_isExist(name), "This name already exists");
    require(
      accounts.length > 0 && accounts.length == amounts.length,
      "Input invalid"
    );
    _batchNames.push(name);

    Participant[] storage participants = _batchs[name].participants;
    _batchs[name].claimTime = claimTime;
    for (uint256 i = 0; i < accounts.length; i++) {
      Participant memory newParticipant = Participant(accounts[i], amounts[i]);
      participants.push(newParticipant);
      isParticipant[accounts[i]] = true;
    }
    emit CreateBatch(
      msg.sender,
      name,
      accounts,
      amounts,
      claimTime,
      block.timestamp
    );
  }

  function releaseToken(string memory name, bool passive) public onlyAdmin {
    Batch storage batch = _batchs[name];

    require(!batch.isClaimed, "This batch is over!");

    require(_checkAdminConsents(name), "Not enough consensus!");
    require(block.timestamp >= batch.claimTime, "It is not time yet!");

    Participant[] memory participants = batch.participants;

    if (passive) {
      for (uint256 i = 0; i < participants.length; i++) {
        Participant memory participant = participants[i];
        _token.safeIncreaseAllowance(participant.account, participant.amount);
      }
    } else {
      for (uint256 i = 0; i < participants.length; i++) {
        Participant memory participant = participants[i];
        _token.safeTransfer(participant.account, participant.amount);
      }
    }

    batch.isClaimed = true;
    emit Release(msg.sender, name, block.timestamp);
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
    for (uint256 i = 0; i < _batchNames.length; i++) {
      if (keccak256(bytes(_batchNames[i])) == keccak256(bytes(_name))) {
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

  function getBatchNames() public view returns (string[] memory) {
    return _batchNames;
  }
}
