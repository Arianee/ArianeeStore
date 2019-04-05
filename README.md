# Arianee tokenonomy

## Specification

```solidity
  pragma solidity ^0.5.1;
  
  interface ArianeeStore{

    /**
     * @dev This emits when a new address is set.
     */
     event SetAddress(string _addressType, address _newAddress);
     
    /**
     * @dev This emits when a credit's price is changed (in USD)
     */
     event NewCreditPrice(uint256 _creditType, uint256 _price);
      
    /**
     * @dev This emits when the Aria/USD price is changed.
     */
     event NewAriaUSDExchange(uint256 _ariaUSDExchange);
     
    /**
     * @dev This emits when credits are buyed.
     */
     event CreditBuyed(address buyer, address _receiver, uint256 _creditType, uint256 quantity);
     
    /**
     * @dev This emits when a new dispatch percent is set.
     */
     event NewDispatchPercent(uint8 _percentInfra, uint8 _percentBrandsProvider, uint8 _percentOwnerProvider, uint8 _arianeeProject, uint8 _assetHolder);
    
    /**
     * @dev This emit when credits are spended.
     */
     event CreditSpended(uint256 _type,uint256 _quantity);

    /**
     * @dev Change address of the authorized exchange address.
     * @notice This account is the only that can change the Aria/$ exchange rate.
     */
     function setAuthorizedExchangeAddress(address _authorizedExchangeAddress) public;

    /**
     * @dev Change address of the protocol infrastructure.
     * @param _protocolInfraAddress new address of the protocol intfrastructure receiver.
     */
     function setProtocolInfraAddress(address _protocolInfraAddress) public;

    /**
     * @dev Change address of the Arianee project address.
     * @param _arianeeProjectAddress new address of the Arianee project receiver.
     */
     function setArianeeProjectAddress(address _arianeeProjectAddress) public;

    /**
     * @dev Public function change the price of a credit type
     * @dev Can only be called by the owner of the contract
     * @param _creditType uint256 credit type to change the price
     * @param _price uint256 new price
     */
     function setCreditPrice(uint256 _creditType, uint256 _price) public;

    /**
     * @dev Update Aria/USD change
     * @notice Can only be called by the authorized exchange address.
     * @param _ariaUSDExchange price of 1 $cent in aria.
     */
     function setAriaUSDExchange(uint256 _ariaUSDExchange) public;

    /**
     * @dev Public function to buy new credit against Aria
     * @param _creditType uint256 credit type to buy
     * @param _quantity uint256 quantity to buy
     * @param _to receiver of the credits
     */
     function buyCredit(uint256 _creditType, uint256 _quantity, address _to) public;
       
    /**
     * @dev Public function to reserve ArianeeSmartAsset
     * @param _id uint256 id of the NFT
     * @param _to address receiver of the token
     */
     function reserveToken(uint256 _id, address _to)
           
    /**
     * @dev Public function that hydrate token and dispatch rewards.
     * @notice Reserve token if token not reserved.
     * @param _tokenId ID of the NFT to modify.
     * @param _imprint Proof of the certification.
     * @param _uri URI of the JSON certification.
     * @param _encryptedInitialKey Initial encrypted key.
     * @param _tokenRecoveryTimestamp Limit date for the issuer to be able to transfer back the NFT.
     * @param _initialKeyIsRequestKey If true set initial key as request key.
     * @param _providerBrand address of the provider of the interface.
     */
     function hydrateToken(uint256 _tokenId, bytes32 _imprint, string memory _uri, bytes32 _encryptedInitialKey, uint256 _tokenRecoveryTimestamp, bool _initialKeyIsRequestKey, address _providerBrand) public
         
    /**
     * @dev Public function for request a nft and dispatch rewards.
     * @param _tokenId ID of the NFT to transfer.
     * @param _tokenKey String to encode to check transfer token access.
     * @param _keepRequestToken If false erase the access token of the NFT.
     * @param _providerOwner address of the provider of the interface.
     */
     function requestToken(uint256 _tokenId, string memory _tokenKey, bool _keepRequestToken, address _providerOwner) public
         
    /**
     * @dev Change the percent of rewards per actor.
     * @notice Can only be called by owner.
     * @param _percentInfra Percent get by the infrastructure maintener.
     * @param _percentBrandsProvider Percent get by the brand software provider.
     * @param _percentOwnerProvider Percent get by the owner software provider.
     * @param _arianeeProject Percent get by the Arianee fondation.
     * @param _assetHolder Percent get by the asset owner.
     */
     function setDispatchPercent(uint8 _percentInfra, uint8 _percentBrandsProvider, uint8 _percentOwnerProvider, uint8 _arianeeProject, uint8 _assetHolder) public
         
     

}

```