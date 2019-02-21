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

    function balanceOf(address owner) public view returns (uint256);
}

/**
 * @title Interface for contracts conforming to ERC-721
 */
contract ERC721Interface {
    function reserveToken(uint256 id) public;
    function reserveTokens(uint256 _first, uint256 _last) public;
    function hydrateToken(uint256 _tokenId, bytes32 _imprint, string memory _uri, bytes32 _encryptedInitialKey, uint256 _tokenRecoveryTimestamp, bool _initialKeyIsRequestKey) public;
    function requestToken(uint256 _tokenId, string memory _tokenKey, bool _keepRequestToken) public;
}

contract ArianeeCreditHistory {
    function addCreditHistory(address _spender, uint256 _price, uint256 _quantity, uint256 _type) public;
    function getCreditPrice(address _spender, uint256 _type) public returns(uint256);
}

contract ArianeeMessage {
    function sendMessage(uint256 _tokenId, string memory _uri, bytes32 _imprint) public;
}

contract ArianeeStore is Pausable {
    using SafeMath for uint256;
    using AddressUtils for address;


    ERC20Interface public acceptedToken;
    ERC721Interface public nonFungibleRegistry;
    ArianeeCreditHistory public creditHistory;
    ArianeeMessage public message;


    // Credits for each user for each service
    mapping(address => mapping(uint256 => uint256)) public credits;

    // Credits Price for each user for each service
    mapping(address => mapping(uint256 => uint256)) public creditsPricesPerAccount;


    // 1 => smart asset
    // 2 => message
    // 3 => service
    mapping(uint256 => uint256) public creditPricesUSD;
    mapping(uint256 => uint256) public creditPrices;
    uint256 public ariaUSDExchange;
    address public authorizedExchangeAddress;
    
    mapping(uint256=>uint256) tokenFeePrice;

    /**
     * @dev Initialize this contract. Acts as a constructor
     * @param _acceptedToken - Address of the ERC20 accepted for this store
     * @param _nonFungibleRegistry - Address of the NFT address
     */
    constructor(
        ERC20 _acceptedToken,
        ERC721 _nonFungibleRegistry,
        address _creditHistoryAddress,
        address _messageAddress
        
    )
    public 
    {

        //Pausable(msg.sender);

        //require(_acceptedToken.isContract(), "The accepted token address must be a deployed contract");
        acceptedToken = ERC20Interface(address(_acceptedToken));
        nonFungibleRegistry = ERC721Interface(address(_nonFungibleRegistry));
        creditHistory = ArianeeCreditHistory(address(_creditHistoryAddress));
        message = ArianeeMessage(address(_messageAddress));

    }


    /**
     * @dev Public function change the price of a credit type
     * @dev Can only be called by the owner of the contract
     * @param _creditType uint256 credit type to change the price
     * @param _price uint256 new price
     */
    function setCreditPrice(uint256 _creditType, uint256 _price) public onlyOwner() returns (bool) {
        creditPricesUSD[_creditType] = _price;
    }
    
    /**
    *
    * @param _ariaUSDExchange price of 1 $cent in aria
    */
    
    function setAriaUSDExchange(uint256 _ariaUSDExchange) public {
        require(msg.sender == authorizedExchangeAddress);
        ariaUSDExchange = _ariaUSDExchange;
        creditPrices[0] = creditPricesUSD[0] * _ariaUSDExchange;
        creditPrices[1] = creditPricesUSD[1] * _ariaUSDExchange;
        creditPrices[2] = creditPricesUSD[2] * _ariaUSDExchange;
    }
    
    function setAuthorizedExchangeAddress(address _authorizedExchangeAddress) public onlyOwner(){
        authorizedExchangeAddress = _authorizedExchangeAddress;
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
     */
    function buyCredit(uint256 _creditType, uint256 _quantity) public returns (bool) {

        uint256 tokens = SafeMath.mul(_quantity, creditPrices[_creditType]);

        // Transfer required token quantity to buy quantity credit
        require(acceptedToken.transferFrom(
                msg.sender,
                owner,
                tokens
            ));
        
        creditHistory.addCreditHistory(msg.sender, creditPrices[_creditType], _quantity, _creditType);

        // Update credit quantity
        credits[msg.sender][_creditType] = SafeMath.add(credits[msg.sender][_creditType], _quantity);
        
        return true;
    }

    /**
     * @dev Modifier that spend credits
     * @param _quantity uint256 quantity of credit to spend
     */
    modifier spendCredit(uint256 _quantity, uint256 _type) {
        require(credits[msg.sender][_type] >= _quantity);
        credits[msg.sender][_type] = SafeMath.sub(credits[msg.sender][_type], _quantity);
        _;
    }

    /**
     * @dev Public function to spend credits
     * @param _quantity uint256 quantity of credit to spend
     */
    function spendSmartAssetsCreditFunction(uint256 _quantity) public returns (bool) {
        require(credits[msg.sender][1] >= _quantity, "need more credits");
        credits[msg.sender][1] = SafeMath.sub(credits[msg.sender][1], _quantity);
        return true;
    }

    /**
     * @dev Public function to reserve ArianeeSmartAsset
     * @param _id uint256 id of the NFT
     */
    function reserveToken(uint256 _id) public spendCredit(1, 0) {
        nonFungibleRegistry.reserveToken(_id);
    }

    /**
     * @dev Public function to reserve several ArianeeSmartAsset
     * @param _first uint256 first ID to reserve
     * @param _last uint256 last ID to reserve
     */
    function reserveTokens(uint256 _first, uint256 _last) public {
        uint256 _idsNb = SafeMath.sub(_last, _first);
        spendSmartAssetsCreditFunction(_idsNb);
        nonFungibleRegistry.reserveTokens(_first, _last);
    }
    
    function hydrateToken(uint256 _tokenId, bytes32 _imprint, string memory _uri, bytes32 _encryptedInitialKey, uint256 _tokenRecoveryTimestamp, bool _initialKeyIsRequestKey, address _providerBrand) public {
        _dispatchRewardsAtHydrate(_tokenId, _providerBrand);
        nonFungibleRegistry.hydrateToken(_tokenId, _imprint, _uri, _encryptedInitialKey, _tokenRecoveryTimestamp, _initialKeyIsRequestKey);
    }
    
    function requestToken(uint256 _tokenId, string memory _tokenKey, bool _keepRequestToken, address _providerOwner) public {
        _dispatchRewardsAtRequest(_tokenId, _providerOwner);
        nonFungibleRegistry.requestToken(_tokenId, _tokenKey, _keepRequestToken);
    }
    
    address protocolInfraAddress;
    address arianeeProjectAddress;
    
    function setProtoCalInfraAddress(address _protocolInfraAddress) public onlyOwner() {
        protocolInfraAddress = _protocolInfraAddress;
    }
    
    function setArianeeProjectAddress(address _arianeeProjectAddress) public onlyOwner() {
        arianeeProjectAddress = _arianeeProjectAddress;
    }
    
    
    
    function _dispatchRewardsAtHydrate(uint256 _tokenId, address _providerBrand) internal{
        uint256 ariaToDispatch = creditHistory.getCreditPrice(msg.sender, 0);
        tokenFeePrice[_tokenId] = ariaToDispatch;
        acceptedToken.transferFrom(owner,protocolInfraAddress,(ariaToDispatch/100)*10);
        acceptedToken.transferFrom(owner,arianeeProjectAddress,(ariaToDispatch/100)*40);
        acceptedToken.transferFrom(owner,_providerBrand,(ariaToDispatch/100)*20);
    }
    
    function _dispatchRewardsAtRequest(uint256 _tokenId, address _providerOwner) internal{
        uint256 ariaToDispatch = tokenFeePrice[_tokenId];
        acceptedToken.transferFrom(owner,_providerOwner,(ariaToDispatch/100)*20);
        acceptedToken.transferFrom(owner,msg.sender,(ariaToDispatch/100)*10);
        delete tokenFeePrice[_tokenId];
    }

    function sendMessage(uint256 _tokenId, string memory _uri, bytes32 _imprint) public spendCredit(1,1){
        message.sendMessage(_tokenId, _uri, _imprint);
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
