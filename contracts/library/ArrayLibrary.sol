// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

library ArrayLibrary {
  function isExist(address[] memory accounts, address account)
    internal
    pure
    returns (bool)
  {
    for (uint256 i = 0; i < accounts.length; i++) {
      if (accounts[i] == account) {
        return true;
      }
    }
    return false;
  }

  function remove(address[] storage accounts, address account) internal {
    uint256 arrLength = accounts.length;
    for (uint256 i = 0; i < arrLength; i++) {
      if (accounts[i] == account) {
        accounts[i] = accounts[arrLength - 1];
        accounts.pop();
        break;
      }
    }
  }

  
}
