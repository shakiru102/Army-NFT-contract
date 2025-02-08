// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.22;

import {ERC721} from "@openzeppelin/contracts@5.2.0/token/ERC721/ERC721.sol";
import {ERC721Burnable} from "@openzeppelin/contracts@5.2.0/token/ERC721/extensions/ERC721Burnable.sol";
import {ERC721URIStorage} from "@openzeppelin/contracts@5.2.0/token/ERC721/extensions/ERC721URIStorage.sol";
import {Ownable} from "@openzeppelin/contracts@5.2.0/access/Ownable.sol";
import "@openzeppelin/contracts@4.7.3/utils/cryptography/draft-EIP712.sol";

contract Army is ERC721, ERC721URIStorage, ERC721Burnable, Ownable, EIP712 {

    address _initalOwner;
    
    string private SIGNING_DOMAIN = "ARMY_VOUCHER";
    string private SIGN_VERSION = "1.0";
    
    uint256 public totalMinted;
    uint256 public max_supply;
    uint256 public publicMintPrice;

    bool public isPublicMintLive = false;

    constructor(address initialOwner) EIP712(SIGNING_DOMAIN, SIGN_VERSION)
        ERC721("Army", "onchainarmy")
        Ownable(initialOwner)
    {}

    struct PublicMintVoucher {
        address minter;
        string tokenId;
        string uri;
        bytes signer;
    }




    function safeMint(address to, uint256 tokenId, string memory uri)
        public
        onlyOwner
    {
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, uri);
    }

    // The following functions are overrides required by Solidity.

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
