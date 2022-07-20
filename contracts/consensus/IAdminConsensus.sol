// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IAdminConsensus {
  enum ConsentStatus {
    NoAction,
    Accept,
    Reject
  }
  /**
   *  @dev Variables and events for admin
   */
  /***
    @dev  Emitted when has new `ADMIN`.
   */
  event AddAdmin(address indexed performer, address indexed newAdmin);

  /***
    @dev  Emitted when remove a `ADMIN`.
   */
  event RemoveAdmin(address indexed performer, address indexed adminRemoved);
  /***
    @dev  Emitted when `account` is accepted consent.
   */
  event AdminAccept(address indexed admin, address newAdmin);

  /***
    @dev  Emitted when `account` is rejected consent.
   */
  event AdminReject(address indexed admin, address newAdmin);

  function addAdmin(address account) external;

  function revokeAdminRole(address _account) external;

  function renounceAdminRole() external;

  function adminAccept(address _account) external;

  function adminReject(address _account) external;

  function getAdminConsensusByAddressAndStatus(address account, ConsentStatus status)
    external
    view
    returns (uint256);

  function getAdmins() external view returns (address[] memory);
}
