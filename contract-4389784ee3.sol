// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.22;

import {ERC721} from "@openzeppelin/contracts@5.2.0/token/ERC721/ERC721.sol";
import {ERC721Burnable} from "@openzeppelin/contracts@5.2.0/token/ERC721/extensions/ERC721Burnable.sol";
import {ERC721URIStorage} from "@openzeppelin/contracts@5.2.0/token/ERC721/extensions/ERC721URIStorage.sol";
import {Ownable} from "@openzeppelin/contracts@5.2.0/access/Ownable.sol";
import {ERC721Pausable} from "@openzeppelin/contracts@5.2.0/token/ERC721/extensions/ERC721Pausable.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract Army is ERC721, ERC721URIStorage, ERC721Pausable, ERC721Burnable, Ownable, EIP712 {

    
    string private SIGNING_DOMAIN = "ARMY_VOUCHER";
    string private SIGN_VERSION = "1";
    
    uint256 public totalMinted;
    uint256 public max_supply;
    uint256 public publicMintPrice;
    uint256 public fpAllowListPrice;
    uint256 public fpAllowListEndTime;
    uint256 public spAllowListPrice;
    uint256 public spAllowListEndTime;
    uint256 public maximumSpMint;

    bytes32 public fpAllowListRoot;
    bytes32 public spAllowListRoot;

    bool public publicMintLive;
    bool public fpAllowListMintLive;
    bool public spAllowListMintLive;

    constructor(address initialOwner) EIP712(SIGNING_DOMAIN, SIGN_VERSION)
        ERC721("Army", "onchainarmy")
        Ownable(initialOwner)
    {
        totalMinted = 0;
        max_supply = 5000;
        publicMintPrice = 0.042 ether;
        fpAllowListPrice = 0.03 ether;
        publicMintLive = false;
        fpAllowListMintLive = false;
        fpAllowListEndTime = block.timestamp + 30 minutes;
        spAllowListPrice = 0.035 ether;
        spAllowListMintLive = false;
        spAllowListEndTime = block.timestamp + 30 minutes;
        maximumSpMint = 25;
    }

    struct PublicMintVoucher {
        address minter;
        uint256 tokenId;
        string uri;
        bytes signature;
    }

    mapping(uint256 => bool) public mintStatus;
    mapping(address => uint256) public spMinterTotal;

    modifier checkMintStatus(uint256 tokenId) {
        require(mintStatus[tokenId] != true, "token already minted");
        _;
    }

    modifier checkTotalMinted () {
        require(totalMinted <= max_supply, "nft supply reached");
        _;
    }


    // PUBLIC MINTING 
    
    modifier isPublicPrice(uint256 amount) {
        require(amount >= publicMintPrice, "Not enough ether");
        _;
    }

    modifier redeemVoucher(PublicMintVoucher calldata voucher) {
        require(owner() == redeemPublicMintVoucher(voucher), "Wrong signature");
        _;
    }
    
    modifier onlyPublicMintLive() {
        require(publicMintLive == true, "public mint not live yet");
        _;
    }

    function togglePublicMintLive () public onlyOwner{
        publicMintLive = !publicMintLive;
    }

   function redeemPublicMintVoucher(PublicMintVoucher calldata voucher) public view  returns (address) {
       bytes32 digest = _hashTypedDataV4(keccak256(abi.encode(
        keccak256("PublicMintVoucher(address minter,uint256 tokenId,string uri)"),
        voucher.minter,
        voucher.tokenId,
        keccak256(bytes(voucher.uri))
       ))); 

       address signer = ECDSA.recover(digest, voucher.signature);
       return signer;
   }

   function publicMint (PublicMintVoucher calldata voucher) public payable onlyPublicMintLive isPublicPrice(msg.value) redeemVoucher(voucher) {
        mint(voucher.minter, voucher.tokenId, voucher.uri);
   }

   function setPublicMintPrice (uint256 price) public  onlyOwner {
    publicMintPrice = price;
   }

//    FPWHITELIST MINTING

    modifier isFpAllowListPrice(uint256 amount) {
            require(amount >= fpAllowListPrice, "Not enough ether");
            _;
        }
    
   modifier checkFpAllowListEndTime() {
    require(fpAllowListEndTime >= block.timestamp, "Minting phase ended.");
    _;
   }

   modifier validateFpAllowList (bytes32[] memory proof, address minter) {
    require(verifyFpAllowList(proof, keccak256(abi.encodePacked(minter))), "Not a part of Allowlist");
    _;
   }
   modifier onlyFpAllowMintLive() {
        require(fpAllowListMintLive == true, "public mint not live yet");
        _;
    }

    function toggleFpAllowListMintLive () public onlyOwner {
        fpAllowListMintLive = !fpAllowListMintLive;
    }

   function setFpAllowListRoot(bytes32 _root) public onlyOwner {
     fpAllowListRoot = _root;
   }

   function setFpAllowListEndTime () public  onlyOwner {
     fpAllowListEndTime = block.timestamp + 30 minutes;
   }

   function verifyFpAllowList (bytes32[] memory proof, bytes32 leaf) public view  returns (bool)  {
    return MerkleProof.verify(proof, fpAllowListRoot, leaf);
   }

   function fpAllowMint(address minter, uint256 tokenId, string memory uri, bytes32[] memory proof)
    public 
    payable 
    isFpAllowListPrice(msg.value)
    checkFpAllowListEndTime
    validateFpAllowList(proof, minter)
    onlyFpAllowMintLive
    {
       mint(minter, tokenId, uri);
   }

   function setFpAllowListPrice(uint256 price) public onlyOwner {
      fpAllowListPrice = price;
   }

//    SPWHITELIST MINTING

 modifier isSpAllowListPrice(uint256 amount) {
            require(amount >= spAllowListPrice, "Not enough ether");
            _;
        }
    
   modifier checkSpAllowListEndTime() {
    require(spAllowListEndTime >= block.timestamp, "Minting phase ended.");
    _;
   }

   modifier validateSpAllowList (bytes32[] memory proof, address minter) {
    require(verifySpAllowList(proof, keccak256(abi.encodePacked(minter))), "Not a part of Allowlist");
    _;
   }
   modifier onlySpAllowMintLive() {
        require(spAllowListMintLive == true, "public mint not live yet");
        _;
    }

    function toggleSpAllowListMintLive () public onlyOwner {
        spAllowListMintLive = !spAllowListMintLive;
    }

   function setSpAllowListRoot(bytes32 _root) public onlyOwner {
     spAllowListRoot = _root;
   }

   function setSpAllowListEndTime () public  onlyOwner {
     spAllowListEndTime = block.timestamp + 30 minutes;
   }

   function verifySpAllowList (bytes32[] memory proof, bytes32 leaf) public view  returns (bool)  {
    return MerkleProof.verify(proof, spAllowListRoot, leaf);
   }

   function spAllowMint(address minter, uint256 tokenId, string memory uri, bytes32[] memory proof)
    public 
    payable 
    isSpAllowListPrice(msg.value)
    checkSpAllowListEndTime
    validateSpAllowList(proof, minter)
    onlySpAllowMintLive
    {
    require(spMinterTotal[minter] < maximumSpMint, "maximum nft mint reached.");
       mint(minter, tokenId, uri);
       spMinterTotal[minter] = spMinterTotal[minter] + 1;
   }

   function setSpAllowListPrice(uint256 price) public onlyOwner {
      spAllowListPrice = price;
   }
  
  function setMaximumSpMint (uint256 amount) public onlyOwner {
    maximumSpMint = amount;
  }
    


    function mint(address to, uint256 tokenId, string memory uri)
        internal
        checkTotalMinted
        checkMintStatus(tokenId)
    {
        totalMinted = totalMinted + 1;
         mintStatus[tokenId] = true;
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, uri);
    }

   function _update(address to, uint256 tokenId, address auth)
        internal
        override(ERC721, ERC721Pausable)
        returns (address)
    {
        return super._update(to, tokenId, auth);
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

     function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function airdrop(address to, uint256[] memory tokenIds, string[] memory uris) public  onlyOwner {
        require(tokenIds.length == uris.length, "invalid input");
        for (uint i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            string memory uri = uris[i];
            mint(to, tokenId, uri);
        }    
    }

    function withdraw(address to) public onlyOwner {
        payable(to).transfer(address(this).balance);
    }
}

