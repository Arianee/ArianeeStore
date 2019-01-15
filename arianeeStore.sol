pragma solidity ^0.4.24;

// File: openzeppelin-solidity/contracts/introspection/ERC165.sol

/**
 * @title ERC165
 * @dev https://github.com/ethereum/EIPs/blob/master/EIPS/eip-165.md
 */
interface ERC165 {

  /**
   * @notice Query if a contract implements an interface
   * @param _interfaceId The interface identifier, as specified in ERC-165
   * @dev Interface identification is specified in ERC-165. This function
   * uses less than 30,000 gas.
   */
  function supportsInterface(bytes4 _interfaceId)
    external
    view
    returns (bool);
}

// File: openzeppelin-solidity/contracts/token/ERC721/ERC721Basic.sol

/**
 * @title ERC721 Non-Fungible Token Standard basic interface
 * @dev see https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md
 */
contract ERC721Basic is ERC165 {

  bytes4 internal constant InterfaceId_ERC721 = 0x80ac58cd;
  /*
   * 0x80ac58cd ===
   *   bytes4(keccak256('balanceOf(address)')) ^
   *   bytes4(keccak256('ownerOf(uint256)')) ^
   *   bytes4(keccak256('approve(address,uint256)')) ^
   *   bytes4(keccak256('getApproved(uint256)')) ^
   *   bytes4(keccak256('setApprovalForAll(address,bool)')) ^
   *   bytes4(keccak256('isApprovedForAll(address,address)')) ^
   *   bytes4(keccak256('transferFrom(address,address,uint256)')) ^
   *   bytes4(keccak256('safeTransferFrom(address,address,uint256)')) ^
   *   bytes4(keccak256('safeTransferFrom(address,address,uint256,bytes)'))
   */

  bytes4 internal constant InterfaceId_ERC721Exists = 0x4f558e79;
  /*
   * 0x4f558e79 ===
   *   bytes4(keccak256('exists(uint256)'))
   */

  bytes4 internal constant InterfaceId_ERC721Enumerable = 0x780e9d63;
  /**
   * 0x780e9d63 ===
   *   bytes4(keccak256('totalSupply()')) ^
   *   bytes4(keccak256('tokenOfOwnerByIndex(address,uint256)')) ^
   *   bytes4(keccak256('tokenByIndex(uint256)'))
   */

  bytes4 internal constant InterfaceId_ERC721Metadata = 0x5b5e139f;
  /**
   * 0x5b5e139f ===
   *   bytes4(keccak256('name()')) ^
   *   bytes4(keccak256('symbol()')) ^
   *   bytes4(keccak256('tokenURI(uint256)'))
   */

  event Transfer(
    address indexed _from,
    address indexed _to,
    uint256 indexed _tokenId
  );
  event Approval(
    address indexed _owner,
    address indexed _approved,
    uint256 indexed _tokenId
  );
  event ApprovalForAll(
    address indexed _owner,
    address indexed _operator,
    bool _approved
  );

  function balanceOf(address _owner) public view returns (uint256 _balance);
  function ownerOf(uint256 _tokenId) public view returns (address _owner);
  function exists(uint256 _tokenId) public view returns (bool _exists);

  function approve(address _to, uint256 _tokenId) public;
  function getApproved(uint256 _tokenId)
    public view returns (address _operator);

  function setApprovalForAll(address _operator, bool _approved) public;
  function isApprovedForAll(address _owner, address _operator)
    public view returns (bool);

  function transferFrom(address _from, address _to, uint256 _tokenId) public;
  function safeTransferFrom(address _from, address _to, uint256 _tokenId)
    public;

  function safeTransferFrom(
    address _from,
    address _to,
    uint256 _tokenId,
    bytes _data
  )
    public;
}

// File: openzeppelin-solidity/contracts/token/ERC721/ERC721.sol

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md
 */
contract ERC721Enumerable is ERC721Basic {
  function totalSupply() public view returns (uint256);
  function tokenOfOwnerByIndex(
    address _owner,
    uint256 _index
  )
    public
    view
    returns (uint256 _tokenId);

  function tokenByIndex(uint256 _index) public view returns (uint256);
}


/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md
 */
contract ERC721Metadata is ERC721Basic {
  function name() external view returns (string _name);
  function symbol() external view returns (string _symbol);
  function tokenURI(uint256 _tokenId) public view returns (string);
}


/**
 * @title ERC-721 Non-Fungible Token Standard, full implementation interface
 * @dev See https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md
 */
contract ERC721 is ERC721Basic, ERC721Enumerable, ERC721Metadata {
}

// File: openzeppelin-solidity/contracts/token/ERC20/ERC20Basic.sol

/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * See https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address _who) public view returns (uint256);
  function transfer(address _to, uint256 _value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

// File: openzeppelin-solidity/contracts/token/ERC20/ERC20.sol

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
  function allowance(address _owner, address _spender)
    public view returns (uint256);

  function transferFrom(address _from, address _to, uint256 _value)
    public returns (bool);

  function approve(address _spender, uint256 _value) public returns (bool);
  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}

// File: openzeppelin-solidity/contracts/math/SafeMath.sol

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
    // Gas optimization: this is cheaper than asserting 'a' not being zero, but the
    // benefit is lost if 'b' is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (_a == 0) {
      return 0;
    }

    c = _a * _b;
    assert(c / _a == _b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
    // assert(_b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = _a / _b;
    // assert(_a == _b * c + _a % _b); // There is no case in which this doesn't hold
    return _a / _b;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
    assert(_b <= _a);
    return _a - _b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
    c = _a + _b;
    assert(c >= _a);
    return c;
  }
}

// File: contracts/ERC900.sol

/**
 * @title ERC900 Simple Staking Interface
 * @dev See https://github.com/ethereum/EIPs/blob/master/EIPS/eip-900.md
 */
contract ERC900 {
  event Staked(address indexed user, uint256 amount, uint256 total, bytes data);
  event Unstaked(address indexed user, uint256 amount, uint256 total, bytes data);

  function stake(uint256 amount, bytes data) public;
  function stakeFor(address user, uint256 amount, bytes data) public;
  function unstake(uint256 amount, bytes data) public;
  function totalStakedFor(address addr) public view returns (uint256);
  function totalStaked() public view returns (uint256);
  function token() public view returns (address);
  function supportsHistory() public pure returns (bool);

  // NOTE: Not implementing the optional functions
  // function lastStakedFor(address addr) public view returns (uint256);
  // function totalStakedForAt(address addr, uint256 blockNumber) public view returns (uint256);
  // function totalStakedAt(uint256 blockNumber) public view returns (uint256);
}

// File: contracts/ERC900BasicStakeContract.sol

/* solium-disable security/no-block-members */
pragma solidity ^0.4.24;





/**
 * @title ERC900 Simple Staking Interface basic implementation
 * @dev See https://github.com/ethereum/EIPs/blob/master/EIPS/eip-900.md
 */
contract ERC900BasicStakeContract is ERC900 {
  // @TODO: deploy this separately so we don't have to deploy it multiple times for each contract
  using SafeMath for uint256;

  // Token used for staking
  ERC20 stakingToken;

  // The default duration of stake lock-in (in seconds)
  uint256 public defaultLockInDuration;

  // To save on gas, rather than create a separate mapping for totalStakedFor & personalStakes,
  //  both data structures are stored in a single mapping for a given addresses.
  //
  // It's possible to have a non-existing personalStakes, but have tokens in totalStakedFor
  //  if other users are staking on behalf of a given address.
  mapping (address => StakeContract) public stakeHolders;

  // Struct for personal stakes (i.e., stakes made by this address)
  // unlockedTimestamp - when the stake unlocks (in seconds since Unix epoch)
  // actualAmount - the amount of tokens in the stake
  // stakedFor - the address the stake was staked for
  struct Stake {
    uint256 unlockedTimestamp;
    uint256 actualAmount;
    address stakedFor;
  }

  // Struct for all stake metadata at a particular address
  // totalStakedFor - the number of tokens staked for this address
  // personalStakeIndex - the index in the personalStakes array.
  // personalStakes - append only array of stakes made by this address
  // exists - whether or not there are stakes that involve this address
  struct StakeContract {
    uint256 totalStakedFor;

    uint256 personalStakeIndex;

    Stake[] personalStakes;

    bool exists;
  }

  /**
   * @dev Modifier that checks that this contract can transfer tokens from the
   *  balance in the stakingToken contract for the given address.
   * @dev This modifier also transfers the tokens.
   * @param _address address to transfer tokens from
   * @param _amount uint256 the number of tokens
   */
  modifier canStake(address _address, uint256 _amount) {
    require(
      stakingToken.transferFrom(_address, this, _amount),
      "Stake required");

    _;
  }

  /**
   * @dev Constructor function
   * @param _stakingToken ERC20 The address of the token contract used for staking
   */
  constructor(ERC20 _stakingToken) public {
    stakingToken = _stakingToken;
  }

  /**
   * @dev Returns the timestamps for when active personal stakes for an address will unlock
   * @dev These accessors functions are needed until https://github.com/ethereum/web3.js/issues/1241 is solved
   * @param _address address that created the stakes
   * @return uint256[] array of timestamps
   */
  function getPersonalStakeUnlockedTimestamps(address _address) external view returns (uint256[]) {
    uint256[] memory timestamps;
    (timestamps,,) = getPersonalStakes(_address);

    return timestamps;
  }

  /**
   * @dev Returns the stake actualAmount for active personal stakes for an address
   * @dev These accessors functions are needed until https://github.com/ethereum/web3.js/issues/1241 is solved
   * @param _address address that created the stakes
   * @return uint256[] array of actualAmounts
   */
  function getPersonalStakeActualAmounts(address _address) external view returns (uint256[]) {
    uint256[] memory actualAmounts;
    (,actualAmounts,) = getPersonalStakes(_address);

    return actualAmounts;
  }

  /**
   * @dev Returns the addresses that each personal stake was created for by an address
   * @dev These accessors functions are needed until https://github.com/ethereum/web3.js/issues/1241 is solved
   * @param _address address that created the stakes
   * @return address[] array of amounts
   */
  function getPersonalStakeForAddresses(address _address) external view returns (address[]) {
    address[] memory stakedFor;
    (,,stakedFor) = getPersonalStakes(_address);

    return stakedFor;
  }

  /**
   * @notice Stakes a certain amount of tokens, this MUST transfer the given amount from the user
   * @notice MUST trigger Staked event
   * @param _amount uint256 the amount of tokens to stake
   * @param _data bytes optional data to include in the Stake event
   */
  function stake(uint256 _amount, bytes _data) public {
    createStake(
      msg.sender,
      _amount,
      defaultLockInDuration,
      _data);
  }

  /**
   * @notice Stakes a certain amount of tokens, this MUST transfer the given amount from the caller
   * @notice MUST trigger Staked event
   * @param _user address the address the tokens are staked for
   * @param _amount uint256 the amount of tokens to stake
   * @param _data bytes optional data to include in the Stake event
   */
  function stakeFor(address _user, uint256 _amount, bytes _data) public {
    createStake(
      _user,
      _amount,
      defaultLockInDuration,
      _data);
  }

  /**
   * @notice Unstakes a certain amount of tokens, this SHOULD return the given amount of tokens to the user, if unstaking is currently not possible the function MUST revert
   * @notice MUST trigger Unstaked event
   * @dev Unstaking tokens is an atomic operation—either all of the tokens in a stake, or none of the tokens.
   * @dev Users can only unstake a single stake at a time, it is must be their oldest active stake. Upon releasing that stake, the tokens will be
   *  transferred back to their account, and their personalStakeIndex will increment to the next active stake.
   * @param _amount uint256 the amount of tokens to unstake
   * @param _data bytes optional data to include in the Unstake event
   */
  function unstake(uint256 _amount, bytes _data) public {
    withdrawStake(
      _amount,
      _data);
  }

  /**
   * @notice Returns the current total of tokens staked for an address
   * @param _address address The address to query
   * @return uint256 The number of tokens staked for the given address
   */
  function totalStakedFor(address _address) public view returns (uint256) {
    return stakeHolders[_address].totalStakedFor;
  }

  /**
   * @notice Returns the current total of tokens staked
   * @return uint256 The number of tokens staked in the contract
   */
  function totalStaked() public view returns (uint256) {
    return stakingToken.balanceOf(this);
  }

  /**
   * @notice Address of the token being used by the staking interface
   * @return address The address of the ERC20 token used for staking
   */
  function token() public view returns (address) {
    return stakingToken;
  }

  /**
   * @notice MUST return true if the optional history functions are implemented, otherwise false
   * @dev Since we don't implement the optional interface, this always returns false
   * @return bool Whether or not the optional history functions are implemented
   */
  function supportsHistory() public pure returns (bool) {
    return false;
  }

  /**
   * @dev Helper function to get specific properties of all of the personal stakes created by an address
   * @param _address address The address to query
   * @return (uint256[], uint256[], address[])
   *  timestamps array, actualAmounts array, stakedFor array
   */
  function getPersonalStakes(
    address _address
  )
    view
    public
    returns(uint256[], uint256[], address[])
  {
    StakeContract storage stakeContract = stakeHolders[_address];

    uint256 arraySize = stakeContract.personalStakes.length - stakeContract.personalStakeIndex;
    uint256[] memory unlockedTimestamps = new uint256[](arraySize);
    uint256[] memory actualAmounts = new uint256[](arraySize);
    address[] memory stakedFor = new address[](arraySize);

    for (uint256 i = stakeContract.personalStakeIndex; i < stakeContract.personalStakes.length; i++) {
      uint256 index = i - stakeContract.personalStakeIndex;
      unlockedTimestamps[index] = stakeContract.personalStakes[i].unlockedTimestamp;
      actualAmounts[index] = stakeContract.personalStakes[i].actualAmount;
      stakedFor[index] = stakeContract.personalStakes[i].stakedFor;
    }

    return (
      unlockedTimestamps,
      actualAmounts,
      stakedFor
    );
  }

  /**
   * @dev Helper function to create stakes for a given address
   * @param _address address The address the stake is being created for
   * @param _amount uint256 The number of tokens being staked
   * @param _lockInDuration uint256 The duration to lock the tokens for
   * @param _data bytes optional data to include in the Stake event
   */
  function createStake(
    address _address,
    uint256 _amount,
    uint256 _lockInDuration,
    bytes _data
  )
    internal
    canStake(msg.sender, _amount)
  {
    if (!stakeHolders[msg.sender].exists) {
      stakeHolders[msg.sender].exists = true;
    }

    stakeHolders[_address].totalStakedFor = stakeHolders[_address].totalStakedFor.add(_amount);
    stakeHolders[msg.sender].personalStakes.push(
      Stake(
        block.timestamp.add(_lockInDuration),
        _amount,
        _address)
      );

    emit Staked(
      _address,
      _amount,
      totalStakedFor(_address),
      _data);
  }

  /**
   * @dev Helper function to withdraw stakes for the msg.sender
   * @param _amount uint256 The amount to withdraw. MUST match the stake amount for the
   *  stake at personalStakeIndex.
   * @param _data bytes optional data to include in the Unstake event
   */
  function withdrawStake(
    uint256 _amount,
    bytes _data
  )
    internal
  {
    Stake storage personalStake = stakeHolders[msg.sender].personalStakes[stakeHolders[msg.sender].personalStakeIndex];

    // Check that the current stake has unlocked & matches the unstake amount
    require(
      personalStake.unlockedTimestamp <= block.timestamp,
      "The current stake hasn't unlocked yet");

    require(
      personalStake.actualAmount == _amount,
      "The unstake amount does not match the current stake");

    // Transfer the staked tokens from this contract back to the sender
    // Notice that we are using transfer instead of transferFrom here, so
    //  no approval is needed beforehand.
    require(
      stakingToken.transfer(msg.sender, _amount),
      "Unable to withdraw stake");

    stakeHolders[personalStake.stakedFor].totalStakedFor = stakeHolders[personalStake.stakedFor]
      .totalStakedFor.sub(personalStake.actualAmount);

    personalStake.actualAmount = 0;
    stakeHolders[msg.sender].personalStakeIndex++;

    emit Unstaked(
      personalStake.stakedFor,
      _amount,
      totalStakedFor(personalStake.stakedFor),
      _data);
  }
}

// File: contracts/Ownable.sol

/// @title Base contract with an owner.
/// @dev Provides onlyOwner modifier, which prevents function from running if
/// it is called by anyone other than the owner.
contract Ownable {
    address public owner;
    address public newOwner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    constructor() public {
        owner = msg.sender;
    }

    /// @notice Transfer ownership from `owner` to `newOwner`
    /// @param _newOwner The new contract owner
    function transferOwnership(address _newOwner) public onlyOwner {
        if (_newOwner != address(0)) {
            newOwner = _newOwner;
        }
    }

    /// @notice accept ownership of the contract
    function acceptOwnership() public {
        require(msg.sender == newOwner);
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

}

// File: contracts/arianeeStore.sol

// File: openzeppelin-zos/contracts/lifecycle/Pausable.sol

/**
 * @title Pausable
 * @dev Base contract which allows children to implement an emergency stop mechanism.
 */
contract Pausable is  Ownable {
  event Pause();
  event Unpause();

  bool public paused = false;

/*
  function initialize(address _sender) isInitializer("Pausable", "1.9.0")  public {
    Ownable.initialize(_sender);
  }
*/
  constructor() public {
      Ownable(msg.sender);
  }


  /**
   * @dev Modifier to make a function callable only when the contract is not paused.
   */
  modifier whenNotPaused() {
    require(!paused);
    _;
  }

  /**
   * @dev Modifier to make a function callable only when the contract is paused.
   */
  modifier whenPaused() {
    require(paused);
    _;
  }

  /**
   * @dev called by the owner to pause, triggers stopped state
   */
  function pause() onlyOwner whenNotPaused public {
    paused = true;
    emit Pause();
  }

  /**
   * @dev called by the owner to unpause, returns to normal state
   */
  function unpause() onlyOwner whenPaused public {
    paused = false;
    emit Unpause();
  }
}

// File: openzeppelin-zos/contracts/AddressUtils.sol

/**
 * Utility library of inline functions on addresses
 */
library AddressUtils {

  /**
   * Returns whether the target address is a contract
   * @dev This function will return false if invoked during the constructor of a contract,
   *  as the code is not actually created until after the constructor finishes.
   * @param addr address to check
   * @return whether the target address is a contract
   */
  function isContract(address addr) internal view returns (bool) {
    uint256 size;
    // XXX Currently there is no better way to check if there is a contract in an address
    // than to check the size of the code at that address.
    // See https://ethereum.stackexchange.com/a/14016/36603
    // for more details about how this works.
    // TODO Check this again before the Serenity release, because all addresses will be
    // contracts then.
    assembly { size := extcodesize(addr) }  // solium-disable-line security/no-inline-assembly
    return size > 0;
  }

}

// File: contracts/ArianeeStore.sol

/**
 * @title Interface for contracts conforming to ERC-20
 */
contract ERC20Interface {
    function transferFrom(address from, address to, uint tokens) public returns (bool success);
    function balanceOf(address owner) public view returns (uint256);
}

/**
 * @title Interface for contracts conforming to ERC-721
 */
contract ERC721Interface {
    function ownerOf(uint256 assetId) public view returns (address);
    function safeTransferFrom(address from, address to, uint256 assetId) public;
    function isAuthorized(address operator, uint256 assetId) public view returns (bool);
    function createFor(address _for, string value) public returns (uint256);

}

contract ArianeeStore is Pausable, ERC900BasicStakeContract {
  using SafeMath for uint256;
  using AddressUtils for address;


    ERC20Interface public acceptedToken;
    ERC721Interface public nonFungibleRegistry;


    // Credits for each user for each service
    mapping (address => mapping (uint256 => uint256)) public credits;
    
    // Credits Price for each user for each service
    mapping (address => mapping (uint256 => uint256)) public creditsPricesPerAccount;
    
    
    // 1 => smart asset
    // 2 => message
    // 3 => service
    mapping (uint256 => uint256) public creditPrices;
    
    


  /**
    * @dev Initialize this contract. Acts as a constructor
    * @param _acceptedToken - Address of the ERC20 accepted for this store
    * @param _nonFungibleRegistry - Address of the NFT address
    */
    
  constructor(
    ERC20 _acceptedToken,
    ERC721 _nonFungibleRegistry
  )
    public ERC900BasicStakeContract(_acceptedToken)
  {

    //Pausable(msg.sender);
    
    //require(_acceptedToken.isContract(), "The accepted token address must be a deployed contract");
    acceptedToken = ERC20Interface(_acceptedToken);
    nonFungibleRegistry = ERC721Interface(_nonFungibleRegistry);

  }
  

  function setCreditPrice(uint256 creditType, uint256 price) public onlyOwner() returns (bool) {
    creditPrices[creditType] = price;
  }
  
  
  function getCreditPrice(uint256 creditType) public view returns (uint256) {
    return creditPrices[creditType];
  }
  
  function buyCredit(uint256 creditType, uint256 quantity) public returns (bool) {
      
      uint256 tokens = quantity * creditPrices[creditType];
      
      // Transfer required token quantity to buy quantity credit
      require(acceptedToken.transferFrom(
                msg.sender,
                owner,
                tokens
            ));
      

      uint256 currentPriceCost = creditsPricesPerAccount[msg.sender][creditType] * credits[msg.sender][creditType];



      // Update credit quantity
      credits[msg.sender][creditType] += quantity;

      // Update avg credit Price
      creditsPricesPerAccount[msg.sender][creditType] = (currentPriceCost+tokens)/credits[msg.sender][creditType];
      
      return true;
  }


  modifier spendSmartAssetsCredit(uint256 quantity) {
    require(credits[msg.sender][1]>=quantity);
    credits[msg.sender][1] = credits[msg.sender][1] - quantity;
    _;
  }

  function spendSmartAssetsCreditFunction(uint256 quantity) public returns (bool) {
    require(credits[msg.sender][1]>=quantity);
    credits[msg.sender][1] = credits[msg.sender][1] - quantity;
    return true;
  }

  // 
  function createFor(address _for, string value) public spendSmartAssetsCredit(1) returns (uint256) {

    return nonFungibleRegistry.createFor(_for, value);
  
  }
  

  function transferAria(address to, uint tokens) public returns (bool){
              // Transfer share amount for marketplace Owner.
            return acceptedToken.transferFrom(
                msg.sender,
                to,
                tokens
            );
  }


  function balanceOfAria() public view returns (uint){
              // Transfer share amount for marketplace Owner.


            return acceptedToken.balanceOf(
                msg.sender
            );
  }


}
