// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";

library SafeMaths {
  using SafeMath for uint256;

  function percent(uint256 arg, uint256 rate) internal pure returns (uint256) {
    uint256 multiply = arg.mul(rate);
    return multiply.div(100);
  }
}
