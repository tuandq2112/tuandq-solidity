// contracts/IHealthToken.sol
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";

contract IHealthToken is ERC20, AccessControlEnumerable {

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");

    address[] private minterList;
    address[] private burnerList;

    bool private minterFlag;
    bool private burnerFlag;

    event AddMinter(address indexed _minter);
    event AddBurner(address indexed _burner);
    event RemoveMinter(address indexed _minter);
    event RemoveBurner(address indexed _burner);
    
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
        emit AddMinter(minter);
    }

    function grantBurnerRole(address burner) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _setupRole(BURNER_ROLE, burner);
        burnerFlag = false;
        emit AddBurner(burner);
    }

    function revokeMinterRole(address minter) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _revokeRole(MINTER_ROLE, minter);
        minterFlag = false;
        emit RemoveMinter(minter);
    }

    function revokeBurnerRole(address burner) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _revokeRole(BURNER_ROLE, burner);
        burnerFlag = false;
        emit RemoveBurner(burner);
    }

    function updateMinterList() public {
        require(minterFlag == false, "Minter List is up to date");
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
        require(burnerFlag == false, "Burner List is up to date");
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

