// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./TimeAndAmountLibrary.sol";

/**
 *@author Ivirse team
 *@title  Smart contract for. User can get tokens after a period of time.
 */

contract TimeLockWithAmount is Ownable {
  event ClaimPrivateToken(uint256 _amount, address _owner, uint256 _time);
  event ClaimPublicToken(uint256 _amount, address _owner, uint256 _time);

  IERC20 private _token;

  TimeAndAmountLibrary.TimeAndAmount[] private _listPublicTimeAndAmount;

  TimeAndAmountLibrary.TimeAndAmount[] private _listPrivateTimeAndAmount;

  ///@notice tokens received
  uint256 private _receivedPublicToken = 0;
  uint256 private _receivedPrivateToken = 0;

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
    uint256 currentTime = block.timestamp;
    TimeAndAmountLibrary.addToList(
      _listPublicTimeAndAmount,
      listPublicTime_,
      listPublicAmount_,
      currentTime
    );
    TimeAndAmountLibrary.addToList(
      _listPrivateTimeAndAmount,
      listPrivateTime_,
      listPrivateAmount_,
      currentTime
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

  ///@notice get token over time
  function _getPrivateTokensCanClaim() private view returns (uint256) {
    return
      TimeAndAmountLibrary.countAmountByTime(
        _listPrivateTimeAndAmount,
        block.timestamp
      );
  }

  ///@notice get token over time
  function _getPublicTokensCanClaim() private view returns (uint256) {
    return
      TimeAndAmountLibrary.countAmountByTime(
        _listPublicTimeAndAmount,
        block.timestamp
      );
  }

  function getPublicTimeAndAmount()
    public
    view
    returns (TimeAndAmountLibrary.TimeAndAmount[] memory)
  {
    return _listPublicTimeAndAmount;
  }

  function getPrivateTimeAndAmount()
    public
    view
    returns (TimeAndAmountLibrary.TimeAndAmount[] memory)
  {
    return _listPrivateTimeAndAmount;
  }

  ///@notice release
  function releasePublicToken(uint256 amount) public onlyOwner {
    uint256 tokenPublicCanClaim = _getPublicTokensCanClaim();
    require(
      tokenPublicCanClaim - _receivedPublicToken >= amount,
      "Exceed total private token"
    );
    _receivedPublicToken += amount;
    _token.transfer(owner(), amount);
    emit ClaimPrivateToken(amount, owner(), block.timestamp);
  }

  ///@notice release
  function releasePrivateToken(uint256 amount) public onlyOwner {
    uint256 tokenPrivateCanClaim = _getPrivateTokensCanClaim();
    require(
      tokenPrivateCanClaim - _receivedPrivateToken >= amount,
      "Exceed total private token"
    );
    _receivedPrivateToken += amount;
    _token.transfer(owner(), amount);
    emit ClaimPublicToken(amount, owner(), block.timestamp);
  }

  ///@notice public get token over time
  function getPublicTokenCanClaim() public view returns (uint256) {
    return _getPublicTokensCanClaim();
  }

  ///@notice public get token over time
  function getPrivateTokenCanClaim() public view returns (uint256) {
    return _getPrivateTokensCanClaim();
  }
}
