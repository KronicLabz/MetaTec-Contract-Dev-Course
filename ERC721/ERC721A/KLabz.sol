// SPDX-License-Identifier: MIT
// Creator: Chiru Labs
// Amended: KronicLabz

pragma solidity ^0.8.0;

import "./ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract KronicLabz is ERC721A, Ownable{
    using Strings for uint256;

    uint256 public constant MAX_SUPPLY = 9999;
    uint256 public constant MAX_PUBLIC_MINT = 5;
    uint256 public constant MAX_ALLOWLIST_MINT = 3;
    uint256 public constant PUBLIC_SALE_PRICE = .1 ether;
    uint256 public constant ALLOWLIST_SALE_PRICE = .06 ether;

    string private  baseTokenUri;
    string public   placeholderTokenUri;

    //deploy smart contract, toggle WL, toggle WL when done, toggle publicSale 
    //2 days later toggle reveal
    bool public isRevealed;
    bool public publicSale;
    bool public hitlistSale;
    bool public pause;
    bool public teamMinted;

    bytes32 private merkleRoot;

    mapping(address => uint256) public totalPublicMint;
    mapping(address => uint256) public totalHitlistMint;

    constructor() ERC721A("KronicLabz", "METATEC"){

    }

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "KronicLabz :: Cannot be called by a contract");
        _;
    }

    function mint(uint256 _quantity) external payable callerIsUser{
        require(publicSale, "");
        require((totalSupply() + _quantity) <= MAX_SUPPLY, "");
        require((totalPublicMint[msg.sender] +_quantity) <= MAX_PUBLIC_MINT, "");
        require(msg.value >= (PUBLIC_SALE_PRICE * _quantity), "");

        totalPublicMint[msg.sender] += _quantity;
        _safeMint(msg.sender, _quantity);
    }

    function hitlistMint(bytes32[] memory _merkleProof, uint256 _quantity) external payable callerIsUser{
        require(hitlistSale, "");
        require((totalSupply() + _quantity) <= MAX_SUPPLY, "");
        require((totalHitlistMint[msg.sender] + _quantity)  <= MAX_ALLOW_LIST_MINT, "");
        require(msg.value >= (ALLOWLIST_SALE_PRICE * _quantity), "");
        //create leaf node
        bytes32 sender = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(_merkleProof, merkleRoot, sender), "");

        totalHitlistMint[msg.sender] += _quantity;
        _safeMint(msg.sender, _quantity);
    }

    function teamMint() external onlyOwner{
        require(!teamMinted, "");
        teamMinted = true;
        _safeMint(msg.sender, 250);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenUri;
    }

    //return uri for certain token
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "");

        uint256 trueId = tokenId + 1;

        if(!isRevealed){
            return placeholderTokenUri;
        }
        //string memory baseURI = _baseURI();
        return bytes(baseTokenUri).length > 0 ? string(abi.encodePacked(baseTokenUri, trueId.toString(), ".json")) : "";
    }

    function setTokenUri(string memory _baseTokenUri) external onlyOwner{
        baseTokenUri = _baseTokenUri;
    }
    function setPlaceHolderUri(string memory _placeholderTokenUri) external onlyOwner{
        placeholderTokenUri = _placeholderTokenUri;
    }

    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner{
        merkleRoot = _merkleRoot;
    }

    function getMerkleRoot() external view returns (bytes32){
        return merkleRoot;
    }

    function togglePause() external onlyOwner{
        pause = !pause;
    }

    function togglehitlistSale() external onlyOwner{
        hitlistSale = !hitlistSale;
    }

    function togglePublicSale() external onlyOwner{
        publicSale = !publicSale;
    }

    function toggleReveal() external onlyOwner{
        isRevealed = !isRevealed;
    }
      function withdraw() external onlyOwner{
        //70% to utilityProject Wallet
        uint256 withdrawAmount_70 = address(this).balance * 70/100;
        //25% to inverstorWallet
        uint256 withdrawAmount_25 = address(this).balance * 25/100;
        // This will pay KronicLabz 5% of the initial sale.
        // All payments will be dedicated to MetaTec to further 
        // the NFT beginner dev program and to pay for developers 
        // for future propjects and platforms for MetaTec
        uint256 withdrawAmount_5 = address(this).balance  * 5/100;
        payable(0x1333e81C131e1D1D0E8Bd42ecA5E45aCd0cE1De3).transfer(withdrawAmount_70);
        payable(0x08bDc77727433Bb7507D782Cb1a4aBa35987659f).transfer(withdrawAmount_25);
        payable(0xF80ACA20e5a6662182Be45f471097a327aC68fcE).transfer(withdrawAmount_5);
        payable(msg.sender).transfer(address(this).balance);
    }
}
