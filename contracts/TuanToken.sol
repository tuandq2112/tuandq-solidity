// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract TuanToken is ERC20, ERC20Burnable, Pausable, AccessControl {
  uint256 private immutable _maxSupply;

  event MinterAccept(address indexed _minterAddr);
  event MinterReject(address indexed _minterAddr);
  event MintConsensus(address indexed _receiverAddr, uint256 _amount);

  address[] private _minters;
  mapping(address => bool) public minterConsent;

  bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
  bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

  constructor() ERC20("TuanToken", "TTK") {
    uint256 fractions = 10**uint256(18);
    _maxSupply = 888888888 * fractions;
    _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    _grantRole(PAUSER_ROLE, msg.sender);
  }

  ///@dev Stop when an emergency occurs.
  function pause() public onlyRole(PAUSER_ROLE) {
    _pause();
  }

  ///@dev Continue to operate normally.
  function unpause() public onlyRole(PAUSER_ROLE) {
    _unpause();
  }

  function mint(address to, uint256 amount)
    public
    onlyRole(DEFAULT_ADMIN_ROLE)
  {
    uint256 totalSupply = totalSupply();
    require(
      totalSupply + amount <= _maxSupply,
      "ERC20: mint amount exceeds max supply"
    );
    _mint(to, amount);
  }

  ///@dev Reject all transaction mint, transfer and burn.
  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 amount
  ) internal override whenNotPaused {
    super._beforeTokenTransfer(from, to, amount);
  }

  ///@dev check account in _minters
  function _inMinters(address _account) private view returns (bool) {
    for (uint256 i = 0; i < _minters.length; i++) {
      address minter = _minters[i];
      if (minter == _account) {
        return true;
      }
    }
    return false;
  }

  ///@dev Grant role for account if account wasn't minter or role is not MINTER ROLE
  function grantRole(bytes32 role, address account) public override {
    if (!_inMinters(account) && role == MINTER_ROLE) {
      _minters.push(account);
    }
    super.grantRole(role, account);
  }

  ///@dev remove minter
  function _removeMinter(address _account) private {
    for (uint256 i = 0; i < _minters.length; i++) {
      address minter = _minters[i];
      if (minter == _account) {
        _minters[i] = _minters[_minters.length - 1];
        _minters.pop();
      }
    }
  }

  ///@dev Remove minter when role is MINTER ROLE
  function revokeRole(bytes32 role, address account) public override {
    if (hasRole(MINTER_ROLE, account)) {
      _removeMinter(account);
    }
    super.revokeRole(role, account);
  }

  ///@dev Remove minter when role is MINTER ROLE
  function renounceRole(bytes32 role, address account) public override {
    if (hasRole(MINTER_ROLE, account)) {
      _removeMinter(account);
    }
    super.renounceRole(role, account);
  }

  /**
   * @dev Minter agree on voting process
   *
   */
  function minterConsensus() public onlyRole(MINTER_ROLE) {
    minterConsent[_msgSender()] = true;
    emit MinterAccept(_msgSender());
  }

  /**
   * @dev Minter disagree on voting process
   *
   */
  function minterReject() public onlyRole(MINTER_ROLE) {
    minterConsent[_msgSender()] = false;
    emit MinterReject(_msgSender());
  }

  ///@dev Minter can mint when all minter accept
  function mintConsensus(address account, uint256 amount)
    public
    onlyRole(MINTER_ROLE)
  {
    uint256 totalSupply = totalSupply();
    require(
      totalSupply + amount <= _maxSupply,
      "ERC20: mint amount exceeds max supply"
    );
    uint256 i;
    address _minter;
    uint256 length = _minters.length;

    for (i = 0; i < length; i++) {
      _minter = _minters[i];
      require(minterConsent[_minter], "At least one minter has not accepted");
    }

    _mint(account, amount);

    for (i = 0; i < length; i++) {
      _minter = _minters[i];
      minterConsent[_minter] = false;
    }

    emit MintConsensus(account, amount);
  }

  function getMinters() public view returns (address[] memory) {
    return _minters;
  }
}