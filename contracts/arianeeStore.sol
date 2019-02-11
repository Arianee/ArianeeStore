pragma solidity 0.5.1;

import "@0xcert/ethereum-utils-contracts/src/contracts/math/safe-math.sol";
import "@0xcert/ethereum-erc721-contracts/src/contracts/nf-token-metadata-enumerable.sol";

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
  
  using SafeMath for uint256;

  bool public paused = false;

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
    function reserveToken(uint256 id) public;
    function reserveTokens(uint256 _first, uint256 _last) public;
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
    acceptedToken = ERC20Interface(address(_acceptedToken));
    nonFungibleRegistry = ERC721Interface(address(_nonFungibleRegistry));

  }
  

/**
 * @dev Public function change the price of a credit type
 * @dev Can only be called by the owner of the contract
 * @param _creditType uint256 credit type to change the price
 * @param _price uint256 new price
 */
  function setCreditPrice(uint256 _creditType, uint256 _price) public onlyOwner() returns (bool) {
    creditPrices[_creditType] = _price;
  }
  
  /**
   * @dev Public function send the price a of a credit 
   * @param _creditType uint256
   */
  function getCreditPrice(uint256 _creditType) public view returns (uint256) {
    return creditPrices[_creditType];
  }
  
  /**
   * @dev Public function to buy new credit against Aria
   * @param _creditType uint256 credit type to buy
   * @param _quantity uint256 quantity to buy
  */
  function buyCredit(uint256 _creditType, uint256 _quantity) public returns (bool) {
      
      uint256 tokens = SafeMath.mul(_quantity, creditPrices[_creditType]);
      
      // Transfer required token quantity to buy quantity credit
      require(acceptedToken.transferFrom(
                msg.sender,
                owner,
                tokens
            ));
      

      uint256 currentPriceCost = SafeMath.mul(creditsPricesPerAccount[msg.sender][_creditType], credits[msg.sender][_creditType]);

      // Update credit quantity
      credits[msg.sender][_creditType] = SafeMath.add(credits[msg.sender][_creditType] , _quantity);

      // Update avg credit Price
      creditsPricesPerAccount[msg.sender][_creditType] = SafeMath.div((SafeMath.add(currentPriceCost, tokens)),credits[msg.sender][_creditType]);
      
      return true;
  }

    /**
     * @dev Modifier that spend credit
     * @param _quantity uint256 quantity of credit to spend
     */
  modifier spendSmartAssetsCredit(uint256 _quantity) {
    require(credits[msg.sender][1]>=_quantity);
    credits[msg.sender][1] = SafeMath.sub(credits[msg.sender][1], _quantity);
    _;
  }

/**
 * @dev Public function to spend credits
 * @param _quantity uint256 quantity of credit to spend
 */
  function spendSmartAssetsCreditFunction(uint256 _quantity) public returns (bool) {
    require(credits[msg.sender][1]>=_quantity,"need more credits");
    credits[msg.sender][1] = SafeMath.sub(credits[msg.sender][1], _quantity);
    return true;
  }

  /**
   * @dev Public function to reserve ArianeeSmartAsset
   * @param _id uint256 id of the NFT
   */
  function reserveToken(uint256 _id) public spendSmartAssetsCredit(1){
    nonFungibleRegistry.reserveToken(_id);
  }
  
  /**
   * @dev Public function to reserve several ArianeeSmartAsset
   * @param _first uint256 first ID to reserve
   * @param _last uint256 last ID to reserve
   */
  function reserveTokens(uint256 _first, uint256 _last) public{
      uint256 _idsNb = SafeMath.sub(_last, _first);
      spendSmartAssetsCreditFunction(_idsNb);
      nonFungibleRegistry.reserveTokens(_first, _last);
  }
  

    /**
     * @dev Public function to transfer Arias 
     * @param _to address address to send the Arias
     * @param _quantity uint256 quantity to send
     */
  function transferAria(address _to, uint _quantity) public returns (bool){
          // Transfer share amount for marketplace Owner.
        return acceptedToken.transferFrom(
            msg.sender,
            _to,
            _quantity
        );
  }

    /**
     * Public function get the msg.sender arias balance
     */
  function balanceOfAria() public view returns (uint){
        // Transfer share amount for marketplace Owner.
        return acceptedToken.balanceOf(msg.sender);
  }


}
