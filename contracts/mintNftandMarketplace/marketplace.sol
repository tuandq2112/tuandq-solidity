/**
        Luồng chạy
    acc 1 (seller) đang sở hữu nft
    acc 2 (buyer) đang có token ivi và muốn mua nft

    1. acc 1 gọi approve nft cho contract
       acc 1 gọi hàm makeItem để sét giá bán cho nft

       acc 2 gọi approve token ivi cho contract với số lượng >= giá bán

    2. acc 2 gọi hàm purchaseItem để nhận nft và chuyển token ivi cho seller
 */

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./nft.sol";

contract Marketplace is ReentrancyGuard {

    // địa chỉ token erc20
    IERC20 _token;

    // địa chỉ nft
    NFT _nft;

    // mảng chứa các tokenId đang sell
    uint256[] private _publicStore;

    struct Item {
        IERC721 nft;
        uint tokenId;
        uint price;
        address seller;
        bool sold;
    }

    // tokenId đến data Item tương ứng
    mapping(uint => Item) public items;

    event Offered(
        address nft,
        uint tokenId,
        uint price,
        address seller
    );
    event Bought(
        address nft,
        uint tokenId,
        uint price,
        address seller,
        address buyer
    );

    constructor(IERC20 token, NFT nft) {
        _token = token;
        _nft = NFT(nft);
    }

    // set giá bán nft sau khi seller đã approve nft đó cho contract
    function makeItem(address seller, uint _tokenId, uint _price) public nonReentrant {
        require(_price > 0, "Price must be greater than zero");
        require(_nft.ownerOf(_tokenId) == seller, "seller is not owner of tokenid");
        require(_nft.getApproved(_tokenId) == address(this), "contract not authorized nft"); 
        
        // đẩy data cho item
        items[_tokenId] = Item (
            _nft,
            _tokenId,
            _price,
            seller,
            false
        );

        //thêm tokenId vừa set giá vào danh sách bán 
        _publicStore.push(_tokenId);

        // emit Offered event
        emit Offered(
            address(_nft),
            _tokenId,
            _price,
            seller
        );
    }

    // hàm mua token, buyer phải approve token cho contract trước khi gọi hàm này
    function purchaseItem(address buyer, uint _itemId) public nonReentrant {
        Item storage item = items[_itemId];
        require(_itemId > 0, "item doesn't exist");
        require(_token.allowance(buyer, address(this)) >= item.price, "not enough ether to cover item price and market fee");
        require(!item.sold, "item already sold");
        // pay seller and feeAccount

        // chuyển nft từ seller cho buyer
        _nft.transferNft(item.seller, buyer, item.tokenId);

        // chuyển token từ buyer cho seller
        _token.transferFrom(buyer, item.seller, item.price);
        
        // đặt trạng thái item về true (đã đc mua)
        item.sold = true;

        // xoá tokenId ra khỏi danh sách tokenId đang đc bán
        uint256 i = 0;
        uint256 tokenIdCurrent;
        uint256 length = _publicStore.length;
        while (i < length) {
            tokenIdCurrent = _publicStore[i];
            if (_itemId == tokenIdCurrent) {
                _publicStore[i] = _publicStore[length-1];
                _publicStore.pop();
                break;
            } else {
                i++;
            }
        }

        emit Bought(
            address(item.nft),
            item.tokenId,
            item.price,
            item.seller,
            buyer
        );
    }

    // hàm trả về giá của tokenId
    function getTotalPrice(uint _tokenId) view public returns(uint){
        return(items[_tokenId].price);
    }

    // danh sách các tokenId đang đc bán
    function getListPublicStoreOfAddress() view public returns(uint256[] memory){
        return (_publicStore);
    }
}