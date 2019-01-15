pragma solidity ^0.4.24;


import "openzeppelin-solidity/contracts/token/ERC721/ERC721.sol";

import "./ERC900BasicStakeContract.sol";
import "./Ownable.sol";
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
    require(credits[msg.sender][1]>=quantity,"need more credits");
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
