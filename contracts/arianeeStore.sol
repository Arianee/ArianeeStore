pragma solidity 0.5.1;

import "@0xcert/ethereum-utils-contracts/src/contracts/math/safe-math.sol";
import "@0xcert/ethereum-erc721-contracts/src/contracts/nf-token-metadata-enumerable.sol";
import "@0xcert/ethereum-erc20-contracts/src/contracts/token.sol";

import "./Ownable.sol";
// File: openzeppelin-zos/contracts/lifecycle/Pausable.sol

/**
 * @title Pausable
 * @dev Base contract which allows children to implement an emergency stop mechanism.
 */
contract Pausable is Ownable {
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
    function transfer(address to, uint tokens) public returns (bool success);
    function balanceOf(address owner) public view returns (uint256);
}

/**
 * @title Interface for contracts conforming to ERC-721
 */
contract ERC721Interface {
    function reserveToken(uint256 id, address _to, uint256 _rewards) public;
    function reserveTokens(uint256 _first, uint256 _last, address _to, uint256 _rewards) public;
    function hydrateToken(uint256 _tokenId, bytes32 _imprint, string memory _uri, bytes32 _encryptedInitialKey, uint256 _tokenRecoveryTimestamp, bool _initialKeyIsRequestKey) public returns(uint256);
    function requestToken(uint256 _tokenId, string memory _tokenKey, bool _keepRequestToken) public returns(uint256);
}

contract ArianeeCreditHistory {
    function addCreditHistory(address _spender, uint256 _price, uint256 _quantity, uint256 _type) public;
    function getCreditPrice(address _spender, uint256 _type, uint256 _quantity) public returns(uint256);
    function arianeeStoreAddress() public returns(address);
}

contract ArianeeMessage {
    function sendMessage(uint256 _tokenId, string memory _uri, bytes32 _imprint, address _to, uint256 _reward) public returns(uint256);
    function readMessage(uint256 _tokenId, uint256 _messageId) public returns(uint256);
}

contract ArianeeService {
    function createService(uint256 _tokenId, string memory _uri, bytes32 _imprint, uint256 _reward) public returns(uint256);
    function acceptService(uint256 _tokenId, uint256 serviceId) public returns(uint256);
}

contract ArianeeStore is Pausable {
    using SafeMath for uint256;
    using AddressUtils for address;

    /**
     * Interface for all the connected contracts.
     */
    ERC20Interface public acceptedToken;
    ERC721Interface public nonFungibleRegistry;
    ArianeeCreditHistory public creditHistory;
    ArianeeMessage public arianeeMessage;
    ArianeeService public arianeeService;

    /**
     * @dev Mapping of the credit price in $cent.
     */
    mapping(uint256 => uint256) public creditPricesUSD;
    /**
     * @dev Mapping of the credit price in Aria.
     */
    mapping(uint256 => uint256) public creditPrices;
    /**
     * @dev Current exchange rate Aria/$
     */
    uint256 public ariaUSDExchange;
    
    /**
     * @dev % of rewards dispatch.
     */
    mapping (uint8=>uint8) dispatchPercent;
    
    address authorizedExchangeAddress;
    address protocolInfraAddress;
    address arianeeProjectAddress;
    
    
    mapping(uint256=>mapping(uint256=>uint256)) tokenFeePrice;

    /**
     * @dev Initialize this contract. Acts as a constructor
     * @param _acceptedToken - Address of the ERC20 accepted for this store
     * @param _nonFungibleRegistry - Address of the NFT address
     */
    constructor(
        ERC20 _acceptedToken,
        ERC721 _nonFungibleRegistry,
        address _creditHistoryAddress
        
    )
    public 
    {
        acceptedToken = ERC20Interface(address(_acceptedToken));
        nonFungibleRegistry = ERC721Interface(address(_nonFungibleRegistry));
        creditHistory = ArianeeCreditHistory(address(_creditHistoryAddress));
    }
    
    /**
     * @dev Change address of the Arianee message contract.
     * @param _arianeeMessageAddress new address of the contract.
     */
    function changeArianeeMessageAddress(address _arianeeMessageAddress) public onlyOwner() {
        arianeeMessage = ArianeeMessage(address(_arianeeMessageAddress));
    } 
    
    /**
     * @dev Change address of the Arianee service contract.
     * @param _arianeeServiceAddress new address of the contract
     */
    function changeArianeeServiceAddress(address _arianeeServiceAddress) public onlyOwner() {
        arianeeService = ArianeeService(address(_arianeeServiceAddress));
    } 
    
    /**
     * @dev Change address of the authorized exchange address.
     * @notice This account is the only that can change the Aria/$ exchange rate.
     */
    function setAuthorizedExchangeAddress(address _authorizedExchangeAddress) public onlyOwner(){
        authorizedExchangeAddress = _authorizedExchangeAddress;
    }
    
    /**
     * @dev Change address of the protocol infrastructure.
     * @param _protocolInfraAddress new address of the protocol intfrastructure receiver.
     */
    function setProtocolInfraAddress(address _protocolInfraAddress) public onlyOwner() {
        protocolInfraAddress = _protocolInfraAddress;
    }
    
    /**
     * @dev Change address of the Arianee project address.
     * @param _arianeeProjectAddress new address of the Arianee project receiver.
     */
    function setArianeeProjectAddress(address _arianeeProjectAddress) public onlyOwner() {
        arianeeProjectAddress = _arianeeProjectAddress;
    }

    /**
     * @dev Public function change the price of a credit type
     * @dev Can only be called by the owner of the contract
     * @param _creditType uint256 credit type to change the price
     * @param _price uint256 new price
     */
    function setCreditPrice(uint256 _creditType, uint256 _price) public onlyOwner() returns (bool) {
        creditPricesUSD[_creditType] = _price;
        _updateCreditPrice();
    }
    
    /**
     * @dev Update Aria/USD change
     * @notice Can only be called by the authorized exchange address.
     * @param _ariaUSDExchange price of 1 $cent in aria.
    */
    
    function setAriaUSDExchange(uint256 _ariaUSDExchange) public {
        require(msg.sender == authorizedExchangeAddress);
        ariaUSDExchange = _ariaUSDExchange;
        _updateCreditPrice();
    }
    
    /**
     * @dev Internal function update creditPrice.
     * @notice creditPrice need to be >100
     */
    function _updateCreditPrice() internal{
        require(creditPricesUSD[0] * ariaUSDExchange > 100);
        require(creditPricesUSD[1] * ariaUSDExchange > 100);
        require(creditPricesUSD[2] * ariaUSDExchange > 100);
        creditPrices[0] = creditPricesUSD[0] * ariaUSDExchange;
        creditPrices[1] = creditPricesUSD[1] * ariaUSDExchange;
        creditPrices[2] = creditPricesUSD[2] * ariaUSDExchange;
    }

    /**
     * @dev Public function send the price a of a credit
     * @param _creditType uint256
     */
    function getCreditPrice(uint256 _creditType) public view returns (uint256) {
        return creditPricesUSD[_creditType];
    }

    /**
     * @dev Public function to buy new credit against Aria
     * @param _creditType uint256 credit type to buy
     * @param _quantity uint256 quantity to buy
     * @param _to receiver of the credits
     */
    function buyCredit(uint256 _creditType, uint256 _quantity, address _to) public returns (bool) {

        uint256 tokens = SafeMath.mul(_quantity, creditPrices[_creditType]);

        // Transfer required token quantity to buy quantity credit
        require(acceptedToken.transferFrom(
                msg.sender,
                address(this),
                tokens
            ));
        
        creditHistory.addCreditHistory(_to, creditPrices[_creditType], _quantity, _creditType);
        
        return true;
    }

    /**
     * @dev Public function to spend credits
     * @param _type credit type used.
     */
    function _spendSmartAssetsCreditFunction(uint256 _type, uint256 _quantity) internal returns (uint256) {
        uint256 rewards = creditHistory.getCreditPrice(msg.sender, _type, _quantity);
        return rewards;
    }

    /**
     * @dev Public function to reserve ArianeeSmartAsset
     * @param _id uint256 id of the NFT
     * @param _to address receiver of the token
     */
    function reserveToken(uint256 _id, address _to) public {
        uint256 rewards = _spendSmartAssetsCreditFunction(0, 1);
        nonFungibleRegistry.reserveToken(_id, _to, rewards);
    }

    /**
     * @dev Public function to reserve several ArianeeSmartAsset
     * @param _first uint256 first ID to reserve
     * @param _last uint256 last ID to reserve
     */
    function reserveTokens(uint256 _first, uint256 _last, address _to) public {
        uint256 _idsNb = SafeMath.sub(_last, _first);
        uint256 reward = _spendSmartAssetsCreditFunction(0, _idsNb);
        nonFungibleRegistry.reserveTokens(_first, _last, _to, reward);
    }
    
    /**
     * @dev Public function that hydrate token and dispatch rewards.
     * @param _tokenId ID of the NFT to modify.
     * @param _imprint Proof of the certification.
     * @param _uri URI of the JSON certification.
     * @param _encryptedInitialKey Initial encrypted key.
     * @param _tokenRecoveryTimestamp Limit date for the issuer to be able to transfer back the NFT.
     * @param _initialKeyIsRequestKey If true set initial key as request key.
     * @param _providerBrand address of the provider of the interface.
     */
    function i(uint256 _tokenId, bytes32 _imprint, string memory _uri, bytes32 _encryptedInitialKey, uint256 _tokenRecoveryTimestamp, bool _initialKeyIsRequestKey, address _providerBrand) public {
        uint256 _reward = nonFungibleRegistry.hydrateToken(_tokenId, _imprint, _uri, _encryptedInitialKey, _tokenRecoveryTimestamp, _initialKeyIsRequestKey);
        _dispatchRewardsAtHydrate(_providerBrand, _reward);
    }
    /**
     * @dev Public function for reqeust a nft and dispatch rewards.
     * @param _tokenId ID of the NFT to transfer.
     * @param _tokenKey String to encode to check transfer token access.
     * @param _keepRequestToken If false erase the access token of the NFT.
     * @param _providerOwner address of the provider of the interface.
     */
    function requestToken(uint256 _tokenId, string memory _tokenKey, bool _keepRequestToken, address _providerOwner) public {
        uint256 _reward = nonFungibleRegistry.requestToken(_tokenId, _tokenKey, _keepRequestToken);
        _dispatchRewardsAtRequest(_providerOwner, _reward);
    }
    /**
     * @dev Change the percent of rewards per actor.
     * @notice Can only be called by owner.
     * @param _percentInfra Percent get by the infrastructure maintener.
     * @param _percentBrandsProvider Percent get by the brand software provider.
     * @param _percentOwnerProvider Percent get by the owner software provider.
     * @param _arianeeProject Percent get by the Arianee fondation.
     * @param _assetHolder Percent get by the asset owner.
     */
    
    function changeDispatchPercent(uint8 _percentInfra, uint8 _percentBrandsProvider, uint8 _percentOwnerProvider, uint8 _arianeeProject, uint8 _assetHolder) public onlyOwner(){
        require(_percentInfra+_percentBrandsProvider+_percentOwnerProvider+_arianeeProject+_assetHolder == 100);
        dispatchPercent[0] = _percentInfra;
        dispatchPercent[1] = _percentBrandsProvider;
        dispatchPercent[2] = _percentOwnerProvider;
        dispatchPercent[3] = _arianeeProject;
        dispatchPercent[4] = _assetHolder;
    }
    
    /**
     * @dev Internal function that dispatch rewards at creation.
     * @param _providerBrand address of the provider of the interface.
     * @param _reward reward for this token.
     */
    function _dispatchRewardsAtHydrate(address _providerBrand, uint256 _reward) internal{
        acceptedToken.transfer(protocolInfraAddress,(_reward/100)*dispatchPercent[0]);
        acceptedToken.transfer(arianeeProjectAddress,(_reward/100)*dispatchPercent[3]);
        acceptedToken.transfer(_providerBrand,(_reward/100)*dispatchPercent[1]);
    }
    
    /**
     * @dev Internal function that dispatch rewards at client reception
     * @param _providerOwner address of the provider of the interface.
     * @param _reward reward for this token.
     */
    
    function _dispatchRewardsAtRequest(address _providerOwner, uint256 _reward) internal{
            acceptedToken.transfer(_providerOwner,(_reward/100)*dispatchPercent[2]);
            acceptedToken.transfer(msg.sender,(_reward/100)*dispatchPercent[4]);
    }
    
    /** 
     * @dev Public function that send a message to a NFT owner attached to a NFT.
     * @param _tokenId token associated to the message
     * @param _uri URI of the message
     * @param _imprint of the message
     * @param _to receiver of the message
     * @param _providerBrand address of the provider of the interface.
     */
    function sendMessage(uint256 _tokenId, string memory _uri, bytes32 _imprint, address _to, address _providerBrand) public returns(uint256){
        uint256 _reward = _spendSmartAssetsCreditFunction(1, 1);
        require(msg.sender != _to);
        uint256 _messageId = arianeeMessage.sendMessage(_tokenId, _uri, _imprint, _to, _reward);
        _dispatchRewardsAtHydrate(_providerBrand,  _reward);
        return _messageId;
    }
    
    /**
     * @dev Public function that indicate a message as read and dispatch rewards
     * @param _tokenId token associated to the message.
     * @param _messageId Id of the message readed.
     * @param _providerOwner address of the provider of the interface.
     */
    function readMessage(uint256 _tokenId, uint256 _messageId, address _providerOwner) public {
        uint256 _reward = arianeeMessage.readMessage(_tokenId, _messageId);
        _dispatchRewardsAtRequest(_providerOwner, _reward);
    }
    
    
    /**
     * @dev Public function that create a service and dispatch rewards.
     * @param _tokenId id of the NFT associated with the service.
     * @param _uri of the JSON associated with the service.
     * @param _imprint of the JSON.
     * @param _providerBrand address of the provider of the interface.
     */
     function createService(uint256 _tokenId, string memory _uri, bytes32 _imprint,  address _providerBrand) public returns(uint256){
         uint256 _reward = _spendSmartAssetsCreditFunction(2, 1);
        uint256 _serviceId = arianeeService.createService(_tokenId,  _uri, _imprint, _reward);
        _dispatchRewardsAtHydrate(_providerBrand, _reward);
        return _serviceId;
     }
     
     /**
      * @dev Public function that accept a service an dispatch rewards.
      * @notice Can only be called by an operator of the NFT.
      * @param _tokenId id of the NFT.
      * @param _serviceId id of the service.
      * @param _providerOwner address of the provider of the interface
      */
     function acceptService(uint256 _tokenId, uint256 _serviceId, address _providerOwner) public {
         uint256 reward = arianeeService.acceptService(_tokenId, _serviceId);
         _dispatchRewardsAtRequest(_providerOwner, reward);
     }
     
     /**
      * @dev Send all aria owned by this contract to the contract owner.
      * @notice Can only be called by the owner.
      * @notice Can only be called if the creditHistory contract is not using this store anymore.
      * 
      */
     function withdrawAria() onlyOwner() public{
        require(address(this) != creditHistory.arianeeStoreAddress());
        acceptedToken.transfer(owner,acceptedToken.balanceOf(address(this)));
     }

}
