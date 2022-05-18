// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 *@author Ivirse team
 *@title  Smart contract for. User can get tokens after a period of time.
 */

contract CloneTimeLockWithAmount is Ownable {
  event ClaimPrivateToken(uint256 _amount, address _owner, uint256 _time);
  event ClaimPublicToken(uint256 _amount, address _owner, uint256 _time);

  struct DataByTime {
    uint256 time;
    uint256 amount;
    bool isClaimed;
  }
  uint256 private FRACTIONS = 10**uint256(18);

  IERC20 private _token;

  DataByTime[] private _listPublicData;

  DataByTime[] private _listPrivateData;

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
      _listPublicData,
      listPublicTime_,
      listPublicAmount_
    );
    _initTimeAndRatio(
      _listPrivateData,
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
    DataByTime[] storage _listData,
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
      _listData.push(
        DataByTime(countTime, _listAmount[i] * FRACTIONS, false)
      );
    }
  }

  /**
   * @dev Get all element have time < now and count all amount of this .
   */
  function _releaseAllToken(
    DataByTime[] storage _listData,
    uint256 _receivedToken,
    bool isPublic
  ) private {
    uint256 totalToken = 0;
    uint256 currentTime = block.timestamp;
    for (uint256 i = 0; i < _listData.length; i++) {
      DataByTime storage data = _listData[i];
      if (data.time <= currentTime) {
        if (!data.isClaimed) {
          totalToken += data.amount;
          data.isClaimed = true;
        }
      } else {
        break;
      }
    }
    require(totalToken > 0, "User claimed all token, can not claim more");
    _receivedToken += totalToken;
    _token.transfer(owner(), totalToken);
    if (isPublic) {
      emit ClaimPublicToken(totalToken, owner(), block.timestamp);
    } else {
      emit ClaimPrivateToken(totalToken, owner(), block.timestamp);
    }
  }

  /**
   * @dev User claim token.
   * Requirements:
   *
   * - Amount less than or equal token unlocked minus token user received
   */
  function _handleClaimToken(DataByTime storage data, bool isPublic) private {
    require(!data.isClaimed, "User claimed token");
    uint256 currentTime = block.timestamp;
    require(data.time <= currentTime, "It's not time release yet");
    data.isClaimed = true;
    uint256 amount = data.amount;
    _token.transfer(owner(), amount);
    if (isPublic) {
      _receivedPublicToken += amount;

      emit ClaimPublicToken(amount, owner(), currentTime);
    } else {
      _receivedPrivateToken += amount;
      emit ClaimPrivateToken(amount, owner(), currentTime);
    }
  }

  function releasePublicTokenByIndex(uint256 index) public onlyOwner {
    _handleClaimToken(_listPublicData[index], true);
  }

  function releasePrivateTokenByIndex(uint256 index) public onlyOwner {
    _handleClaimToken(_listPrivateData[index], false);
  }

  /**
   * @dev User claim token.
   * Requirements:
   *
   * - Amount less than or equal token unlocked minus token user received
   */
  function releaseAllPublicToken() public onlyOwner {
    _releaseAllToken(_listPublicData, _receivedPublicToken, true);
  }

  /**
   * @dev User claim token.
   * Requirements:
   *
   * - Amount less than or equal token unlocked minus token user received
   */
  function releaseAllPrivateToken() public onlyOwner {
    _releaseAllToken(_listPrivateData, _receivedPrivateToken, false);
  }

  /**
   * @dev Get milestone and amount of private release.
   */
  function getPublicData() public view returns (DataByTime[] memory) {
    return _listPublicData;
  }

  /**
   * @dev Get milestone and amount of public release.
   */
  function getPrivateData() public view returns (DataByTime[] memory) {
    return _listPrivateData;
  }
}
