// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/**
 *@author tuan.dq
 *@title  Interface of community contract
 */

interface CommunityInterface {
  struct Member {
    address accounts;
    uint256 amounts;
  }

  struct Campaign {
    Member[] members;
    uint256 payTime;
  }

  struct TimeClaim {
    uint256 unlockTime;
    uint256 amount;
  }
  struct Group {
    TimeClaim[] timeClaims;
    mapping(string => Campaign) campaigns;
    string[] campaignNames;
  }

  function createCampaign(
    string memory groupName,
    string memory campaignName,
    address[] memory accounts,
    uint256[] memory amounts,
    uint256 payTime
  ) external;

  function getGroupNames() external view returns (string[] memory);
}
