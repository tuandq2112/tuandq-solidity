// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";

contract NFT is ERC721URIStorage {

    // lấy token id
    uint256 private tokenId;

    //mảng các nft do địa chỉ sở hữu
    mapping(address=>uint256[]) private _nftsOfAddress;

    constructor() ERC721("NFT MARKETPLACE", "NM"){}

    //hàm tạo nft
    function mint(string memory _tokenURI) public returns(uint) {
        tokenId ++;
        _safeMint(msg.sender, tokenId);
        _setTokenURI(tokenId, _tokenURI);

        // thêm tokenId mà msg.sender vừa tạo vào mảng lưu trữ
        _nftsOfAddress[msg.sender].push(tokenId);
        return(tokenId);
    }

    //trả về mảng các nft do địa chỉ sở hữu
    function checkNftsOfAddress(address acc) view public returns(uint[] memory) {
        return _nftsOfAddress[acc];
    }

    // hàm chuyển nft 
    function transferNft(address from, address to, uint256 id) public {
        transferFrom(from, to, id);

        //xoá tokenId mà "from" vừa chuyển cho "to"
        uint256 i = 0;
        uint256 tokenIdCurrent;
        uint256 length = _nftsOfAddress[from].length;
        while (i < length) {
            tokenIdCurrent = _nftsOfAddress[from][i];
            if (id == tokenIdCurrent) {
                _nftsOfAddress[from][i] = _nftsOfAddress[from][length-1];
                _nftsOfAddress[from].pop();
                break;
            } else {
                i++;
            }
        }

        // thêm tokenId mà "to" vừa nhận đc
        _nftsOfAddress[to].push(id);
    }
}