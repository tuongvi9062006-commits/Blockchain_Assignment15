
 // SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract StakingRewards {
    address payable public owner;
    uint256 public rewardRatePerSecond;
    uint256 public totalStaked;
    uint256 public rewardPool;

    struct Stake {
        uint256 amount;
        uint256 startTime;
        uint256 rewardDebt;
    }

    mapping(address => Stake) public stakes;

    event Staked(address indexed user, uint256 amount);
    event RewardClaimed(address indexed user, uint256 reward);
    event Unstaked(address indexed user, uint256 principal, uint256 reward);
    event RewardsFunded(uint256 amount);
    event RateChanged(uint256 rate);

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    constructor(uint256 _rate) payable {
        owner = payable(msg.sender);
        rewardRatePerSecond = _rate;
        rewardPool = msg.value;
    }

    function pendingReward(address user) public view returns (uint256) {
        Stake memory s = stakes[user];

        if (s.amount == 0) {
            return s.rewardDebt;
        }

        return s.rewardDebt +
            s.amount * rewardRatePerSecond *
            (block.timestamp - s.startTime) / 1 ether;
    }

    function stake() external payable {
        require(msg.value > 0, "Zero stake");

        Stake storage s = stakes[msg.sender];
        uint256 accrued = pendingReward(msg.sender);

        s.rewardDebt = accrued;
        s.amount += msg.value;
        s.startTime = block.timestamp;
        totalStaked += msg.value;

        emit Staked(msg.sender, msg.value);
    }

    function claimReward() external {
        Stake storage s = stakes[msg.sender];
        require(s.amount > 0, "No stake");

        uint256 reward = pendingReward(msg.sender);
        require(reward > 0, "No reward yet");
        require(rewardPool >= reward, "Insufficient reward pool");

        rewardPool -= reward;
        s.rewardDebt = 0;
        s.startTime = block.timestamp;

        (bool success, ) = payable(msg.sender).call{value: reward}("");
        require(success, "Transfer failed");

        emit RewardClaimed(msg.sender, reward);
    }

    function unstake() external {
        Stake storage s = stakes[msg.sender];

        uint256 principal = s.amount;
        require(principal > 0, "No stake");

        uint256 reward = pendingReward(msg.sender);
        require(rewardPool >= reward, "Insufficient reward pool");

        rewardPool -= reward;
        totalStaked -= principal;
        delete stakes[msg.sender];

        (bool success, ) = payable(msg.sender).call{
            value: principal + reward
        }("");

        require(success, "Transfer failed");
        emit Unstaked(msg.sender, principal, reward);
    }

    function fundRewards() external payable onlyOwner {
        require(msg.value > 0, "Zero funding");
        rewardPool += msg.value;
        emit RewardsFunded(msg.value);
    }

    function setRewardRate(uint256 _newRate) external onlyOwner {
        require(totalStaked == 0, "Active stakes: rate locked");
        rewardRatePerSecond = _newRate;
        emit RateChanged(_newRate);
    }
}
