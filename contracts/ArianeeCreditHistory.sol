pragma solidity 0.5.1;

contract ArianeeCreditHistory{
    
    
    mapping(address => mapping(uint256=>CreditBuy[])) public creditHistory;
  
  mapping(address => uint256[]) public historyIndex;
  
  struct CreditBuy{
      uint256 price;
      uint256 quantity;
  }
  
  //TODO add only callable by stores
  
  function addCreditHistory(address _spender, uint256 _price, uint256 _quantity, uint256 _type) public{
      
      CreditBuy memory _creditBuy = CreditBuy({
          price: _price,
          quantity: _quantity
      });
      
      creditHistory[_spender][_type].push(_creditBuy);
  }

    function getCreditPrice(address _spender, uint256 _type) public returns (uint256){
        uint256 _index = historyIndex[_spender][_type];
        uint256 price = creditHistory[_spender][_type][_index].price;
        creditHistory[_spender][_type][_index].quantity = creditHistory[_spender][_type][_index].quantity-1;
        
        if(creditHistory[_spender][_type][_index].quantity == 0){
            historyIndex[_spender][_type] = _index + 1;
        }
        
        return price;
        
    }
    
}