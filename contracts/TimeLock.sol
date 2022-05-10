// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

/**
 *@author Ivirse team
 *@title  Smart contract for. Users can get tokens after a period of time.
 */

contract TokenTimelock is Ownable {
  using SafeERC20 for IERC20;
  using SafeMath for uint256;

  ///@notice địa chỉ token erc20
  IERC20 private _token;

  ///@notice mảng địa chỉ các investor
  address[] public _investors;

  ///@notice từ địa chỉ investor -> số token họ sẽ được nhận
  mapping(address => uint256) private _tokenForInvestor;

  ///@notice tổng số token của tất cả các investor
  uint256 public totalSupplyToken = 0;

  ///@notice cấu trúc lưu thời gian khoá và tỉ lệ mỗi vòng vesting
  struct timesAndRate {
    uint256 timeLock;
    uint256 rate;
  }

  ///@notice số lần vesting
  uint256 public timesVesting;

  ///@notice từ lần vesting -> thời gian khoá và tỉ lệ
  mapping(uint256 => timesAndRate) private _timesAndRate;

  ///@notice đếm thời gian chạy
  uint256 private _timeStartVesting;

  ///@notice đếm số lần vesting
  uint256 public countVesting = 0;

  ///@notice biến kiểm tra có đang trong vòng vesting
  bool private _statusRelease = false;

  /**
  * @notice biến hiển thị trạng thái contract
  '0': đang chuẩn bị dữ liệu 
  '1': đang trong thời gian vesting
  '2': đã kết thúc vesting
   */
  uint256 public statusContract = 0;

  constructor() {}

  /**
   * @dev thêm địa chỉ investor và lượng token của họ vào mảng
   */
  function setInvestorsAndAmounts(
    IERC20 tokenAddr,
    address[] memory investorsAddr,
    uint256[] memory amounts
  ) public onlyOwner {
    require(investorsAddr.length != 0, "investorsAddr.length >= 1");
    require(investorsAddr.length == amounts.length, "must be the same length");
    require(statusContract == 0 || statusContract == 2, "not time to set");

    _token = tokenAddr;
    statusContract = 0;

    /**@notice
     * gán số lượng token cho từng vestor (amounts)
     * push investor vào danh sách      (_investors)
     * tính tổng số lượng token          (totalSupplyToken)
     */
    for (uint256 i = 0; i < investorsAddr.length; i++) {
      _tokenForInvestor[investorsAddr[i]] = amounts[i];
      totalSupplyToken = totalSupplyToken + amounts[i];
      _investors.push(investorsAddr[i]);
    }
  }

  /**
   * @dev thêm số lần vesting kèm thời gian và tỉ lệ mỗi vòng
   */
  function setTimesAndRate(
    uint256 times,
    uint256[] memory rate,
    uint256[] memory timeLock
  ) public onlyOwner {
    require(times != 0, "times >= 1");
    require(times == rate.length, "must be equal");
    require(times == timeLock.length, "must be equal");
    require(statusContract == 0 || statusContract == 2, "not time to set");

    timesVesting = times;

    ///@notice kiểm tra xem tổng rate có bằng 100%
    uint256 checkSumRate = 0;

    /**
     * @notice
     * tính toán tổng rate
     * gán tỉ lệ với từng vòng
     * gán thời gian khoá với từng vòng
     */
    for (uint256 i = 0; i < times; i++) {
      checkSumRate = checkSumRate + rate[i];
      _timesAndRate[i].rate = rate[i];
      _timesAndRate[i].timeLock = timeLock[i];
    }

    require(checkSumRate == 100, "checkSumRate equal to 100%");
  }

  /**
   * @dev bắt đầu đếm thời gian vòng vesting hiện tại, bắt đầu từ vòng 0
   *
   *
   * @notice trước khi goi hàm startRelease() ở lần đầu, balanceOf(address(this)) >= totalSupplyToken
   *
   */
  function startRelease() public onlyOwner {
    if (countVesting == 0) {
      uint256 balanceContract = _token.balanceOf(address(this));
      require(
        balanceContract >= totalSupplyToken,
        "not enough tokens to start release"
      );
    }
    require(countVesting < timesVesting, "too many times vesting");
    require(_statusRelease == false, "not start time");

    _timeStartVesting = _timesAndRate[countVesting].timeLock + block.timestamp;
    _statusRelease = true;
    statusContract = 1;
  }

  /**
   * @dev hàm tính tỉ lệ phần trăm
   */
  function percent(uint256 arg, uint256 rate) private pure returns (uint256) {
    uint256 multiply = arg.mul(rate);
    return multiply.div(100);
  }

  /**
   * @dev approve token cho vestor theo ti le vesting
   */
  function release() public onlyOwner {
    require(block.timestamp >= _timeStartVesting, "not time release");
    require(_statusRelease == true, "time error");

    /**
     @notice tính toán tỉ lệ token approve và approve cho vestor
     */
    for (uint256 i = 0; i < _investors.length; i++) {
      uint256 amountSend = percent(
        _tokenForInvestor[_investors[i]],
        _timesAndRate[countVesting].rate
      );

      /**
      @notice không dùng safeApprove do không cộng dồn các token đã approve trước đó
       */
      _token.safeIncreaseAllowance(_investors[i], amountSend);
    }
    countVesting++;
    _statusRelease = false;
  }

  /**
   * @dev reset các biến của contract về khởi nguyên
   */
  function resetData() public onlyOwner {
    require(countVesting >= timesVesting, "not time to reset data");
    delete _investors;
    timesVesting = 0;
    statusContract = 2;
    countVesting = 0;
    totalSupplyToken = 0;
  }

  /**
   * @dev approve token cho owner
   *
   * @notice chú ý khi dùng hàm này do có TRƯỜNG HỢP investor chưa transferFrom 
      token được approve về mà owner đã rút hết tiền của contract ra 
      sẽ gây lỗi "investor đã được approve nhưng ko rút được token về"
   */
  function withdrawCoin() public onlyOwner returns (uint256) {
    uint256 amount = _token.balanceOf(address(this));
    require(amount != 0, "not have token");
    _token.safeApprove(owner(), amount);
    return amount;
  }

  /**
   * @dev kiem tra thoi diem realease
   *
   *
   * @notice nếu không trong thời gian release -> false
   * @notice nếu trong thời gian release, kiểm tra block.timestamp để biết true/false
   */
  function checkTimeRelease() public view returns (bool) {
    if (_statusRelease == false) {
      return false;
    } else if (block.timestamp >= _timeStartVesting) {
      return true;
    }

    return false;
  }

  /**
   @dev tra ve dia chi token erc20
   */
  function token() public view returns (IERC20) {
    return _token;
  }
  
}
