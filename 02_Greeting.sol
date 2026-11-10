// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Greeting {
    string private greeting;
    address public owner;

    event GreetingChanged(
        address changer,
        string newGreeting
    );

    constructor(string memory _g) {
        owner = msg.sender;
        greeting = _g;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Not the owner");
        _;
    }

    function setGreeting(string memory _g)
        public onlyOwner
    {
        greeting = _g;
        emit GreetingChanged(msg.sender, _g);
    }

    function greet() public view
        returns (string memory)
    {
        return greeting;
    }

    function resetGreeting() public onlyOwner {
        greeting = "Hello, World!";
        emit GreetingChanged(msg.sender, greeting);
    }
}