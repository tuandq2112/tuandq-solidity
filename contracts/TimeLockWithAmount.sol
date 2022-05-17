// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 *@author Ivirse team
 *@title  Smart contract for. User can get tokens after a period of time.
 */

contract TimeLockWithAmount is Ownable {
  event ClaimPrivateToken(uint256 _amount, address _owner, uint256 _time);
  event ClaimPublicToken(uint256 _amount, address _owner, uint256 _time);

  struct TimeAndAmount {
    uint256 time;
    uint256 amount;
  }
  uint256 private FRACTIONS = 10**uint256(18);

  IERC20 private _token;

  TimeAndAmount[] private _listPublicTimeAndAmount;

  TimeAndAmount[] private _listPrivateTimeAndAmount;

  uint256 private _receivedPublicToken = 0;

  uint256 private _receivedPrivateToken = 0;

  /**
   * @dev Sets the values for {listPublicTimeAndAmount} and {listPrivateTimeAndAmount}.
   *
   * The default value of {decimals} is 18. To select a different value for
   * {decimals} you should overload it.
   *
   * All two of these values are immutable: they can only be set once during
   * construction.
   * Requirements:
   *
   * - `length of listPublicAmount_ and length of listPublicTime_` can be equal
   * - `length of listPrivateAmount_ and length of listPrivateTime_` can be equal
   */

  constructor(
    address tokenAddress_,
    uint256[] memory listPublicAmount_,
    uint256[] memory listPublicTime_,
    uint256[] memory listPrivateAmount_,
    uint256[] memory listPrivateTime_
  ) {
    require(
      _validateConstructor(
        tokenAddress_,
        listPublicAmount_,
        listPublicTime_,
        listPrivateAmount_,
        listPrivateTime_
      ),
      "Parameters invalid"
    );
    _token = IERC20(tokenAddress_);
    _initTimeAndRatio(
      _listPublicTimeAndAmount,
      listPublicTime_,
      listPublicAmount_
    );
    _initTimeAndRatio(
      _listPrivateTimeAndAmount,
      listPrivateTime_,
      listPrivateAmount_
    );
  }

  ///@notice require before constructor
  function _validateConstructor(
    address _tokenAddress,
    uint256[] memory _listPublicAmount,
    uint256[] memory _listPublicTime,
    uint256[] memory _listPrivateAmount,
    uint256[] memory _listPrivateTime
  ) private pure returns (bool) {
    uint256 numberOfPublicAmount = _listPublicAmount.length;
    uint256 numberOfPublicTime = _listPublicTime.length;
    uint256 numberOfPrivateAmount = _listPrivateAmount.length;
    uint256 numberOfPrivateTime = _listPrivateTime.length;

    return
      numberOfPublicAmount == numberOfPublicTime &&
      numberOfPrivateAmount == numberOfPrivateTime &&
      _tokenAddress != address(0);
  }

  /**
   * @dev Corresponding to a time there will be a price we push into the array.
   */

  function _initTimeAndRatio(
    TimeAndAmount[] storage _listTimeAndAmount,
    uint256[] memory _listTime,
    uint256[] memory _listAmount
  ) private {
    require(
      _listTime.length == _listAmount.length,
      "Number of time is not equal number of amount"
    );
    uint256 countTime = block.timestamp;
    for (uint256 i = 0; i < _listTime.length; i++) {
      countTime += _listTime[0];
      _listTimeAndAmount.push(
        TimeAndAmount(countTime, _listAmount[i] * FRACTIONS)
      );
    }
  }

  /**
   * @dev Get all element have time < now and count all amount of this .
   */
  function _countAmountByTime(TimeAndAmount[] memory _listTimeAndAmount)
    private
    view
    returns (uint256)
  {
    uint256 totalAmount = 0;
    uint256 currentTime = block.timestamp;
    for (uint256 i = 0; i < _listTimeAndAmount.length; i++) {
      if (_listTimeAndAmount[i].time <= currentTime) {
        totalAmount += _listTimeAndAmount[i].amount;
      } else {
        break;
      }
    }
    return totalAmount;
  }

  /**
   * @dev Get total private amount unlocked for user .
   */
  function _getPrivateTokensUnlocked() private view returns (uint256) {
    return _countAmountByTime(_listPrivateTimeAndAmount);
  }

  /**
   * @dev Get total public amount unlocked for user .
   */
  function _getPublicTokensUnlocked() private view returns (uint256) {
    return _countAmountByTime(_listPublicTimeAndAmount);
  }

  /**
   * @dev Get milestone and amount of private release.
   */
  function getPublicTimeAndAmount()
    public
    view
    returns (TimeAndAmount[] memory)
  {
    return _listPublicTimeAndAmount;
  }

  /**
   * @dev Get milestone and amount of public release.
   */
  function getPrivateTimeAndAmount()
    public
    view
    returns (TimeAndAmount[] memory)
  {
    return _listPrivateTimeAndAmount;
  }

  /**
   * @dev User claim token.
   * Requirements:
   *
   * - Amount less than or equal token unlocked minus token user received
   */
  function releasePublicToken(uint256 amount) public onlyOwner {
    uint256 tokenPublicCanClaim = _getPublicTokensUnlocked();
    require(
      tokenPublicCanClaim - _receivedPublicToken >= amount,
      "Exceed total private token"
    );
    _receivedPublicToken += amount;
    _token.transfer(owner(), amount);
    emit ClaimPrivateToken(amount, owner(), block.timestamp);
  }

  /**
   * @dev User claim token.
   * Requirements:
   *
   * - Amount less than or equal token unlocked minus token user received
   */
  function releasePrivateToken(uint256 amount) public onlyOwner {
    uint256 tokenPrivateCanClaim = _getPrivateTokensUnlocked();
    require(
      tokenPrivateCanClaim - _receivedPrivateToken >= amount,
      "Exceed total private token"
    );
    _receivedPrivateToken += amount;
    _token.transfer(owner(), amount);
    emit ClaimPublicToken(amount, owner(), block.timestamp);
  }

  /**
   * @dev Total public token user can claims.
   */
  function getPublicTokenCanClaim() public view returns (uint256) {
    return _getPublicTokensUnlocked() - _receivedPublicToken;
  }

  /**
   * @dev Total private token user can claims.
   */
  function getPrivateTokenCanClaim() public view returns (uint256) {
    return _getPrivateTokensUnlocked() - _receivedPrivateToken;
  }

  /**
   * @dev Total public token user can claims.
   */
  function getPublicTokenClaimed() public view returns (uint256) {
    return _receivedPublicToken;
  }

  /**
   * @dev Total private token user can claims.
   */
  function getPrivateTokenClaimed() public view returns (uint256) {
    return _receivedPrivateToken;
  }
}
