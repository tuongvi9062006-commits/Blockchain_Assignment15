
 // SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract Escrow {
    enum State {
        AwaitingPayment,
        AwaitingDelivery,
        Complete,
        Refunded,
        Disputed
    }

    address payable public buyer;
    address payable public seller;
    address payable public arbiter;
    State public state;

    event StateChanged(State newState);
    event Paid(address indexed to, uint256 amount);

    modifier onlyBuyer() {
        require(msg.sender == buyer, "Not buyer");
        _;
    }

    modifier onlyArbiter() {
        require(msg.sender == arbiter, "Not arbiter");
        _;
    }

    modifier onlyBuyerOrSeller() {
        require(msg.sender == buyer || msg.sender == seller, "Not party");
        _;
    }

    modifier onlyArbiterOrSeller() {
        require(msg.sender == arbiter || msg.sender == seller, "Not arbiter or seller");
        _;
    }

    modifier stateCheck(State expected) {
        require(state == expected, "Wrong state");
        _;
    }

    constructor(address payable _seller, address payable _arbiter) payable {
        require(msg.value > 0, "Payment required");
        require(_seller != address(0) && _arbiter != address(0), "Invalid address");
        require(
            _seller != msg.sender &&
            _arbiter != msg.sender &&
            _seller != _arbiter,
            "Distinct parties required"
        );

        buyer = payable(msg.sender);
        seller = _seller;
        arbiter = _arbiter;
        state = State.AwaitingDelivery;
        emit StateChanged(state);
    }

    function _pay(address payable to) private {
        uint256 amount = address(this).balance;
        (bool success, ) = to.call{value: amount}("");
        require(success, "Transfer failed");
        emit Paid(to, amount);
    }

    function confirmDelivery() external onlyBuyer stateCheck(State.AwaitingDelivery) {
        state = State.Complete;
        emit StateChanged(state);
        _pay(seller);
    }

    function refundBuyer() external onlyArbiterOrSeller stateCheck(State.AwaitingDelivery) {
        state = State.Refunded;
        emit StateChanged(state);
        _pay(buyer);
    }

    function raiseDispute() external onlyBuyerOrSeller stateCheck(State.AwaitingDelivery) {
        state = State.Disputed;
        emit StateChanged(state);
    }

    function resolveToSeller() external onlyArbiter stateCheck(State.Disputed) {
        state = State.Complete;
        emit StateChanged(state);
        _pay(seller);
    }

    function resolveToBuyer() external onlyArbiter stateCheck(State.Disputed) {
        state = State.Refunded;
        emit StateChanged(state);
        _pay(buyer);
    }
}
