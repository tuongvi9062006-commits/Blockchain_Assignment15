
 // SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract EnglishAuction {
    address payable public seller;
    uint256 public auctionEnd;
    address public highestBidder;
    uint256 public highestBid;
    uint256 public constant MIN_INCREMENT = 5;

    mapping(address => uint256) public pendingReturns;
    bool public ended;

    event NewBid(address indexed bidder, uint256 amount);
    event AuctionEnded(address winner, uint256 amount);

    constructor(uint256 _biddingSeconds, uint256 _startPrice) {
        require(_biddingSeconds > 0 && _startPrice > 0, "Invalid settings");
        seller = payable(msg.sender);
        auctionEnd = block.timestamp + _biddingSeconds;
        highestBid = _startPrice;
    }

    function bid() external payable {
        require(!ended && block.timestamp < auctionEnd, "Auction closed");

        uint256 minBid = highestBidder == address(0)
            ? highestBid
            : highestBid + ((highestBid * MIN_INCREMENT + 99) / 100);

        require(msg.value >= minBid, "Bid too low");

        if (highestBidder != address(0)) {
            pendingReturns[highestBidder] += highestBid;
        }

        highestBidder = msg.sender;
        highestBid = msg.value;

        emit NewBid(msg.sender, msg.value);
    }

    function withdrawPending() external returns (bool) {
        uint256 amount = pendingReturns[msg.sender];
        require(amount > 0, "No refund");

        pendingReturns[msg.sender] = 0;

        (bool success, ) = payable(msg.sender).call{value: amount}("");
        require(success, "Refund failed");
        return true;
    }

    function endAuction() external {
        require(block.timestamp >= auctionEnd, "Auction active");
        require(!ended, "Already ended");

        ended = true;
        uint256 amount = highestBidder == address(0) ? 0 : highestBid;

        emit AuctionEnded(highestBidder, amount);

        if (amount > 0) {
            (bool success, ) = seller.call{value: amount}("");
            require(success, "Payment failed");
        }
    }
}
