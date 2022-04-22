// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;    
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract VestingSchedule is Ownable {

  struct Investor {
      address investorAddress;
      uint256 investmentAmount;
      uint256 tokenReceived;
      bool active;
  }
  uint8 private _times;
  uint256 private _lockTime; // unit minutes
  uint256 private _startTime;
  uint256 private _count;
  Investor[] private _investors;
  IERC20 private _token;
  address private _tokenAddress;
  event ADDINVESTOR(address _investorAddress, uint256 _amount);

  constructor(uint8 times, uint256 lockTime, address token) {
      _times = times;
      _lockTime = lockTime;
      _token = IERC20(token);
      _tokenAddress = token;
  }
  
  function getTokenAddress() public view returns(address){
      return _tokenAddress;
  }

  function reset(uint8 times, uint256 lockTime, IERC20 token) public onlyOwner {
      _times = times;
      _lockTime = lockTime;
      _token = token; 
  }

  function _getTotalCoin() private view returns (uint256) {
      uint256 totalCoin = 0;
      for(uint256 i = 0; i < _investors.length; i++){
          totalCoin = totalCoin + _investors[i].investmentAmount;
      } 
      return totalCoin;
  }

  function _getAllowance() private view returns (uint256) {
      return _token.allowance(owner(), address(this));
  }

  function _hasInvestor(address _investorAddress) private view returns(bool) {
      for(uint256 i = 0; i < _investors.length; i++){
          if(_investors[i].investorAddress == _investorAddress){
              return true;
          }
      }
      return false;
  }
  
  function addInvestor(address investorAddress, uint256 investmentAmount) public onlyOwner {
      require(block.timestamp < _startTime || _startTime == 0, "Overtime for registration");
      require(_getAllowance() >= _getTotalCoin() + investmentAmount, "Exceed allowance");
      _investors.push(Investor(investorAddress, investmentAmount, 0, true));
      emit ADDINVESTOR(investorAddress, investmentAmount);
  }

  function start() public onlyOwner {
      _startTime = block.timestamp;
  }

  function delay(uint256 delayTime) public onlyOwner {
      _startTime += delayTime * 1 minutes;
  }

  function inActiveInvestor(address investorAddress) public onlyOwner {
    require(block.timestamp < _startTime || _startTime ==0, "Overtime for inactive");
    for(uint256 i = 0; i < _investors.length; i++){
        if(_investors[i].investorAddress == investorAddress){
            _investors[i].active = false;
        }
    }
  }
 
  function getInvestorByAddress(address investorAddress) public view returns (Investor memory){
      require(_hasInvestor(investorAddress), "Not found investor");
      Investor memory _investor;
      for(uint256 i = 0; i < _investors.length; i++){
          if(_investors[i].investorAddress == investorAddress){
              _investor = _investors[i];
          }
      }
      return _investor;
  }

  function sendCoinForInvestor() public onlyOwner {
    require(_startTime != 0, "The schedule hasn't started yet");
    require(_count < _times, "The schedule has ended");
    require(block.timestamp > _startTime +  (_count + 1) * _lockTime * 1 minutes, "Not until unlock time");
    _count++;
    for(uint256 i = 0; i < _investors.length; i++){
        Investor memory _investor = _investors[i];
        if(_investor.active == true){
          uint256 _amountToSend;
          if(_count > _times){
              _amountToSend =  _investor.investmentAmount - _investor.tokenReceived;
          } else{
              _amountToSend =  _investor.investmentAmount / _times;
          }
          _investor.tokenReceived += _amountToSend;
          _token.transferFrom(owner(), _investor.investorAddress, _amountToSend);

        }
      }
  }

}