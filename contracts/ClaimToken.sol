// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 *@author Ivirse team
 *@title  Smart contract for. User can get tokens after a period of time.
 */

contract ClaimToken is Ownable {
  event ClaimTokenEvent(uint256 _amount, address _owner, uint256 _time);

  struct DataByTime {
    uint256 time;
    uint256 publicAmount;
    uint256 privateAmount;
    bool isClaimed;
  }
  uint256 private FRACTIONS = 10**uint256(18);

  IERC20 private _token;

  DataByTime[] _listData;

  constructor(
    address tokenAddress_,
    uint256[] memory listTime_,
    uint256[] memory listPublicAmount_,
    uint256[] memory listPrivateAmount_
  ) {
    require(
      _validateConstructor(
        tokenAddress_,
        listTime_,
        listPrivateAmount_,
        listPublicAmount_
      ),
      "Parameters invalid"
    );
    _token = IERC20(tokenAddress_);
    uint256 currentTime = block.timestamp;
    for (uint256 i = 0; i < listTime_.length; i++) {
      currentTime += listTime_[i];
      _listData.push(
        DataByTime(
          currentTime,
          listPublicAmount_[i] * FRACTIONS,
          listPrivateAmount_[i] * FRACTIONS,
          false
        )
      );
    }
  }

  ///@notice require before constructor
  function _validateConstructor(
    address _tokenAddress,
    uint256[] memory _listTime,
    uint256[] memory _listPrivateAmount,
    uint256[] memory _listPublicAmount
  ) private pure returns (bool) {
    uint256 numberOfTime = _listTime.length;
    uint256 numberOfPublicAmount = _listPublicAmount.length;
    uint256 numberOfPrivateAmount = _listPrivateAmount.length;

    return
      numberOfPublicAmount == numberOfPrivateAmount &&
      numberOfPrivateAmount == numberOfTime &&
      numberOfTime > 0 &&
      _tokenAddress != address(0);
  }

  function releaseTokenByIndex(uint256 index) public onlyOwner {
    DataByTime storage data = _listData[index];
    uint256 currentTime = block.timestamp;
    require(data.time <= currentTime, "It's not time release yet");
    require(!data.isClaimed, "The user has received money at this time");
    address owner = owner();
    uint256 totalAmount = data.privateAmount + data.publicAmount;
    data.isClaimed = true;
    _token.transfer(owner, totalAmount);
    emit ClaimTokenEvent(totalAmount, owner, currentTime);
  }

  function releaseAllToken() public onlyOwner {
    uint256 totalTokenCanClaim = 0;
    uint256 currentTime = block.timestamp;
    for (uint256 index = 0; index < _listData.length; index++) {
      DataByTime storage data = _listData[index];
      if (!data.isClaimed && data.time <= currentTime) {
        data.isClaimed = true;
        totalTokenCanClaim += data.privateAmount + data.publicAmount;
      }
    }
    address owner = owner();
    require(totalTokenCanClaim > 0, "User received all unlock tokens");
    _token.transfer(owner, totalTokenCanClaim);
    emit ClaimTokenEvent(totalTokenCanClaim, owner, currentTime);
  }

  function getData() public view returns (DataByTime[] memory) {
    return _listData;
  }
}
