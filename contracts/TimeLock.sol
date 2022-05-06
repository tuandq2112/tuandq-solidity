// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract TokenTimelock is Ownable {
  using SafeERC20 for IERC20;
  using SafeMath for uint256;

  IERC20 private _token;

  address[] private _beneficiary;

  struct amountData {
    uint256 amountReceive;
    uint256 amountReceived;
  }
  mapping(address => amountData) private _amount;
  uint256 public _sumAmount;
  uint256 private _sumBalanceContractInTimes = 0;

  struct timesAndRate {
    uint256 timeLock;
    uint256 rate;
  }
  uint256 private _times;
  mapping(uint256 => timesAndRate) private _timesAndRate;
  uint256 private _timeStart;

  uint256 private _count = 0;
  bool private _status = false;
  uint256 private _statusContract = 0;

  event SetBeneficiaryAmounts(
    IERC20 token_,
    address[] beneficiary_,
    uint256[] amounts_
  );
  event SetTimesAndRate(uint256[] rate_, uint256[] timeLock_);

  constructor() {}

/**
  * set dia chi token erc20 '_token'
  * set danh sach cac address vestor '_beneficiary'
  * set so luong token cho vestor '_amounts'
 */
  function setBeneficiaryAmounts(
    IERC20 token_,
    address[] memory beneficiary_,
    uint256[] memory amounts_
  ) public onlyOwner {
    require(beneficiary_.length != 0, "beneficiary_.length >= 1");
    require(beneficiary_.length == amounts_.length, "must be the same length");
    require(_statusContract == 0 || _statusContract == 2, "not time to set");

    _token = token_;
    _statusContract = 0;

    for (uint256 i = 0; i < beneficiary_.length; i++) {
      _amount[beneficiary_[i]].amountReceive = amounts_[i];
      _sumAmount = _sumAmount + amounts_[i];
      _beneficiary.push(beneficiary_[i]);
    }
    emit SetBeneficiaryAmounts(token_, beneficiary_, amounts_);
  }

/**
  * set so lan vesting '_times'
  * set ti le moi lan vesting 'rate'
  * set time lock moi lan vesting 'timelockk')
 */
  function setTimesAndRate(
    uint256 times_,
    uint256[] memory rate_,
    uint256[] memory timeLock_
  ) public onlyOwner {
    require(times_ != 0, "times_ >= 1");
    require(times_ == rate_.length, "must be equal");
    require(times_ == timeLock_.length, "must be equal");
    require(_statusContract == 0 || _statusContract == 2, "not time to set");

    _times = times_;
    uint256 sum = 0;
    for (uint256 i = 0; i < times_; i++) {
      sum = sum + rate_[i];
      _timesAndRate[i].rate = rate_[i];
      _timesAndRate[i].timeLock = timeLock_[i];
    }
    require(sum == 100, "sum equal to 100%");
    emit SetTimesAndRate(rate_, timeLock_);
  }

/**
  * truoc khi goi ham startRelease() lan dau, balanceOf(address(this)) >= _sumAmount
  *  
 */
  function startRelease() public onlyOwner {
    if (_count == 0) {
      uint256 amount = token().balanceOf(address(this));
      require(amount >= _sumAmount, "not enough tokens to release");
    }
    require(_count < _times, "too many times vesting");
    require(_status == false, "not start time");
    _timeStart = _timesAndRate[_count].timeLock + block.timestamp;
    _status = true;
    _statusContract = 1;
  }

/**
  * approve token cho vestor theo ti le vesting
 */
  function release() public onlyOwner {
    require(block.timestamp >= _timeStart, "not time release");
    require(_status == true, "time error");

    for (uint256 i = 0; i < _beneficiary.length; i++) {
      uint256 lastAmount = token().allowance(address(this), _beneficiary[i]);
      if (lastAmount != 0) {
        token().safeDecreaseAllowance(_beneficiary[i], lastAmount);
      }
      uint256 amountSend = SafeMath.div(
        SafeMath.mul(
          _amount[_beneficiary[i]].amountReceive,
          _timesAndRate[_count].rate
        ),
        100
      );
      token().safeApprove(_beneficiary[i], lastAmount + amountSend);
      _amount[_beneficiary[i]].amountReceived += amountSend;
    }
    _sumBalanceContractInTimes =
      _sumBalanceContractInTimes +
      SafeMath.div(SafeMath.mul(_sumAmount, _timesAndRate[_count].rate), 100);
    _count++;
    _status = false;
  }

/**
  * reset cac bien contract ve ban dau
 */
  function resetData() public onlyOwner {
    require(_count >= _times, "not time to reset data");
    delete _beneficiary;
    _times = 0;
    _statusContract = 2;
    _sumBalanceContractInTimes = 0;
    _count = 0;
    _sumAmount = 0;
  }

/**
  * approve token con lai cho owner
 */
  function withdrawCoin() public onlyOwner returns (uint256) {
    uint256 amount = token().balanceOf(address(this));
    require(amount != 0, "not have token");
    uint256 amountRevert = amount - _sumBalanceContractInTimes;
    token().safeApprove(owner(), amountRevert);
    return amountRevert;
  }

/**
  * kiem tra thoi diem realease
 */
  function checkTimeRelease() public view returns (bool) {
    if (_status == false) {
      return false;
    } else if (block.timestamp >= _timeStart) {
      return true;
    }
    return false;
  }

/**
  * tra ve dia chi token erc20
 */
  function token() public view returns (IERC20) {
    return _token;
  }
}
