
 // SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract Voting {
    address public chairperson;

    struct Candidate {
        string name;
        uint256 voteCount;
    }

    struct Voter {
        bool authorized;
        bool voted;
        uint256 voteIndex;
    }

    Candidate[] public candidates;
    mapping(address => Voter) public voters;

    event VoterAuthorized(address indexed voter);
    event VoteCast(address indexed voter, uint256 candidateIndex);

    constructor(string[] memory candidateNames) {
        chairperson = msg.sender;

        for (uint256 i = 0; i < candidateNames.length; i++) {
            candidates.push(Candidate(candidateNames[i], 0));
        }
    }

    modifier onlyChairperson() {
        require(msg.sender == chairperson, "Not chairperson");
        _;
    }

    function authorize(address voter)
        public onlyChairperson
    {
        require(!voters[voter].authorized, "Already authorized");
        require(voter != address(0), "Invalid address");

        voters[voter].authorized = true;
        emit VoterAuthorized(voter);
    }

    function vote(uint256 candidateIndex) public {
        require(voters[msg.sender].authorized, "Not authorized");
        require(!voters[msg.sender].voted, "Already voted");
        require(candidateIndex < candidates.length, "Invalid candidate");

        voters[msg.sender].voted = true;
        voters[msg.sender].voteIndex = candidateIndex;

        candidates[candidateIndex].voteCount++;

        emit VoteCast(msg.sender, candidateIndex);
    }

    function totalVotes(uint256 candidateIndex)
        public view returns (uint256)
    {
        require(candidateIndex < candidates.length, "Invalid candidate");
        return candidates[candidateIndex].voteCount;
    }

    function winnerName()
        public view returns (string memory)
    {
        require(candidates.length > 0, "No candidates");

        uint256 winningIndex = 0;

        for (uint256 i = 1; i < candidates.length; i++) {
            if (candidates[i].voteCount >
                candidates[winningIndex].voteCount) {
                winningIndex = i;
            }
        }

        return candidates[winningIndex].name;
    }
}
