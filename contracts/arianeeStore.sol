pragma solidity 0.5.1;

import "@0xcert/ethereum-utils-contracts/src/contracts/math/safe-math.sol";
import "@0xcert/ethereum-erc721-contracts/src/contracts/nf-token-metadata-enumerable.sol";
import "@0xcert/ethereum-erc20-contracts/src/contracts/token.sol";
import "@0xcert/ethereum-utils-contracts/src/contracts/permission/ownable.sol";
import "./Pausable.sol";

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
    function hydrateToken(uint256 _tokenId, bytes32 _imprint, string memory _uri, address _encryptedInitialKey, uint256 _tokenRecoveryTimestamp, bool _initialKeyIsRequestKey, address _owner) public returns(uint256);
    function requestToken(uint256 _tokenId, bytes32 _hash, bool _keepRequestToken, address _newOwner, bytes memory _signature) public returns(uint256);
    function getRewards(uint256 _tokenId) external view returns(uint256);
}

/**
 * @title Interface to interact with ArianneCreditHistory
 */
contract ArianeeCreditHistory {
    function addCreditHistory(address _spender, uint256 _price, uint256 _quantity, uint256 _type) public;
    function consumeCredits(address _spender, uint256 _type, uint256 _quantity) public returns(uint256);
    function arianeeStoreAddress() public returns(address);
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

    /**
     * @dev Mapping of the credit price in $cent.
     */
    mapping(uint256 => uint256) internal creditPricesUSD;

    /**
     * @dev Mapping of the credit price in Aria.
     */
    mapping(uint256 => uint256) internal creditPrices;

    /**
     * @dev Current exchange rate Aria/$
     */
    uint256 public ariaUSDExchange;

    /**
     * @dev % of rewards dispatch.
     */
    mapping (uint8=>uint8) internal dispatchPercent;
    
    /**
     * @dev Address needed in contract execution.
     */
    address authorizedExchangeAddress;
    address protocolInfraAddress;
    address arianeeProjectAddress;

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
     * @dev Initialize this contract. Acts as a constructor
     * @param _acceptedToken - Address of the ERC20 accepted for this store
     * @param _nonFungibleRegistry - Address of the NFT address
     */
    constructor(
        ERC20 _acceptedToken,
        ERC721 _nonFungibleRegistry,
        address _creditHistoryAddress,
        uint256 _ariaUSDExchange,
        uint256 _creditPricesUSD0,
        uint256 _creditPricesUSD1,
        uint256 _creditPricesUSD2

    )
    public
    {
        acceptedToken = ERC20Interface(address(_acceptedToken));
        nonFungibleRegistry = ERC721Interface(address(_nonFungibleRegistry));
        creditHistory = ArianeeCreditHistory(address(_creditHistoryAddress));

        ariaUSDExchange = _ariaUSDExchange;
        creditPricesUSD[0] = _creditPricesUSD0;
        creditPricesUSD[1] = _creditPricesUSD1;
        creditPricesUSD[2] = _creditPricesUSD2;
        _updateCreditPrice();
    }


    /**
     * @dev Change address of the authorized exchange address.
     * @notice This account is the only that can change the Aria/$ exchange rate.
     */
    function setAuthorizedExchangeAddress(address _authorizedExchangeAddress) public onlyOwner(){
        authorizedExchangeAddress = _authorizedExchangeAddress;
        emit SetAddress("authorizedExchange", _authorizedExchangeAddress);
    }

    /**
     * @dev Change address of the protocol infrastructure.
     * @param _protocolInfraAddress new address of the protocol intfrastructure receiver.
     */
    function setProtocolInfraAddress(address _protocolInfraAddress) public onlyOwner() {
        protocolInfraAddress = _protocolInfraAddress;
        emit SetAddress("protocolInfra", _protocolInfraAddress);
    }

    /**
     * @dev Change address of the Arianee project address.
     * @param _arianeeProjectAddress new address of the Arianee project receiver.
     */
    function setArianeeProjectAddress(address _arianeeProjectAddress) public onlyOwner() {
        arianeeProjectAddress = _arianeeProjectAddress;
        emit SetAddress("arianeeProject", _arianeeProjectAddress);
    }

    /**
     * @dev Public function change the price of a credit type
     * @dev Can only be called by the owner of the contract
     * @param _creditType uint256 credit type to change the price
     * @param _price uint256 new price
     */
    function setCreditPrice(uint256 _creditType, uint256 _price) public onlyOwner() {
        creditPricesUSD[_creditType] = _price;
        _updateCreditPrice();

        emit NewCreditPrice(_creditType, _price);
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

        emit NewAriaUSDExchange(_ariaUSDExchange);
    }

    /**
     * @dev Internal function update creditPrice.
     * @notice creditPrice need to be >100
     */
    function _updateCreditPrice() internal{
        require(creditPricesUSD[0] * ariaUSDExchange >=100);
        require(creditPricesUSD[1] * ariaUSDExchange >=100);
        require(creditPricesUSD[2] * ariaUSDExchange >=100);
        creditPrices[0] = creditPricesUSD[0] * ariaUSDExchange;
        creditPrices[1] = creditPricesUSD[1] * ariaUSDExchange;
        creditPrices[2] = creditPricesUSD[2] * ariaUSDExchange;
    }

    /**
     * @dev Public function send the price a of a credit in aria
     * @param _creditType uint256
     */
    function getCreditPrice(uint256 _creditType) public view returns (uint256) {
        return creditPrices[_creditType];
    }

    /**
     * @dev Public function to buy new credit against Aria
     * @param _creditType uint256 credit type to buy
     * @param _quantity uint256 quantity to buy
     * @param _to receiver of the credits
     */
    function buyCredit(uint256 _creditType, uint256 _quantity, address _to) public whenNotPaused(){

        uint256 tokens = SafeMath.mul(_quantity, creditPrices[_creditType]);

        // Transfer required token quantity to buy quantity credit
        require(acceptedToken.transferFrom(
                msg.sender,
                address(this),
                tokens
            ));

        creditHistory.addCreditHistory(_to, creditPrices[_creditType], _quantity, _creditType);

        emit CreditBuyed(msg.sender, _to, _creditType, _quantity);

    }

    /**
     * @dev Public function to spend credits
     * @param _type credit type used.
     */
    function _spendSmartAssetsCreditFunction(uint256 _type, uint256 _quantity) internal returns (uint256) {
        uint256 rewards = creditHistory.consumeCredits(msg.sender, _type, _quantity);
        emit CreditSpended(_type, _quantity);
        return rewards;
    }

    /**
     * @dev Public function to reserve ArianeeSmartAsset
     * @param _id uint256 id of the NFT
     * @param _to address receiver of the token
     */
    function reserveToken(uint256 _id, address _to) public whenNotPaused(){
        uint256 rewards = _spendSmartAssetsCreditFunction(0, 1);
        nonFungibleRegistry.reserveToken(_id, _to, rewards);
    }

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
    function hydrateToken(uint256 _tokenId, bytes32 _imprint, string memory _uri, address _encryptedInitialKey, uint256 _tokenRecoveryTimestamp, bool _initialKeyIsRequestKey, address _providerBrand) public whenNotPaused(){
        if(nonFungibleRegistry.getRewards(_tokenId) == 0){
            reserveToken(_tokenId, msg.sender);
        }
        uint256 _reward = nonFungibleRegistry.hydrateToken(_tokenId, _imprint, _uri, _encryptedInitialKey, _tokenRecoveryTimestamp, _initialKeyIsRequestKey,  msg.sender);
        _dispatchRewardsAtHydrate(_providerBrand, _reward);
    }
    /**
     * @dev Public function for request a nft and dispatch rewards.
     * @param _tokenId ID of the NFT to transfer.
     * @param _hash Hash of tokenId + newOwner address.
     * @param _keepRequestToken If false erase the access token of the NFT.
     * @param _providerOwner address of the provider of the interface.
     */
    function requestToken(uint256 _tokenId, bytes32 _hash, bool _keepRequestToken, address _providerOwner, bytes memory _signature) public whenNotPaused(){
        uint256 _reward = nonFungibleRegistry.requestToken(_tokenId, _hash, _keepRequestToken, msg.sender, _signature);
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

    function setDispatchPercent(uint8 _percentInfra, uint8 _percentBrandsProvider, uint8 _percentOwnerProvider, uint8 _arianeeProject, uint8 _assetHolder) public onlyOwner(){
        require(_percentInfra+_percentBrandsProvider+_percentOwnerProvider+_arianeeProject+_assetHolder == 100);
        dispatchPercent[0] = _percentInfra;
        dispatchPercent[1] = _percentBrandsProvider;
        dispatchPercent[2] = _percentOwnerProvider;
        dispatchPercent[3] = _arianeeProject;
        dispatchPercent[4] = _assetHolder;

        emit NewDispatchPercent(_percentInfra, _percentBrandsProvider, _percentOwnerProvider, _arianeeProject, _assetHolder);
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
     * @dev Get all Arias from the previous store.
     * @dev Can only be called by the owner.
     * @param _oldStoreAddress address of the previous store.
     */
    function getAriaFromOldStore(address _oldStoreAddress) onlyOwner() public{
        ArianeeStore oldStore = ArianeeStore(address(_oldStoreAddress));
        oldStore.withdrawArias();
    }
    
    /**
     * @dev Withdraw all arias to the new store.
     * @dev Can only be called by the new store.
     */
    function withdrawArias() external{
        require(address(this) != creditHistory.arianeeStoreAddress());
        require(msg.sender == creditHistory.arianeeStoreAddress());
        acceptedToken.transfer(address(creditHistory.arianeeStoreAddress()),acceptedToken.balanceOf(address(this)));
    }
    
    /**
     * @dev The USD credit price per type.
     * @param _creditType for which we want the USD price.
     * @return price in USD.
     */
    function creditPriceUSD(uint256 _creditType) external view returns(uint256 _creditPriceUSD){
        _creditPriceUSD = creditPricesUSD[_creditType];
    }
    
    /**
     * @dev dispatch for rewards.
     * @param _receiver for which we want the % of rewards.
     * @return % of rewards.
     */
    function percentOfDispatch(uint8 _receiver) external view returns(uint8 _percent){
        _percent = dispatchPercent[_receiver];
    }
    
    /**
     * @dev Allow or not a transfer in the SmartAsset contract.
     * @notice not used for now.
     * @param _to Receiver of the NFT.
     * @param _from Actual owner of the NFT.
     * @param _tokenId id of the
     * @return true.
     */
    function canTransfer(address _to,address _from,uint256 _tokenId) external pure returns(bool){
        return true;
    }

}
