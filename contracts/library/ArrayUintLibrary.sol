// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

library ArrayUintLibrary {
  function reduce(uint256[] memory amounts) internal pure returns (uint256) {
    uint256 arrLength = amounts.length;
    uint256 totalAmount = 0;
    for (uint256 i = 0; i < arrLength; i++) {
      totalAmount += amounts[i];
    }
    return totalAmount;
  }
}
