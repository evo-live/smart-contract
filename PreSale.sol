pragma solidity ^0.4.4;

import "github.com/oraclize/ethereum-api/oraclizeAPI.sol";
import "github.com/OpenZeppelin/zeppelin-solidity/contracts/math/SafeMath.sol";
import "github.com/OpenZeppelin/zeppelin-solidity/contracts/ownership/Ownable.sol";
import "github.com/OpenZeppelin/zeppelin-solidity/contracts/lifecycle/Pausable.sol";

interface ETLToken {
    function transfer(address receiver, uint amount) external;
    function freezePresale(address _to, uint256 _value, uint256 _expireTime) external;
    function freeze2Presale(address _to, uint256 _value, uint256 _expireTime) external;
    function freeze3Presale(address _to, uint256 _value, uint256 _expireTime) external;
}

contract ETLTokenPresale is Pausable, usingOraclize {
    using SafeMath for uint256;

    ETLToken public tokenReward;

    uint256 public minimalPrice = 10000000000000; // 0.00001
    uint256 public tokensRaised;
    uint256 public loyaltyCap = 200000000000000; // 2mln
    uint256 public presaleCap = 400000000000000; // 4mln

    uint256 public expiredTime = 1546300800;
    uint256 constant public fiveZero = 100000;
    uint256 constant public tenZero = 10000000000;
    
    uint256 public ETHUSD;
    event LogPriceUpdated(string price);
    event LogNewOraclizeQuery(string description);

    uint256 public startPresaleTime;
    bool public presaleFinished = false;
    bool public loyaltyPart = true;
    
    modifier whenNotFinished() {
        require(!presaleFinished);
        _;
    }

    function ETLTokenPresale(address _tokenReward) public {
        tokenReward = ETLToken(_tokenReward);
    }

    function getBonus() public view returns (uint256) {
        if (loyaltyPart) return 5;
        else if (!loyaltyPart && block.timestamp <= startPresaleTime.add(2 weeks)) return 5;
        return 3;
    }
    
    function getPrice() public view returns (uint256) {
        if (loyaltyPart == true) return 1;
        return 8;
    }
    
    function () public payable {
        buy(msg.sender);
    }

    function buy(address buyer) whenNotPaused whenNotFinished public payable {
        require(buyer != address(0));
        require(msg.value != 0);
        require(msg.value >= minimalPrice);

        uint256 tokens;
        
        if (loyaltyPart) {
            if (tokensRaised >= loyaltyCap) {
                loyaltyPart = false;
                startPresaleTime = block.timestamp;
            }
            
            uint256 loyaltyTokens = msg.value.mul(ETHUSD).div(fiveZero).div(getPrice()).mul(10).div(tenZero);
            tokens = loyaltyTokens;
            
        } else {
            
            uint256 normalTokens = msg.value.mul(ETHUSD).div(fiveZero).div(getPrice()).mul(10).div(tenZero);
            uint256 bonusTokens = msg.value.mul(ETHUSD).div(fiveZero).div(getPrice()).mul(10).mul(getBonus()).div(10).div(tenZero);
            tokens = normalTokens.add(bonusTokens);
            tokenReward.freezePresale(buyer, bonusTokens, expiredTime);
            
            if (tokensRaised >= presaleCap) {
                presaleFinished = true;
            }
        }
        
        tokensRaised = tokensRaised.add(tokens);
        tokenReward.transfer(buyer, tokens);
        owner.transfer(msg.value);
    }

    function __callback(bytes32 myid, string result) {
        if (msg.sender != oraclize_cbAddress()) {
            revert();
        }
        ETHUSD = stringToUint(result);
        LogPriceUpdated(result);
        if (oraclize_getPrice("URL") > this.balance) {
            LogNewOraclizeQuery("Oraclize query was NOT sent, please add some ETH to cover for the query fee");
        } else {
            LogNewOraclizeQuery("Oraclize query was sent, standing by for the answer..");
            oraclize_query(86400, "URL", "json(https://api.kraken.com/0/public/Ticker?pair=ETHUSD).result.XETHZUSD.c.0");
        }
    }

    function updatePrice() onlyOwner payable {
        if (oraclize_getPrice("URL") > this.balance) {
            LogNewOraclizeQuery("Oraclize query was NOT sent, please add some ETH to cover for the query fee");
        } else {
            LogNewOraclizeQuery("Oraclize query was sent, standing by for the answer..");
            oraclize_query(86400, "URL", "json(https://api.kraken.com/0/public/Ticker?pair=ETHUSD).result.XETHZUSD.c.0");
        }
    }

    function stringToUint(string s) public pure returns (uint result) {
        bytes memory b = bytes(s);
        uint i;
        result = 0;
        for (i = 0; i < b.length; i++) {
            uint c = uint(b[i]);
            if (c >= 48 && c <= 57) {
                result = result * 10 + (c - 48);
            }
        }
    }
    
    function updatePriceManualy(uint256 _ETHUSD) onlyOwner public {
        ETHUSD = _ETHUSD;
    }

    function transferFunds() public onlyOwner {
        owner.transfer(address(this).balance);
    }

    function updateMinimal(uint256 _minimalPrice) public onlyOwner {
        minimalPrice = _minimalPrice;
    }

    function transferTokens(uint256 _tokens) public onlyOwner {
        uint256 tokens = _tokens.mul(10 ** uint256(18));
        tokenReward.transfer(owner, tokens); 
    }
    
    function startPresale() public onlyOwner {
        loyaltyPart = false;
        startPresaleTime = block.timestamp;
    }

    function airdrop(address[] _array1, uint256[] _array2) public onlyOwner {
        address[] memory arrayAddress = _array1;
        uint256[] memory arrayAmount = _array2;
        uint256 arrayLength = arrayAddress.length.sub(1);
        uint256 i = 0;
       
        while (i <= arrayLength) {
            tokenReward.transfer(arrayAddress[i], arrayAmount[i]);
            i = i.add(1);
        }  
   }
   
   function addEther() onlyOwner public payable {
       
   }

}