
 // SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract SimpleBank {
    mapping(address => uint256) private balances;

    event Deposited(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);

    // Gui ETH vao ngan hang
    function deposit() public payable {
        require(msg.value > 0, "Must send ETH");

        balances[msg.sender] += msg.value;

        emit Deposited(msg.sender, msg.value);
    }

    // Rut ETH tu ngan hang
    function withdraw(uint256 amount) public {
        require(amount > 0, "Amount must be positive");
        require(balances[msg.sender] >= amount, "Insufficient balance");

        // Effects: cap nhat so du truoc
        balances[msg.sender] -= amount;

        // Interactions: chuyen ETH sau
        (bool success, ) = payable(msg.sender).call{value: amount}("");
        require(success, "Transfer failed");

        emit Withdrawn(msg.sender, amount);
    }

    // Xem so du cua tai khoan hien tai
    function myBalance() public view returns (uint256) {
        return balances[msg.sender];
    }

    // Xem tong ETH trong hop dong
    function bankTotal() public view returns (uint256) {
        return address(this).balance;
    }
}
