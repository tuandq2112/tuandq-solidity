// contracts/IvirseToken.sol
// SPDX-License-Identifier: MIT

pragma solidity >=0.4.22 <0.9.0;

import "../node_modules/openzeppelin-solidity/contracts/token/ERC20/ERC20.sol";
import "../node_modules/openzeppelin-solidity/contracts/access/Ownable.sol";

contract IvirseToken is ERC20, Ownable {

    uint256 private _maxSupply; 
    uint256 private _totalSupply;

    event MinterAdded(address indexed _minterAddr);
    event MinterRemoved(address indexed _minterAddr);

    mapping (address => bool ) public minter; 
    mapping (address => bool ) public minterConsent;

    address[] private minterList;

    /**
    * @dev Sets the values for {name}, {_maxSupply} and {symbol}, initializes {decimals} with
    * a default value of 18.
    *
    * To select a different value for {decimals}, use {_setupDecimals}.
    *
    * All three of these values are immutable: they can only be set once during
    * construction.
    */
    constructor() ERC20("IVIE", "IVI") {
        uint256 fractions = 10**uint256(18);
        _maxSupply = 888888888 * fractions;
        addMinter(_msgSender());
    }

    /**
    * @dev Returns the maxSupply of the token.
    */
    function maxSupply() public view returns (uint256) {
        return _maxSupply;
    }    

    /**
    * @dev Issues `amount` tokens to the designated `address`.
    *
    * Can only be called by the current owner.
    * See {ERC20-_mint}.
    */
    function mint(address account, uint256 amount) public onlyOwner {
        _totalSupply = totalSupply();
        require(_totalSupply + amount <= _maxSupply, "ERC20: mint amount exceeds max supply");
        _mint(account, amount);
    }    

    /**
    * @dev Destroys `amount` tokens from the caller.
    *
    * See {ERC20-_burn}.
    */ 
    function burn(uint256 amount) public {
        _burn(_msgSender(), amount);
    }

    /**
     * @dev Throws if called by any account other than the minter.
     */
    modifier onlyMinter() {
        require(minter[msg.sender], "Only-minter");
        _;
    }

    /**
    * @dev Add '_minterAddr' to the {minterList}
    *
    */ 
    function addMinter(address _minterAddr) public onlyOwner{
        require(!minter[_minterAddr], "Is minter");
        minterList.push(_minterAddr);
        minter[_minterAddr] = true;
        minterConsent[_minterAddr] = false;
        emit MinterAdded(_minterAddr);
    }

    /**
    * @dev Remove '_minterAddr' out of the {minterList}
    *
    */ 
    function removeMinter(address _minterAddr) public onlyOwner{
        require(minter[_minterAddr], "Not minter");
        minter[_minterAddr] = false;
        // minterConsent[_minterAddr] = true;
        emit MinterRemoved(_minterAddr);
        
        uint256 i = 0;
        address _minter;
        while (i < minterList.length) {
            _minter = minterList[i];
            if (!minter[_minter]) {
                minterList[i] = minterList[minterList.length - 1];
                delete minterList[minterList.length - 1];
                minterList.pop();
            } else {
                i++;
            }
        }
    }
    /**
    * @dev Returns the list of minter in {minterList}
    *
    */ 
    function getMinters() public view returns (address[] memory){
        return minterList;
    }

    /**
    * @dev Minter agree on voting process
    *
    */ 
    function minterConsensus() public onlyMinter {
        minterConsent[_msgSender()] = true;
    }

    /**
    * @dev Minter disagree on voting process
    *
    */ 
    function minterReject() public onlyMinter {
        minterConsent[_msgSender()] = false;
    }

    /**
    * @dev Issues `amount` tokens to the designated `address`.
    *
    * Can only be called by the current minter with acceptance from other minters.
    * See {ERC20-_mint}.
    */
    function mintConsensus(address account, uint256 amount) public onlyMinter {
        _totalSupply = totalSupply();
        require(_totalSupply + amount <= _maxSupply, "ERC20: mint amount exceeds max supply");
        uint256 i;
        address _minter;
        uint256 length = minterList.length;

        for (i = 0; i < length; i++) {
            _minter = minterList[i];
            require(minterConsent[_minter], "At least one minter has not accepted");
        }
        _mint(account, amount);

        for (i = 0; i < length; i++) {
            _minter = minterList[i];
            minterConsent[_minter] = false;
        }
    } 
}
