
 // SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract Ownable {
    address public owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Not the owner");
        _;
    }

    function transferOwnership(address newOwner)
        public onlyOwner
    {
        require(newOwner != address(0), "Invalid address");

        address oldOwner = owner;
        owner = newOwner;

        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

contract ProtectedVault is Ownable {
    uint256 private treasure;

    event Deposited(address indexed from, uint256 amount);
    event Withdrawn(address indexed to, uint256 amount);

    function deposit() public payable {
        require(msg.value > 0, "Must send ETH");

        treasure += msg.value;
        emit Deposited(msg.sender, msg.value);
    }

    function withdraw(address payable to, uint256 amt)
        public onlyOwner
    {
        require(to != address(0), "Invalid address");
        require(amt <= treasure, "Insufficient balance");

        treasure -= amt;

        (bool success, ) = to.call{value: amt}("");
        require(success, "Transfer failed");

        emit Withdrawn(to, amt);
    }

    function contractBalance()
        public view returns (uint256)
    {
        return address(this).balance;
    }
}
