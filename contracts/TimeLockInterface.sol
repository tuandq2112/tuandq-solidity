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
  function addInvestor(
    address[] memory investorAddresses,
    uint256[] memory amounts
  ) external;

  function setTimesAndRate(
    uint256 times,
    uint256[] memory rates,
    uint256[] memory listTime
  ) external;

  function start() external;

  ///@notice Delay phase
  function reStart() external;

  ///@notice Release phase
  function release() external;

  ///@notice Finished phase 
  function reset() external;
}
