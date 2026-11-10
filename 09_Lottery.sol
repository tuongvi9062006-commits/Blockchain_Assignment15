
 // SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract Lottery {
    address payable[] private players;
    address public manager;
    uint256 public entryFee;
    uint256 public minPlayers;

    event Entered(address indexed player);
    event WinnerSelected(address indexed winner, uint256 amount);

    modifier onlyManager() {
        require(msg.sender == manager, "Not manager");
        _;
    }

    constructor(uint256 _entryFee, uint256 _minPlayers) {
        require(_entryFee > 0 && _minPlayers > 0, "Invalid settings");
        manager = msg.sender;
        entryFee = _entryFee;
        minPlayers = _minPlayers;
    }

    function enter() public payable {
        require(msg.sender != manager, "Manager cannot enter");
        require(msg.value == entryFee, "Wrong entry fee");

        players.push(payable(msg.sender));
        emit Entered(msg.sender);
    }

    function playersCount() public view returns (uint256) {
        return players.length;
    }

    function pickWinner() public onlyManager {
        require(players.length >= minPlayers, "Not enough players");

        uint256 index = uint256(blockhash(block.number - 1)) % players.length;
        address payable winner = players[index];
        uint256 prize = address(this).balance;

        delete players;

        (bool success, ) = winner.call{value: prize}("");
        require(success, "Payout failed");

        emit WinnerSelected(winner, prize);
    }
}
