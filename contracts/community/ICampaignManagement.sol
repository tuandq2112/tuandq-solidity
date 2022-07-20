// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/**
 *@author tuan.dq
 *@title  Interface of campaign management contract
 */

interface ICampaignManagement {
  enum AdminConsentStatus {
    NoAction,
    Accept,
    Reject
  }
  enum CampaignStatus {
    NoAction,
    Release,
    Delete
  }
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
    CampaignStatus status;
    uint256 releaseTime;
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
   *  @dev  Emitted when `ADMIN` delete campaign.
   */
  event DeleteCampaign(string indexed campaignName, address indexed account);
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

  function createCampaign(
    string memory campaignName,
    address[] memory accounts,
    uint256[] memory amounts,
    uint256 releaseTime
  ) external;

  function updateCampaign(
    string memory campaignName,
    address[] memory accounts,
    uint256[] memory amounts,
    uint256 releaseTime
  ) external;

  function adminAcceptRelease(string memory campaign) external;

  function adminRejectRelease(string memory campaign) external;

  function release(string memory campaignName, bool passive) external;

  function deleteCampaign(string memory campaignName) external;

  function getDatas() external view returns (DataByTime[] memory);

  function getCampaigns() external view returns (string[] memory);

  function getConsensusByNameAndStatus(
    string memory campaignName,
    AdminConsentStatus status
  ) external view returns (uint256);

  function getCampaign(string memory campaignName)
    external
    view
    returns (Campaign memory);

  function getTotalTokenUnlock() external view returns (uint256);

  function getTotalCanUse() external view returns (uint256);
}
