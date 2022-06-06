// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/**
 *@author tuan.dq
 *@title  Interface of campaign management contract
 */

interface ICampaignManagement {
  /**
   *@dev struct for data in once time.
   */
  struct DataByTime {
    uint256 unlockTime;
    uint256 amount;
  }
  /**
   *@dev struct for a participant.
   */
  struct Participant {
    address account;
    uint256 amount;
  }

  /**
   *@dev struct for a participant.
   */
  struct Campaign {
    Participant[] participants;
    bool isClaimed;
  }
  /**
   *  @dev  Emitted when `ADMIN` create campaign.
   */
  event ChangeCampaign(
    string campaignName,
    address[] accounts,
    uint256[] amounts,
    bool isUpdate
  );
  /**
   *  @dev  Emitted when `account` is accepted consent.
   */
  event AdminAcceptRelease(address indexed account, string indexed campaign);

  /**
   *  @dev  Emitted when `account` is rejected consent.
   */
  event AdminRejectRelease(address indexed account, string indexed campaign);

  /**
   *  @dev  Emitted when `ADMIN` release token.
   */
  event Release(string campaignName);
}
