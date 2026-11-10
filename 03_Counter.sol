
 // SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract Counter {
    uint256 public count = 0;
    uint256 public constant MAX = 100;

    event Incremented(uint256 newCount);
    event Decremented(uint256 newCount);
    event Reset(uint256 newCount);

    function increment() public {
        require(count < MAX, "Max limit reached");

        count += 1;
        emit Incremented(count);
    }

    function decrement() public {
        require(count > 0, "Count is zero");

        count -= 1;
        emit Decremented(count);
    }

    function reset() public {
        count = 0;
        emit Reset(count);
    }
}
