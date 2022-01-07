// contracts/IHealthToken.sol
// SPDX-License-Identifier: MIT

pragma solidity >=0.4.22 <0.9.0;

import "../node_modules/openzeppelin-solidity/contracts/token/ERC20/ERC20.sol";
import "../node_modules/openzeppelin-solidity/contracts/access/AccessControlEnumerable.sol";

contract IHealthToken is ERC20, AccessControlEnumerable {

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");

    address[] private minterList;
    address[] private burnerList;

    bool private minterFlag;
    bool private burnerFlag;

    constructor() ERC20("IHEALTHCoin", "IHI") {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(MINTER_ROLE, _msgSender());
        _setupRole(BURNER_ROLE, _msgSender());
        minterFlag = false;
        burnerFlag = false;
    }

    function mint(address to, uint256 amount) public onlyRole(MINTER_ROLE) {
        _mint(to, amount);
    }

    function burn(address from, uint256 amount) public onlyRole(BURNER_ROLE) {
        _burn(from, amount);
    }

    function grantMinterRole(address minter) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _setupRole(MINTER_ROLE, minter);
        minterFlag = false;
    }

    function grantBurnerRole(address burner) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _setupRole(BURNER_ROLE, burner);
        burnerFlag = false;
    }

    function revokeMinterRole(address minter) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _revokeRole(MINTER_ROLE, minter);
        minterFlag = false;
    }

    function revokeBurnerRole(address minter) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _revokeRole(BURNER_ROLE, minter);
        burnerFlag = false;
    }

    function updateMinterList() public {
        uint256 prevListLength = minterList.length;
        uint256 i;

        for (i = 0; i< prevListLength; i++) {
            minterList.pop();
        }

        uint256 minterCount = getRoleMemberCount(MINTER_ROLE);
        for (i = 0; i < minterCount; i++) {
            minterList.push(getRoleMember(MINTER_ROLE, i));
        }
        minterFlag = true;
    }

    function updateBurnerList() public {
        uint256 prevListLength = burnerList.length;
        uint256 i;

        for (i = 0; i< prevListLength; i++) {
            burnerList.pop();
        }

        uint256 burnerCount = getRoleMemberCount(BURNER_ROLE);
        for (i = 0; i < burnerCount; i++) {
            burnerList.push(getRoleMember(BURNER_ROLE, i));
        }
        burnerFlag = true;
    }

    function getMinterList() public view returns (address[] memory) {
        require(minterFlag, "Call updateMinterList() before calling this function");
        return minterList;
    }

    function getBurnerList() public view returns (address[] memory) {
        require(burnerFlag, "Call updateBurnerList() before calling this function");
        return burnerList;
    }
}