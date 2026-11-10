
 // SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract SimpleNFT {
    string public name = "SimpleNFT";
    string public symbol = "SNFT";
    address payable public owner;

    uint256 public nextTokenId;
    uint256 public constant MAX_SUPPLY = 100;
    uint256 public mintPrice = 0.01 ether;

    mapping(uint256 => address) public ownerOf;
    mapping(address => uint256) public balances;
    mapping(uint256 => address) public approvals;

    event Minted(address indexed to, uint256 indexed tokenId);
    event TransferNFT(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed spender, uint256 indexed tokenId);

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    constructor() {
        owner = payable(msg.sender);
    }

    function mint() external payable returns (uint256) {
        require(msg.value == mintPrice, "Wrong mint price");
        require(nextTokenId < MAX_SUPPLY, "Sold out");

        uint256 id = nextTokenId++;
        ownerOf[id] = msg.sender;
        balances[msg.sender]++;

        emit Minted(msg.sender, id);
        emit TransferNFT(address(0), msg.sender, id);
        return id;
    }

    function _transfer(address from, address to, uint256 tokenId) internal {
        require(to != address(0), "Invalid recipient");
        require(ownerOf[tokenId] == from, "Not token owner");

        delete approvals[tokenId];
        ownerOf[tokenId] = to;
        balances[from]--;
        balances[to]++;

        emit TransferNFT(from, to, tokenId);
    }

    function transferNFT(address to, uint256 tokenId) external {
        require(ownerOf[tokenId] == msg.sender, "Not token owner");
        _transfer(msg.sender, to, tokenId);
    }

    function approve(address spender, uint256 tokenId) external {
        require(ownerOf[tokenId] == msg.sender, "Not token owner");
        approvals[tokenId] = spender;
        emit Approval(msg.sender, spender, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId) external {
        require(approvals[tokenId] == msg.sender, "Not approved");
        _transfer(from, to, tokenId);
    }

    function withdrawPayments() external onlyOwner {
        uint256 amount = address(this).balance;
        require(amount > 0, "No payments");

        (bool success, ) = owner.call{value: amount}("");
        require(success, "Transfer failed");
    }
}
