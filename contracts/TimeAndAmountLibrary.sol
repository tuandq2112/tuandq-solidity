// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

library TimeAndAmountLibrary {
  struct TimeAndAmount {
    uint256 time;
    uint256 amount;
  }

  function addToList(
    TimeAndAmount[] storage listTimeAndAmount,
    uint256[] memory listTime,
    uint256[] memory listAmount,
    uint256 currentTime
  ) internal {
    require(
      listTime.length == listAmount.length,
      "Number of time is not equal number of amount"
    );
    uint256 countTime = currentTime;
    for (uint256 i = 0; i < listTime.length; i++) {
      countTime += listTime[0];
      listTimeAndAmount.push(TimeAndAmount(countTime, listAmount[i]));
    }
  }

  function countAmountByTime(
    TimeAndAmount[] memory listTimeAndAmount,
    uint256 currentTime
  ) internal pure returns (uint256) {
    uint256 totalAmount = 0;
    for (uint256 i = 0; i < listTimeAndAmount.length; i++) {
      if (listTimeAndAmount[i].time <= currentTime) {
        totalAmount += listTimeAndAmount[i].amount;
      } else {
        break;
      }
    }
    return totalAmount;
  }
}
