// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

/**
 *@author Ivirse team
 *@title  Interface of timelock contract
 */

interface TimeLockInterface {
  ///@notice Prepare phase
  ///@dev thêm investor với đầu vào là 2 list : investorAddresses 1 list địa chỉ ứng vào amounts 1 list tiền mà địa chỉ tương ứng có thể claims
  function addInvestor(
    address[] memory investorAddresses,
    uint256[] memory amounts
  ) external;

  ///@dev set thời gian và tỷ lệ => times số lần claims, rates tỷ lệ claim mỗi lần tổng = 100%, listime thời gian tương ứng với từng lần claims(chú ý: times = rates.length = listime.length)
  function setTimesAndRate(uint256[] memory rates, uint256[] memory listTime)
    external;

  ///@dev bắt đầu đếm thời gian từ prepare phase chuyển từ trạng thái prepare =>  release
  function start() external;

  ///@notice Delay phase
  ///@dev bắt đầu đếm thời giạn lại nhưng từ trạng thái delay => trạng thái release
  function reStart() external;

  ///@notice Release phase
  ///@dev Ủy quyền tiền cho từng người từ trạng thái release về delay
  function release() external;

  ///@notice Finished phase
  function reset() external;
}
