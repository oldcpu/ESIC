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

pragma solidity ^0.4.23;

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

/**
 * @title Basic token
 * @dev Basic version of StandardToken, with no allowances.
 */
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

  uint256 totalSupply_;

  /**
  * @dev Total number of tokens in existence
  */
  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }

  /**
  * @dev Transfer token for a specified address
  * @param _to The address to transfer to.
  * @param _value The amount to be transferred.
  */
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);

    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

  /**
  * @dev Gets the balance of the specified address.
  * @param _owner The address to query the the balance of.
  * @return An uint256 representing the amount owned by the passed address.
  */
  function balanceOf(address _owner) public view returns (uint256) {
    return balances[_owner];
  }

}

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender)
    public view returns (uint256);

  function transferFrom(address from, address to, uint256 value)
    public returns (bool);

  function approve(address spender, uint256 value) public returns (bool);
  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}

/**
 * @title Standard ERC20 token
 *
 * @dev Implementation of the basic standard token.
 * https://github.com/ethereum/EIPs/issues/20
 * Based on code by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 */
contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) internal allowed;


  /**
   * @dev Transfer tokens from one address to another
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _value uint256 the amount of tokens to be transferred
   */
  function transferFrom(
    address _from,
    address _to,
    uint256 _value
  )
    public
    returns (bool)
  {
    require(_to != address(0));
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    emit Transfer(_from, _to, _value);
    return true;
  }

  /**
   * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
   * Beware that changing an allowance with this method brings the risk that someone may use both the old
   * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
   * race condition is to first reduce the spender's allowance to 0 and set the desired value afterwards:
   * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
   * @param _spender The address which will spend the funds.
   * @param _value The amount of tokens to be spent.
   */
  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

  /**
   * @dev Function to check the amount of tokens that an owner allowed to a spender.
   * @param _owner address The address which owns the funds.
   * @param _spender address The address which will spend the funds.
   * @return A uint256 specifying the amount of tokens still available for the spender.
   */
  function allowance(
    address _owner,
    address _spender
   )
    public
    view
    returns (uint256)
  {
    return allowed[_owner][_spender];
  }

  /**
   * @dev Increase the amount of tokens that an owner allowed to a spender.
   * approve should be called when allowed[_spender] == 0. To increment
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * @param _spender The address which will spend the funds.
   * @param _addedValue The amount of tokens to increase the allowance by.
   */
  function increaseApproval(
    address _spender,
    uint256 _addedValue
  )
    public
    returns (bool)
  {
    allowed[msg.sender][_spender] = (
      allowed[msg.sender][_spender].add(_addedValue));
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  /**
   * @dev Decrease the amount of tokens that an owner allowed to a spender.
   * approve should be called when allowed[_spender] == 0. To decrement
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * @param _spender The address which will spend the funds.
   * @param _subtractedValue The amount of tokens to decrease the allowance by.
   */
  function decreaseApproval(
    address _spender,
    uint256 _subtractedValue
  )
    public
    returns (bool)
  {
    uint256 oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

}

contract ESICToken is StandardToken {
    string public name = "Enterprise Service Improvement Chain";
    string public symbol = "ET";
    uint8 public decimals = 18;
    uint256 public INITIAL_SUPPLY = 10000000000000000000000000000;

    constructor() public {
        totalSupply_ = INITIAL_SUPPLY;
        balances[msg.sender] = totalSupply_;
        emit Transfer(0x0, msg.sender, INITIAL_SUPPLY);
    }
}

contract ESICVault is Ownable {
    using SafeMath for uint256;

    // token contract Address
    address public tokenAddress               = 0x3256816C40dEe189CAaa32Dd91f6C79cA73B9906;

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

    ESICToken public token;

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

    constructor() public {
        owner = msg.sender;
        token = ESICToken(tokenAddress);
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
    function lock() internal notLocked onlyOwner {

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
    function distribute() onlyOwner locked public {
        claimTokenReserve(developerReserveWallet);
        claimTokenReserve(serviceReserveWallet);
        claimTokenReserve(enterpriseReserveWallet);
        claimTokenReserve(cornerReserveWallet);
        claimTokenReserve(institutionalReserveWallet);
        claimTokenReserve(privateReserveWallet);
    }

    //Claim tokens for non-vesting reserve wallets
    function claimTokenReserve(address reserveWallet) internal onlyOwner locked {

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
    function teamVestingStage() public view onlyTeamReserve returns(uint256){

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
    function advisorVestingStage() public view onlyAdvisorReserve returns(uint256){

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
