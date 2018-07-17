pragma solidity ^0.4.23;


/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;


  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() public {
    owner = msg.sender;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  /**
   * @dev Allows the current owner to relinquish control of the contract.
   * @notice Renouncing to ownership will leave the contract without an owner.
   * It will not be possible to call the functions with the `onlyOwner`
   * modifier anymore.
   */
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function transferOwnership(address _newOwner) public onlyOwner {
    _transferOwnership(_newOwner);
  }

  /**
   * @dev Transfers control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function _transferOwnership(address _newOwner) internal {
    require(_newOwner != address(0));
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }
}

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    // Gas optimization: this is cheaper than asserting 'a' not being zero, but the
    // benefit is lost if 'b' is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (a == 0) {
      return 0;
    }

    c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return a / b;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}

/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * See https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

contract ESICVault is Ownable {
    using SafeMath for uint256;

    // token contract Address

    //Wallet Addresses for allocation
    address public teamReserveWallet          = 0xC7e65CfAbEBab39b71df10b81c58EFA7f39b142e;
    address public advisorReserveWallet       = 0xb820EDBC22cE934AaB93749A547608d247b6855b;
    address public developerReserveWallet     = 0x08BD51746161B82D49338d9B9a9C3D6d4327afA5;
    address public serviceReserveWallet       = 0xf0529398b984Ee01966FF474cE37261141580304;
    address public enterpriseReserveWallet    = 0x2E4E16270c7506753e0A845721A145E465FAb27c;
    address public cornerReserveWallet        = 0x777fC79A52FF1a2949d8aA4C960d11BB8925Ae4b;
    address public institutionalReserveWallet = 0xc318942c76cE9957E14fBdc3afC729d5b5Ac06b0;
    address public privateReserveWallet       = 0xa61FCf967332C14e8c942c2CDB941609a08d503F;

    //Token Allocations
    uint256 public teamReserveAllocation          = 1.5 * (10 ** 9) * (10 ** 18);
    uint256 public advisorReserveAllocation       = 0.5 * (10 ** 9) * (10 ** 18);
    uint256 public developerReserveAllocation     = 1.0 * (10 ** 9) * (10 ** 18);
    uint256 public serviceReserveAllocation       = 1.0 * (10 ** 9) * (10 ** 18);
    uint256 public enterpriseReserveAllocation    = 1.0 * (10 ** 9) * (10 ** 18);
    uint256 public cornerReserveAllocation        = 0.25 * (10 ** 9) * (10 ** 18);
    uint256 public institutionalReserveAllocation = 0.5 * (10 ** 9) * (10 ** 18);
    uint256 public privateReserveAllocation       = 4.25 * (10 ** 9) * (10 ** 18);

    //Total Token Allocations
    uint256 public totalAllocation = 10 * (10 ** 9) * (10 ** 18);

    uint256 public teamTimeLock = 4 * 365 days;
    uint256 public teamVestingStages = 48;
    uint256 public advisorTimeLock = 4 * 365 days;
    uint256 public advisorVestingStages = 48;

    /** Reserve allocations */
    mapping(address => uint256) public allocations;

    /** When timeLocks are over (UNIX Timestamp)  */
    mapping(address => uint256) public timeLocks;

    /** How many tokens each reserve wallet has claimed */
    mapping(address => uint256) public claimed;

    /** When this vault was locked (UNIX Timestamp)*/
    uint256 public lockedAt = 0;

    ERC20Basic public token;

    /** Allocated reserve tokens */
    event Allocated(address wallet, uint256 value);

    /** Distributed reserved tokens */
    event Distributed(address wallet, uint256 value);

    /** Tokens have been locked */
    event Locked(uint256 lockTime);

    //Any of the eight reserve wallets
    modifier onlyReserveWallets {
        require(allocations[msg.sender] > 0);
        _;
    }

    //Only ESIC team reserve wallet
    modifier onlyTeamReserve {
        require(msg.sender == teamReserveWallet);
        require(allocations[msg.sender] > 0);
        _;
    }

    //Only ESIC advisor reserve wallet
    modifier onlyAdvisorReserve {
        require(msg.sender == advisorReserveWallet);
        require(allocations[msg.sender] > 0);
        _;
    }

    //Has not been locked yet
    modifier notLocked {
        require(lockedAt == 0);
        _;
    }

    modifier locked {
        require(lockedAt > 0);
        _;
    }

    //Token allocations have not been set
    modifier notAllocated {
        require(allocations[teamReserveWallet] == 0);
        require(allocations[advisorReserveWallet] == 0);
        require(allocations[developerReserveWallet] == 0);
        require(allocations[serviceReserveWallet] == 0);
        require(allocations[enterpriseReserveWallet] == 0);
        require(allocations[cornerReserveWallet] == 0);
        require(allocations[institutionalReserveWallet] == 0);
        require(allocations[privateReserveWallet] == 0);
        _;
    }

    constructor(ERC20Basic _token) public {
        token = ERC20Basic(_token);
    }

    function allocate() public notLocked notAllocated onlyOwner {

        //Makes sure Token Contract has the exact number of tokens
        require(token.balanceOf(address(this)) == totalAllocation);

        allocations[teamReserveWallet] = teamReserveAllocation;
        allocations[advisorReserveWallet] = advisorReserveAllocation;
        allocations[developerReserveWallet] = developerReserveAllocation;
        allocations[serviceReserveWallet] = serviceReserveAllocation;
        allocations[enterpriseReserveWallet] = enterpriseReserveAllocation;
        allocations[cornerReserveWallet] = cornerReserveAllocation;
        allocations[institutionalReserveWallet] = institutionalReserveAllocation;
        allocations[privateReserveWallet] = privateReserveAllocation;

        emit Allocated(teamReserveWallet, teamReserveAllocation);
        emit Allocated(advisorReserveWallet, advisorReserveAllocation);
        emit Allocated(developerReserveWallet, developerReserveAllocation);
        emit Allocated(serviceReserveWallet, serviceReserveAllocation);
        emit Allocated(enterpriseReserveWallet, enterpriseReserveAllocation);
        emit Allocated(cornerReserveWallet, cornerReserveAllocation);
        emit Allocated(institutionalReserveWallet, institutionalReserveAllocation);
        emit Allocated(privateReserveWallet, privateReserveAllocation);

        lock();
        distribute();
    }

    //Lock the vault for the three wallets
    function lock() internal {

        lockedAt = block.timestamp;

        timeLocks[teamReserveWallet] = lockedAt.add(teamTimeLock);
        timeLocks[advisorReserveWallet] = lockedAt.add(advisorTimeLock);

        emit Locked(lockedAt);
    }

    //In the case locking failed, then allow the owner to reclaim the tokens on the contract.
    //Recover Tokens in case incorrect amount was sent to contract.
    function recoverFailedLock() external notLocked notAllocated onlyOwner {

        // Transfer all tokens on this contract back to the owner
        require(token.transfer(owner, token.balanceOf(address(this))));
    }

    // Total number of tokens currently in the vault
    function getTotalBalance() public view returns (uint256 tokensCurrentlyInVault) {

        return token.balanceOf(address(this));

    }

    // Number of tokens that are still locked
    function getLockedBalance() public view onlyReserveWallets returns (uint256 tokensLocked) {

        return allocations[msg.sender].sub(claimed[msg.sender]);

    }

    //Distribute tokens for non-vesting reserve wallets
    function distribute() internal {
        claimTokenReserve(developerReserveWallet);
        claimTokenReserve(serviceReserveWallet);
        claimTokenReserve(enterpriseReserveWallet);
        claimTokenReserve(cornerReserveWallet);
        claimTokenReserve(institutionalReserveWallet);
        claimTokenReserve(privateReserveWallet);
    }

    //Claim tokens for non-vesting reserve wallets
    function claimTokenReserve(address reserveWallet) internal {

        require(reserveWallet == developerReserveWallet || reserveWallet == serviceReserveWallet
          || reserveWallet == enterpriseReserveWallet || reserveWallet == cornerReserveWallet
          || reserveWallet == institutionalReserveWallet|| reserveWallet == privateReserveWallet);


        // Must Only claim once
        require(allocations[reserveWallet] > 0);
        require(claimed[reserveWallet] == 0);

        uint256 amount = allocations[reserveWallet];

        claimed[reserveWallet] = amount;

        require(token.transfer(reserveWallet, amount));

        emit Distributed(reserveWallet, amount);
    }

    //Claim tokens for ESIC team reserve wallet
    function claimTeamReserve() onlyTeamReserve locked public {

        uint256 vestingStage = teamVestingStage();

        //Amount of tokens the team should have at this vesting stage
        uint256 totalUnlocked = vestingStage.mul(allocations[teamReserveWallet]).div(teamVestingStages);

        require(totalUnlocked <= allocations[teamReserveWallet]);

        //Previously claimed tokens must be less than what is unlocked
        require(claimed[teamReserveWallet] < totalUnlocked);

        uint256 payment = totalUnlocked.sub(claimed[teamReserveWallet]);

        claimed[teamReserveWallet] = totalUnlocked;

        require(token.transfer(teamReserveWallet, payment));

        emit Distributed(teamReserveWallet, payment);
    }

    //Current Vesting stage for ESIC team
    function teamVestingStage() public view returns(uint256){

        // Every 3 months
        uint256 vestingMonths = teamTimeLock.div(teamVestingStages);

        uint256 stage = (block.timestamp.sub(lockedAt)).div(vestingMonths);

        //Ensures team vesting stage doesn't go past teamVestingStages
        if(stage > teamVestingStages){
            stage = teamVestingStages;
        }

        return stage;

    }

    //Claim tokens for ESIC advisor reserve wallet
    function claimAdvisorReserve() onlyAdvisorReserve locked public {

        uint256 vestingStage = advisorVestingStage();

        //Amount of tokens the team should have at this vesting stage
        uint256 totalUnlocked = vestingStage.mul(allocations[advisorReserveWallet]).div(advisorVestingStages);

        require(totalUnlocked <= allocations[advisorReserveWallet]);

        //Previously claimed tokens must be less than what is unlocked
        require(claimed[advisorReserveWallet] < totalUnlocked);

        uint256 payment = totalUnlocked.sub(claimed[advisorReserveWallet]);

        claimed[advisorReserveWallet] = totalUnlocked;

        require(token.transfer(advisorReserveWallet, payment));

        emit Distributed(advisorReserveWallet, payment);
    }

    //Current Vesting stage for ESIC advisor
    function advisorVestingStage() public view returns(uint256){

        // Every month
        uint256 vestingMonths = advisorTimeLock.div(advisorVestingStages);

        uint256 stage = (block.timestamp.sub(lockedAt)).div(vestingMonths);

        //Ensures advisor vesting stage doesn't go past advisorVestingStages
        if(stage > advisorVestingStages){
            stage = advisorVestingStages;
        }

        return stage;

    }
}
