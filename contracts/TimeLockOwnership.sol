// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./SafeMaths.sol";

/**
 *@author Ivirse team
 *@title  Smart contract for. User can get tokens after a period of time.
 */

contract TimeLockOwnership is Ownable {
  using SafeMaths for uint256;

  struct TimeAndRatio {
    uint256 time;
    uint256 ratio;
  }
  event ClaimToken(uint256 _amount, address _owner, uint256 _time);
  IERC20 private _token;

  ///@notice list ratio and time
  TimeAndRatio[] private _listTimeAndRatio;

  ///@notice total token can claim
  uint256 private _totalToken;

  ///@notice tokens received
  uint256 private _receivedToken = 0;

  constructor(
    address tokenAddress_,
    uint256[] memory listRatio_,
    uint256[] memory listTime_,
    uint256 totalToken_
  ) {
    require(
      _validateConstructor(tokenAddress_, listRatio_, listTime_),
      "Parameters invalid"
    );
    _token = IERC20(tokenAddress_);
    _totalToken = totalToken_;
    uint256 countTime = block.timestamp;
    for (uint256 i = 0; i < listTime_.length; i++) {
      countTime += listTime_[i];
      _listTimeAndRatio.push(TimeAndRatio(countTime, listRatio_[i]));
    }
  }

  ///@notice require before constructor
  function _validateConstructor(
    address _tokenAddress,
    uint256[] memory _listRatio,
    uint256[] memory _listTime
  ) private pure returns (bool) {
    uint256 numberOfRatio = _listRatio.length;
    uint256 numberOfTime = _listTime.length;
    uint256 totalRatio = 0;
    for (uint256 i = 0; i < _listRatio.length; i++) {
      totalRatio += _listRatio[i];
    }
    return
      numberOfTime == numberOfRatio &&
      totalRatio == 100 &&
      _tokenAddress != address(0);
  }


  ///@notice get token over time
  function _getTokensCanClaim() private view returns (uint256) {
    uint256 totalTokenUnlock = 0;
    for (uint256 i = 0; i < _listTimeAndRatio.length; i++) {
      if (block.timestamp > _listTimeAndRatio[i].time) {
        totalTokenUnlock += _totalToken.percent(_listTimeAndRatio[i].ratio);
      }
    }
    totalTokenUnlock -= _receivedToken;
    return totalTokenUnlock;
  }

  ///@notice release
  function release(uint256 amount) public onlyOwner {
    uint256 tokenCanClaim = _getTokensCanClaim();
    require(tokenCanClaim >= amount, "Exceed total token");
    _receivedToken += amount;
    _token.transfer(owner(), amount);
    emit ClaimToken(amount, owner(), block.timestamp);
  }

  function getTimeAndRatio() public view returns (TimeAndRatio[] memory) {
    return _listTimeAndRatio;
  }

  ///@notice public get token over time
  function getTokenCanClaim() public view returns (uint256) {
    return _getTokensCanClaim();
  }

  function getTotalToken() public view returns (uint256) {
    return _totalToken;
  }
}
