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
  
  function changeArianeeStoreAdress(address _newArianeeStoreAdress) onlyOwner() public{
      arianeeStoreAddress = _newArianeeStoreAdress;
  }
  
  function addCreditHistory(address _spender, uint256 _price, uint256 _quantity, uint256 _type) public onlyStore() {
      
      CreditBuy memory _creditBuy = CreditBuy({
          price: _price,
          quantity: _quantity
      });
      
      creditHistory[_spender][_type].push(_creditBuy);
      
  }

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