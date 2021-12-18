// contracts/GLDToken.sol
// SPDX-License-Identifier: MIT

pragma solidity >=0.4.22 <0.9.0;

import "../node_modules/openzeppelin-solidity/contracts/token/ERC20/ERC20.sol";

contract IvirseToken is ERC20 {
    constructor(uint256 initialSupply) ERC20("Gold", "IVIRSE") {
        _mint(msg.sender, initialSupply); // Assign a supply to the addres deploy the contract
    }
}

contract IvirseWithAutoMinerReward is ERC20 {
    constructor() ERC20("Reward", "RWD") {}

    function _mintMinerReward() internal {
        _mint(block.coinbase, 1000);
    }

    // Incentive mechanism for clients
    function _beforeTokenTransfer(address from, address to, uint256 value) internal virtual override {
        if (!(from == address(0) && to == block.coinbase)) {
          _mintMinerReward();
        }
        super._beforeTokenTransfer(from, to, value);
    }
}