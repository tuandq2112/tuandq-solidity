// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract VestingShark is Ownable {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    ///@notice địa chỉ token erc20
    IERC20 private _token;

    ///@notice mảng địa chỉ investor
    address public investor;

    ///@notice tổng số token của tất cả các investor
    uint256 public totalAmount = 0;

    ///@notice cấu trúc lưu thời gian khoá và tỉ lệ mỗi vòng vesting
    struct timesAndRate {
        uint256 timeLock;
        uint256 rate;
    }

    ///@notice số lần vesting
    uint256 public timesVesting;

    ///@notice từ lần vesting -> thời gian khoá và tỉ lệ
    mapping(uint256 => timesAndRate) private _phase;

    ///@notice kiểm tra xem admin đã chuyển owner sang user hay chưa
    bool public transferOwnerToUser = false;

    ///@notice kiểm tra số token user đã claim
    uint256 public amountClaimed = 0;


    /**
     * @dev cài đặt địa chỉ token erc20, tổng số lượng token, tỉ lệ và thời gian vesting
     *
     * Tổng các phần tử trong rate_ phải băng 100
     * Phần tử trong timeLock_ nên lớn hơn 15s 
    */
    constructor (
        IERC20 tokenAddr_, 
        address investorAddr_,
        uint256 totalAmount_, 
        uint256[] memory rate_,
        uint256[] memory time_ 
        ) {
        require(rate_.length == time_.length, "must have the same length");

        _token = tokenAddr_;
        investor = investorAddr_;
        totalAmount = totalAmount_;
        timesVesting = rate_.length;

        /**
         * @notice cộng dồn các khoảng thời gian để chạy lần lượt
         *
         * ví dụ có mảng thời gian [15, 30, 45]
         * --> _phase[0].timeLock = now + 15
         * --> _phase[1].timeLock = now + 15 + 30
         * --> _phase[2].timeLock = now + 15 + 30 + 45
        */
        uint256 countTime = 0;
        for(uint256 i = 0; i < timesVesting; i ++) {
            countTime = countTime + time_[i];
            _phase[i].timeLock = block.timestamp + countTime;
            _phase[i].rate = rate_[i];
        }
    }

    /**
     * @return số token trong contract
    */
    function balanceContract() public view returns(uint256) {
        return _token.balanceOf(address(this));
    }

    /**
     * @dev admin chuyển owner cho user duy nhất 1 lần, sau đó không thể chuyển được nữa
    */
    function transferOwner() public onlyOwner {
        require(transferOwnerToUser == false, "not transfer owner");
        transferOwnership(investor);
        transferOwnerToUser = true;
    }

    /**
   * @dev hàm tính tỉ lệ phần trăm
   */
    function percent(uint256 arg, uint256 rate) private pure returns (uint256) {
        uint256 multiply = arg.mul(rate);
        return multiply.div(100);
    }

    /**
     * @dev kiểm tra xem đã đủ thời gian của phase nào, và có thể claim được bao nhiêu coin
     *
     * @return tổng số token đã được unlock
    */
    function checkTokenCanClaim() public view returns(uint256) {

        uint256 amountUnlock = 0;
        for(uint256 i = 0; i < timesVesting; i ++) {
            if(block.timestamp >= _phase[i].timeLock) {
                amountUnlock = amountUnlock + percent(totalAmount, _phase[i].rate);
            }
        }
        return amountUnlock;
    }

    /**
     * @dev nếu có token đã unlock, owner transfer token về ví
     *
     * admin phải chuyển đủ token erc 20 vào contract, nếu không hàm safeTransfer sẽ lỗi 
    */
    function claimToken(uint256 amount) public onlyOwner {
        uint256 amountUnlock = checkTokenCanClaim();
        require(amountUnlock >= amount + amountClaimed, "can not claim token");

        require(balanceContract() >= amount, "no have token to transfer");

        _token.safeTransfer(investor, amount);
        amountClaimed = amountClaimed + amount;
    }

}
