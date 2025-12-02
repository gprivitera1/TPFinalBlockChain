// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {
    ERC721
} from "lib/openzeppelin-contracts/contracts/token/ERC721/ERC721.sol";
import {
    ERC721Enumerable
} from "lib/openzeppelin-contracts/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import {
    IERC20
} from "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {
    IERC721
} from "lib/openzeppelin-contracts/contracts/token/ERC721/IERC721.sol";
import {
    Counters
} from "lib/openzeppelin-contracts/contracts/utils/Counters.sol";
import {Ownable} from "lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import {
    ReentrancyGuard
} from "lib/openzeppelin-contracts/contracts/security/ReentrancyGuard.sol";

contract CCNFT is ERC721Enumerable, Ownable, ReentrancyGuard {
    

    event Buy(address indexed buyer, uint256 indexed tokenId, uint256 value);
    event Claim(address indexed claimer, uint256 indexed tokenId);
    event Trade(address indexed buyer, address indexed seller, uint256 indexed tokenId, uint256 value);
    event PutOnSale(uint256 indexed tokenId, uint256 price);

    struct TokenSale {
        bool onSale;
        uint256 price;
    }

    using Counters for Counters.Counter;
    Counters.Counter private tokenIdTracker;

    mapping(uint256 => uint256) public values;
    mapping(uint256 => bool) public validValues;
    mapping(uint256 => TokenSale) public tokensOnSale;
    uint256[] public listTokensOnSale;
    
    address public fundsCollector;
    address public feesCollector;
    bool public canBuy;
    bool public canClaim;
    bool public canTrade;
    uint256 public totalValue;
    uint256 public maxValueToRaise;
    uint16 public buyFee;
    uint16 public tradeFee;
    uint16 public maxBatchCount;
    uint32 public profitToPay;
    IERC20 public fundsToken;

    constructor(string memory name, string memory symbol) ERC721(name, symbol) {
        canBuy = true;
        canClaim = true;
        canTrade = true;
        maxValueToRaise = 1000000 * 10 ** 18;
        buyFee = 100; // 1%
        tradeFee = 50; // 0.5%
        maxBatchCount = 10;
        profitToPay = 500; // 5%
    }

    function buy(uint256 value, uint256 amount) external nonReentrant {
        require(canBuy, "Buying is disabled");
        require(amount > 0 && amount <= maxBatchCount, "Invalid amount");
        require(validValues[value], "Invalid value");
        require(totalValue + (value * amount) <= maxValueToRaise, "Exceeds max value to raise");

        totalValue += value * amount;

        for (uint256 i = 0; i < amount; i++) {
            tokenIdTracker.increment();
            uint256 tokenId = tokenIdTracker.current();
            values[tokenId] = value;
            _safeMint(msg.sender, tokenId);
            emit Buy(msg.sender, tokenId, value);
        }

        uint256 totalCost = value * amount;
        uint256 feeAmount = totalCost * buyFee / 10000;

        require(fundsToken.transferFrom(msg.sender, fundsCollector, totalCost), "Cannot send funds tokens");
        require(fundsToken.transferFrom(msg.sender, feesCollector, feeAmount), "Cannot send fees tokens");
    }

    function claim(uint256[] calldata listTokenId) external nonReentrant {
        require(canClaim, "Claiming is disabled");
        require(listTokenId.length > 0 && listTokenId.length <= maxBatchCount, "Invalid amount");

        uint256 claimValue = 0;
        
        for (uint256 i = 0; i < listTokenId.length; i++) {
            require(_exists(listTokenId[i]), "Token does not exist");
            require(ownerOf(listTokenId[i]) == msg.sender, "Only owner can Claim");
            
            claimValue += values[listTokenId[i]];
            values[listTokenId[i]] = 0;

            TokenSale storage tokenSale = tokensOnSale[listTokenId[i]];
            tokenSale.onSale = false;
            tokenSale.price = 0;
            removeFromArray(listTokensOnSale, listTokenId[i]);
            
            _burn(listTokenId[i]);
            emit Claim(msg.sender, listTokenId[i]);
        }
        
        totalValue -= claimValue;
        
        uint256 totalToTransfer = claimValue + (claimValue * profitToPay / 10000);
        require(fundsToken.transferFrom(fundsCollector, msg.sender, totalToTransfer), "Cannot send funds");
    }

    function trade(uint256 tokenId) external nonReentrant {
        require(canTrade, "Trading is disabled");
        require(_exists(tokenId), "Token does not exist");
        require(ownerOf(tokenId) != msg.sender, "Buyer is the Seller");

        TokenSale storage tokenSale = tokensOnSale[tokenId];
        require(tokenSale.onSale, "Token not On Sale");

        uint256 price = tokenSale.price;
        uint256 feeAmount = price * tradeFee / 10000;
        address seller = ownerOf(tokenId);

        require(fundsToken.transferFrom(msg.sender, seller, price), "Cannot transfer funds to seller");
        require(fundsToken.transferFrom(msg.sender, feesCollector, feeAmount), "Cannot transfer fees");

        emit Trade(msg.sender, seller, tokenId, price);
        _safeTransfer(seller, msg.sender, tokenId, "");

        tokenSale.onSale = false;
        tokenSale.price = 0;
        removeFromArray(listTokensOnSale, tokenId);
    }

    function putOnSale(uint256 tokenId, uint256 price) external {
        require(canTrade, "Trading is disabled");
        require(_exists(tokenId), "Token does not exist");
        require(ownerOf(tokenId) == msg.sender, "Only owner can put on sale");

        TokenSale storage tokenSale = tokensOnSale[tokenId];
        tokenSale.onSale = true;
        tokenSale.price = price;

        addToArray(listTokensOnSale, tokenId);
        emit PutOnSale(tokenId, price);
    }


    function setFundsToken(address token) external onlyOwner {
        require(token != address(0), "Invalid address");
        fundsToken = IERC20(token);
    }

    function setFundsCollector(address _address) external onlyOwner {
        require(_address != address(0), "Invalid address");
        fundsCollector = _address;
    }

    function setFeesCollector(address _address) external onlyOwner {
        require(_address != address(0), "Invalid address");
        feesCollector = _address;
    }

    function setProfitToPay(uint32 _profitToPay) external onlyOwner {
        profitToPay = _profitToPay;
    }

    function setCanBuy(bool _canBuy) external onlyOwner {
        canBuy = _canBuy;
    }

    function setCanClaim(bool _canClaim) external onlyOwner {
        canClaim = _canClaim;
    }

    function setCanTrade(bool _canTrade) external onlyOwner {
        canTrade = _canTrade;
    }

    function setMaxValueToRaise(uint256 _maxValueToRaise) external onlyOwner {
        maxValueToRaise = _maxValueToRaise;
    }
    
    function addValidValues(uint256 value) external onlyOwner {
        validValues[value] = true;
    }

    function setMaxBatchCount(uint16 _maxBatchCount) external onlyOwner {
        maxBatchCount = _maxBatchCount;
    }

    function setBuyFee(uint16 _buyFee) external onlyOwner {
        buyFee = _buyFee;
    }

    function setTradeFee(uint16 _tradeFee) external onlyOwner {
        tradeFee = _tradeFee;
    }

    function addToArray(uint256[] storage list, uint256 value) private {
        uint256 index = find(list, value);
        if (index == list.length) {
            list.push(value);
        }
    }

    function removeFromArray(uint256[] storage list, uint256 value) private {
        uint256 index = find(list, value);
        if (index < list.length) {
            list[index] = list[list.length - 1];
            list.pop();
        }
    }

    function find(uint256[] storage list, uint256 value) private view returns(uint256) {
        for (uint256 i = 0; i < list.length; i++) {
            if (list[i] == value) {
                return i;
            }
        }
        return list.length;
    }

    function transferFrom(address, address, uint256) 
        public 
        pure
        override(ERC721, IERC721) 
    {
        revert("Not Allowed");
    }

    function safeTransferFrom(address, address, uint256) 
        public pure override(ERC721, IERC721) 
    {
        revert("Not Allowed");
    }

    function safeTransferFrom(address, address, uint256,  bytes memory) 
        public 
        pure
        override(ERC721, IERC721) 
    {
        revert("Not Allowed");
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal 
        override(ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }
    
    function getTokensOnSale() external view returns(uint256[] memory) {
        return listTokensOnSale;
    }
}