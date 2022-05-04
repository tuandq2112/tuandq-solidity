// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract TokenTimelock is Ownable {
  using SafeERC20 for IERC20;
  using SafeMath for uint256;

  IERC20 private _token;

  //list vestor
  address[] private _beneficiary;

  struct amountData {
    uint256 amountReceive;
    uint256 amountReceived;
  }

  // amount for vestor
  mapping(address => amountData) private _amount;
  uint256 private _sumAmount;

  struct timesAndRate {
    uint256 timeLock;
    uint256 rate;
  }
  uint256 private _times;
  mapping(uint256 => timesAndRate) private _timesAndRate;

  uint256 private _timeStart;
  uint256 private _count = 0;
  bool private _status = false;

  constructor() {}

  // admin thiet lap danh sach va so luong amoun cho tung address
  function setBeneficiaryAmounts(
    IERC20 token_,
    address[] memory beneficiary_,
    uint256[] memory amounts_
  ) public onlyOwner {
    require(beneficiary_.length != 0, "beneficiary_.length >= 1");
    require(amounts_.length != 0, "amounts_.length >= 1");
    require(beneficiary_.length == amounts_.length, "must be the same length");

    _token = token_;

    for (uint256 i = 0; i < beneficiary_.length; i++) {
      _amount[beneficiary_[i]].amountReceive = amounts_[i];
      _sumAmount = _sumAmount + amounts_[i];
      _beneficiary.push(beneficiary_[i]);
    }
  }

  //admin thiet lap so lan vesting, ti le moi lan vesting và thoi gian moi lan vesting
  function setTimesAndRate(
    uint256 times_,
    uint256[] memory rate_,
    uint256[] memory timeLock_
  ) public onlyOwner {
    require(times_ != 0, "times_ >= 1");
    require(times_ == rate_.length, "must be equal");
    require(times_ == timeLock_.length, "must be equal");
    require(_count >= _times, "still in vesting time");

    _times = times_;
    uint256 sum = 0;
    for (uint256 i = 0; i < times_; i++) {
      sum = sum + rate_[i];
      _timesAndRate[i].rate = rate_[i];
      _timesAndRate[i].timeLock = timeLock_[i];
    }
    require(sum == 100, "sum equal to 100%");
  }

  //admin goi khi bat dau tinh thoi gian vesting cho tung vong
  function startRelease() public onlyOwner {
    require(_status == false, "not start time");
    _timeStart = _timesAndRate[_count].timeLock + block.timestamp;
    _status = true;
  }

  // tra ve dia chi token erc20
  function token() public view virtual returns (IERC20) {
    return _token;
  }

  // tra ve luot vesting dang thuc hien
  function getCurrentTimes() public view virtual returns (uint256) {
    return _count;
  }

  //tra ve danh sach cac dia chi vestor
  function getListVestor() public view virtual returns (address[] memory) {
    return _beneficiary;
  }

  //tra ve amount ung voi address vestor
  function getAmountForBeneficiary(address beneficiary_)
    public
    view
    virtual
    returns (uint256)
  {
    return _amount[beneficiary_].amountReceive;
  }

  //tra ve tong so lan vesting
  function getTimes() public view virtual returns (uint256) {
    return _times;
  }

  //tra ve thoi gian va ti le ung voi tung lan vesting
  function getRateAndTimeLockForTimes(uint256 times_)
    public
    view
    virtual
    returns (timesAndRate memory)
  {
    return _timesAndRate[times_];
  }

  // tra ve amount con lai
  function getAmountRemaining(address beneficiary_)
    public
    view
    virtual
    returns (uint256)
  {
    return
      _amount[beneficiary_].amountReceive -
      _amount[beneficiary_].amountReceived;
  }

  // tra ve tong amount
  function getSumAmount() public view virtual returns (uint256) {
    return _sumAmount;
  }

  /*
    - truoc khi goi ham release() admin phai transfer 1 luong token cho address timeLock
    - token.balanceOf(address(this)) phai >= tong cung vesting * ti le vestin cua vong do
    - sau khi release, vestor tu transferFrom ve vi cua minh
    */

  //admin goi khi het thoi gian lock, de chuyen approve cho vestor
  function release() public virtual onlyOwner {
    require(block.timestamp >= _timeStart, "not time release");
    require(_status == true, "time error");

    uint256 amount = token().balanceOf(address(this));
    require(
      amount >=
        SafeMath.div(SafeMath.mul(_sumAmount, _timesAndRate[_count].rate), 100),
      "not enough tokens to release"
    );

    for (uint256 i = 0; i < _beneficiary.length; i++) {
      uint256 lastAmount = token().allowance(address(this), _beneficiary[i]);
      if (lastAmount != 0) {
        token().safeDecreaseAllowance(_beneficiary[i], lastAmount);
      }
      if (_count == _times - 1) {
        uint256 amountSend = _amount[_beneficiary[i]].amountReceive -
          _amount[_beneficiary[i]].amountReceived;
        token().safeApprove(_beneficiary[i], lastAmount + amountSend);
      } else {
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
    }
    _count++;
    _status = false;
  }

  //kiem tra thoi diem release
  function checkTimeRelease() public view returns (bool) {
    if (_status == false) {
      return false;
    } else if (block.timestamp >= _timeStart) {
      return true;
    }
    return false;
  }
}
