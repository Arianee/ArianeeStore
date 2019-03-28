pragma solidity 0.5.1;

import "@0xcert/ethereum-utils-contracts/src/contracts/permission/ownable.sol";

contract ArianeeCreditHistory is Ownable{
    
    
  mapping(address => mapping(uint256=>CreditBuy[])) public creditHistory;
  
  mapping(address => mapping(uint256=>uint256)) public historyIndex;
  
  address public arianeeStoreAddress;
  
  struct CreditBuy{
      uint256 price;
      uint256 quantity;
  }
  
   modifier onlyStore(){
        require(msg.sender == arianeeStoreAddress, 'not called by store');
        _;
    }
  
  /**
   * @dev public function that change the store contract address.
   * @notice Can only be called by the contract owner.
   */
  function changeArianeeStoreAdress(address _newArianeeStoreAdress) onlyOwner() public{
      arianeeStoreAddress = _newArianeeStoreAdress;
  }
  
  /**
   * @dev public funciton that add a credit history when credit are bought.
   * @notice can only be called by the store.
   * @param _spender address of the buyer
   * @param _price current price of the credit.
   * @param _quantity of credit buyed.
   * @param _type of credit buyed.
   */
  function addCreditHistory(address _spender, uint256 _price, uint256 _quantity, uint256 _type) public onlyStore() {
      
      CreditBuy memory _creditBuy = CreditBuy({
          price: _price,
          quantity: _quantity
      });
      
      creditHistory[_spender][_type].push(_creditBuy);
      
  }

    /**
     * @dev Public function that return the price of the oldest non spended credit.
     * @notice Can only be called by the store.
     * @param _spender address of the buyer.
     * @param _type type of credit.
     * @return price of the credit.
     */
    function getCreditPrice(address _spender, uint256 _type) public onlyStore() returns (uint256){
        uint256 _index = historyIndex[_spender][_type];
        uint256 price = creditHistory[_spender][_type][_index].price;
        creditHistory[_spender][_type][_index].quantity = creditHistory[_spender][_type][_index].quantity-1;
        
        if(creditHistory[_spender][_type][_index].quantity == 0){
            historyIndex[_spender][_type] = _index + 1;
        }
        
        return price;
        
    }
    
}