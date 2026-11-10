
 // SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract Crowdfunding {
    struct Contribution {
        address contributor;
        uint256 amount;
    }

    address payable public owner;
    uint256 public goal;
    uint256 public deadline;
    uint256 public raised;
    bool public claimed;

    mapping(address => uint256) public contributions;

    event Contributed(address indexed contributor, uint256 amount);
    event Claimed(uint256 amount);
    event Refunded(address indexed contributor, uint256 amount);

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    constructor(uint256 _goal, uint256 _durationSeconds) {
        require(_goal > 0 && _durationSeconds > 0, "Invalid settings");
        owner = payable(msg.sender);
        goal = _goal;
        deadline = block.timestamp + _durationSeconds;
    }

    function contribute() external payable {
        require(block.timestamp < deadline, "Campaign ended");
        require(msg.value > 0, "Zero contribution");

        raised += msg.value;
        contributions[msg.sender] += msg.value;
        emit Contributed(msg.sender, msg.value);
    }

    function getRemainingTime() public view returns (uint256) {
        if (block.timestamp >= deadline) return 0;
        return deadline - block.timestamp;
    }

    function claimFunds() external onlyOwner {
        require(block.timestamp >= deadline, "Campaign active");
        require(raised >= goal, "Goal not reached");
        require(!claimed, "Already claimed");

        claimed = true;
        uint256 amount = address(this).balance;

        (bool success, ) = owner.call{value: amount}("");
        require(success, "Transfer failed");
        emit Claimed(amount);
    }

    function refund() external {
        require(block.timestamp >= deadline, "Campaign active");
        require(raised < goal, "Goal reached");

        uint256 amount = contributions[msg.sender];
        require(amount > 0, "Nothing to refund");

        contributions[msg.sender] = 0;

        (bool success, ) = payable(msg.sender).call{value: amount}("");
        require(success, "Refund failed");
        emit Refunded(msg.sender, amount);
    }
}
