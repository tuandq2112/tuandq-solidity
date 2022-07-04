// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IAdminConsensus {
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
  event AdminAcceptAdd(address indexed admin, address newAdmin);

  /***
    @dev  Emitted when `account` is rejected consent.
   */
  event AdminRejectAdd(address indexed admin, address newAdmin);

  /***
    @dev  Emitted when `account` is accepted consent.
   */
  event AdminAcceptRevoke(address indexed admin, address oldAdmin);

  /***
    @dev  Emitted when `account` is rejected consent.
   */
  event AdminRejectRevoke(address indexed admin, address oldAdmin);

  function addAdmin(address account) external;

  function revokeAdminRole(address _account) external;

  function renounceAdminRole() external;

  function adminAcceptAdd(address _account) external;

  function adminRejectAdd(address _account) external;

  function adminAcceptRevoke(address _account) external;

  function adminRejectRevoke(address _account) external;
}
