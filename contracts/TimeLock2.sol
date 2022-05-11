// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./TimeLockInterface.sol";

/**
 *@author Ivirse team
 *@title  Smart contract for. Users can get tokens after a period of time.
 */

contract TimeLock2 is Ownable, TimeLockInterface {
  ///@notice limited number of investors
  uint256 public immutable LIMITED_NUMBER_OF_PARTICIPANTS = 800;

  using SafeMath for uint256;

  using SafeERC20 for IERC20;

  enum STATUSENUM {
    PREPARE,
    RELEASE,
    DELAY,
    FINISHED
  }

  struct TimeAndRate {
    uint256 time;
    uint256 rate;
  }

  modifier inPreparePhase() {
    require(_status == STATUSENUM.PREPARE, "Not in prepare phase");
    _;
  }

  modifier inReleasePhase() {
    require(_status == STATUSENUM.RELEASE, "Not in release phase");
    _;
  }

  modifier inDelayTime() {
    require(_status == STATUSENUM.DELAY, "Not in delay phase");
    _;
  }

  modifier inFinishPhase() {
    require(_status == STATUSENUM.FINISHED, "Not in finish phase");
    _;
  }

  ///@notice token used in this smart contract
  IERC20 private _token;

  ///@notice the total amount that the user will receive
  mapping(address => uint256) private _totalAmount;

  ///@notice list investor
  address[] private _investors;

  STATUSENUM private _status;

  uint256 private _times;
  uint256 private _count = 0;

  TimeAndRate[] private _listTimeAndRate;

  uint256 private _startTime;

  event AddInvestors(address[] _investorAddresses, uint256[] _amounts);
  event SetTimeAndRate(uint256 _times, uint256[] _rate, uint256[] _timeLock);

  constructor(IERC20 token_) {
    _token = token_;
    _status = STATUSENUM.PREPARE;
  }

  ///@notice Prepare phase
  function _validateInput(
    address[] memory _investorAddresses,
    uint256[] memory _amounts
  ) private view returns (bool) {
    uint256 numberOfInvestorAddress = _investorAddresses.length;
    uint256 numberOfAmount = _amounts.length;
    uint256 newNumber = _investors.length + numberOfInvestorAddress;
    return
      numberOfInvestorAddress > 0 &&
      numberOfAmount > 0 &&
      numberOfAmount == numberOfInvestorAddress &&
      newNumber <= LIMITED_NUMBER_OF_PARTICIPANTS;
  }

  function addInvestor(
    address[] memory investorAddresses,
    uint256[] memory amounts
  ) public override {
    require(_validateInput(investorAddresses, amounts), "Input invalid");
    for (uint64 i = 0; i < investorAddresses.length; i++) {
      address newAddress = investorAddresses[i];
      uint256 newAmount = amounts[i];
      _investors.push(newAddress);
      _totalAmount[newAddress] = newAmount;
    }
    emit AddInvestors(investorAddresses, amounts);
  }

  function _validateTimeAndRate(
    uint256 _newTimes,
    uint256[] memory _rates,
    uint256[] memory _listTime
  ) private pure returns (bool) {
    uint256 numberOfRate = _rates.length;
    uint256 numberOfTime = _listTime.length;
    uint256 totalRates = 0;
    for (uint256 i = 0; i < numberOfRate; i++) {
      totalRates += _rates[i];
    }
    return
      _newTimes == numberOfRate &&
      numberOfRate > 0 &&
      numberOfTime > 0 &&
      numberOfRate == numberOfTime &&
      totalRates == 100;
  }

  function setTimesAndRate(
    uint256 times,
    uint256[] memory rates,
    uint256[] memory listTime
  ) public override onlyOwner inPreparePhase {
    require(
      _validateTimeAndRate(times, rates, listTime),
      "Input to adjust time and rate invalid"
    );
    _times = times;
    while (_listTimeAndRate.length > 0) {
      _listTimeAndRate.pop();
    }
    for (uint256 i = 0; i < times; i++) {
      _listTimeAndRate.push(TimeAndRate(listTime[i], rates[i]));
    }
    emit SetTimeAndRate(times, rates, listTime);
  }

  function _calculateTokens() private view returns (uint256) {
    uint256 total;
    for (uint256 i = 0; i < _investors.length; i++) {
      total += _totalAmount[_investors[i]];
    }
    return total;
  }

  function start() public override onlyOwner inPreparePhase {
    require(
      _calculateTokens() <= _token.balanceOf(address(this)),
      "Not enough tokens"
    );
    _startTime = block.timestamp;
    _status = STATUSENUM.RELEASE;
  }

  ///@notice Delay phase

  function reStart() public override onlyOwner inDelayTime {
    _startTime = block.timestamp;
    _status = STATUSENUM.RELEASE;
  }

  ///@notice Release phase

  function _getNextRelaseTime() private view returns (uint256) {
    return _startTime + _listTimeAndRate[_count].time;
  }

  function _getCurrentRate() private view returns (uint256) {
    return _listTimeAndRate[_count].rate;
  }

  function release() public override onlyOwner inReleasePhase {
    require(
      block.timestamp > _getNextRelaseTime(),
      "It's not time release yet"
    );
    uint256 currentRating = _getCurrentRate();
    for (uint256 i = 0; i < _investors.length; i++) {
      address investorAddress = _investors[i];
      uint256 totalAmount = _totalAmount[investorAddress];
      uint256 amountApprove = totalAmount.mul(currentRating).div(100);
      _token.safeIncreaseAllowance(investorAddress, amountApprove);
    }
    _count++;

    if (_count == _times) {
      _status = STATUSENUM.FINISHED;
    } else {
      _status = STATUSENUM.DELAY;
    }
  }

  function getInvestors() public view returns (address[] memory) {
    return _investors;
  }

  ///@notice Finish phase
  function getExcessTokens() public onlyOwner inFinishPhase {
    uint256 totalExcessTokens = _token.balanceOf(address(this));
    _token.transfer(owner(), totalExcessTokens);
  }

  function reset() public override onlyOwner inFinishPhase {
    _count = 0;
    _status = STATUSENUM.PREPARE;
    _times = 0;
    _startTime = 0;
    while (_investors.length > 0) {
      _investors.pop();
    }

    while (_listTimeAndRate.length > 0) {
      _listTimeAndRate.pop();
    }
  }
}
