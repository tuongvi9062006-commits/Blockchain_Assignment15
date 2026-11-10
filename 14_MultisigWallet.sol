
 // SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract MultisigWallet {
    address[] public owners;
    uint256 public required;

    mapping(address => bool) public isOwner;

    struct Transaction {
        address to;
        uint256 value;
        bool executed;
    }

    Transaction[] public transactions;
    mapping(uint256 => mapping(address => bool)) public confirmed;
    mapping(uint256 => uint256) private confirmationCount;

    event Submission(uint256 indexed txId);
    event Confirmation(address indexed owner, uint256 indexed txId);
    event Execution(uint256 indexed txId);
    event Deposit(address indexed sender, uint256 amount);

    modifier onlyOwner() {
        require(isOwner[msg.sender], "Not owner");
        _;
    }

    modifier txExists(uint256 txId) {
        require(txId < transactions.length, "Invalid transaction");
        _;
    }

    constructor(address[] memory _owners, uint256 _required) {
        require(_required > 0 && _owners.length >= _required, "Invalid threshold");

        for (uint256 i = 0; i < _owners.length; i++) {
            address a = _owners[i];
            require(a != address(0) && !isOwner[a], "Duplicate or zero owner");
            isOwner[a] = true;
            owners.push(a);
        }

        required = _required;
    }

    receive() external payable {
        emit Deposit(msg.sender, msg.value);
    }

    function submitTransaction(address to, uint256 value) external onlyOwner {
        require(to != address(0), "Invalid recipient");

        transactions.push(Transaction(to, value, false));
        emit Submission(transactions.length - 1);
    }

    function confirmTransaction(uint256 txId) external onlyOwner txExists(txId) {
        require(!transactions[txId].executed, "Already executed");
        require(!confirmed[txId][msg.sender], "Already confirmed");

        confirmed[txId][msg.sender] = true;
        confirmationCount[txId]++;

        emit Confirmation(msg.sender, txId);

        if (confirmationCount[txId] >= required) {
            _execute(txId);
        }
    }

    function executeTransaction(uint256 txId) external onlyOwner txExists(txId) {
        require(confirmationCount[txId] >= required, "Not enough confirmations");
        _execute(txId);
    }

    function _execute(uint256 txId) internal {
        Transaction storage t = transactions[txId];

        require(!t.executed, "Already executed");
        require(address(this).balance >= t.value, "Insufficient ETH");

        t.executed = true;

        (bool success, ) = payable(t.to).call{value: t.value}("");
        require(success, "Transfer failed");

        emit Execution(txId);
    }

    function getConfirmations(uint256 txId)
        external view txExists(txId) returns (uint256)
    {
        return confirmationCount[txId];
    }
}
