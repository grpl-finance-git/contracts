// SPDX-License-Identifier: MIT

/*     
    Golden Raito Per Liquidity
    
    
    Forked from Ampleforth: https://github.com/ampleforth/uFragments (Credits to Ampleforth team for implementation of rebasing on the ethereum network)
    
    GRPL 1.0 license
    
    GRPLVesting.sol - GRPL Tokens Vested for all atakeholders for long term collaboration
  
*/
pragma solidity ^0.6.12;

contract Ownable {

  address private _owner;
  uint256 private _ownershipLocked;

  event OwnershipLocked(address lockedOwner);
  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );


  constructor() public {
    _owner = msg.sender;
  _ownershipLocked = 0;
  }

  function owner() public view returns(address) {
    return _owner;
  }

  modifier onlyOwner() {
    require(isOwner());
    _;
  }

  function isOwner() public view returns(bool) {
    return msg.sender == _owner;
  }

  function transferOwnership(address newOwner) public onlyOwner {
    _transferOwnership(newOwner);
  }

  function _transferOwnership(address newOwner) internal {
    require(_ownershipLocked == 0);
    require(newOwner != address(0));
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
  }
  
  // Set _ownershipLocked flag to lock contract owner forever
  function lockOwnership() public onlyOwner {
  require(_ownershipLocked == 0);
  emit OwnershipLocked(_owner);
    _ownershipLocked = 1;
  }

}

interface IERC20 {

  function totalSupply() external view returns (uint256);

  function balanceOf(address who) external view returns (uint256);

  function allowance(address owner, address spender)
    external view returns (uint256);

  function transfer(address to, uint256 value) external returns (bool);

  function approve(address spender, uint256 value)
    external returns (bool);

  function transferFrom(address from, address to, uint256 value)
    external returns (bool);

  event Transfer(
    address indexed from,
    address indexed to,
    uint256 value
  );

  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}

contract GRPLVesting is Ownable{
    
    IERC20 public grpl;
    
    string private name;
    address private beneficiaryAddress;
    uint256 private totalVested;
    uint256 private scheduleTime;
    bool private initialized;
    
    event GRPL_LOCKED(string name, address beneficiaryAddress, uint256 _totalVested, uint256 _scheduleTime);
    event GRPL_RELEASED(string name, address beneficiaryAddress, uint256 _releaseAmount, uint256 _timeOfWithdrawl);
    
    constructor(IERC20 _grpl) public{
        grpl = _grpl;
    }
    
    modifier whenInitialized(){
        require(initialized == true,"contract should be initiaized");
        _;
    }
    
    modifier onlyBeneficiary(){
        require(msg.sender == beneficiaryAddress, "not authorized to withdraw");
        _;
    }
    
    modifier whenTimeComleted(){
        require(now > scheduleTime,"time for vesting has not completed");
        _;
    }
    
    function initialize(string memory _name,
        address _beneficiaryAddress,
        uint256 _totalVested,
        uint256 _scheduleTime)
    public onlyOwner{
        require(initialized == false,"contract already initialized");
        require(grpl.balanceOf(address(this)) == _totalVested, 'tested amount doesnt match');
        name =_name;
        beneficiaryAddress = _beneficiaryAddress;
        totalVested = _totalVested;
        scheduleTime = _scheduleTime;
        initialized = true;
        
        emit GRPL_LOCKED(_name, _beneficiaryAddress, _totalVested, _scheduleTime);
    }
    
    
    function getInfo() public view returns(string memory _name,address _beneficiaryAddress,uint256 amountVested,uint256 unlockTime){
        return (name,beneficiaryAddress,totalVested,scheduleTime);
    }
    
    function withdraw() whenInitialized onlyBeneficiary whenTimeComleted public{
        grpl.transfer(beneficiaryAddress, grpl.balanceOf(address(this)));
        emit GRPL_RELEASED(name, beneficiaryAddress, totalVested, now);
        selfdestruct(address(uint160(owner())));
    }   
}