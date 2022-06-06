// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./consensus/AdminConsensus.sol";
import "./CommunityInterface.sol";

/**
 *@author tuan.dq
 *@title Smart contract for vesting schedule of teams.
 */

contract Community is AdminConsensus, CommunityInterface {
  /**
   *@dev Using safe math library for uin256
   */

  mapping(string => mapping(string => mapping(address => bool)))
    private _adminConsents;

  using SafeERC20 for IERC20;
  /**
   *@dev mapping string to group;
   */
  mapping(string => Group) private _teams;

  string[] private _groupNames;

  function createCampaign(
    string memory groupName,
    string memory campaignName,
    address[] memory accounts,
    uint256[] memory amounts,
    uint256 payTime
  ) public override onlyAdmin {}

  function getGroupNames() public view override returns (string[] memory) {
    return _groupNames;
  }

  /**
   *  @dev  Admin accept for batch release token.
   */
  function adminAcceptRelease(string memory name) public onlyAdmin {
    // _adminConsents[name][msg.sender] = true;
    // emit AdminAcceptRelease(msg.sender, name);
  }

  /**
   *  @dev  Admin reject for batch release token.
   */
  function adminRejectRelease(string memory name) public onlyAdmin {
    // _adminConsents[name][msg.sender] = false;
    // emit AdminRejectRelease(msg.sender, name);
  }
}
