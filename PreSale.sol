pragma solidity ^0.4.18;

import "github.com/oraclize/ethereum-api/oraclizeAPI.sol";
import "github.com/OpenZeppelin/zeppelin-solidity/contracts/math/SafeMath.sol";
import "github.com/OpenZeppelin/zeppelin-solidity/contracts/ownership/Ownable.sol";
import "github.com/OpenZeppelin/zeppelin-solidity/contracts/lifecycle/Pausable.sol";

interface ETLToken {
    function transfer(address receiver, uint amount);
}

contract ETLTokenPresale is Pausable, usingOraclize {
    using SafeMath for uint256;

    ETLToken public tokenReward;

    mapping (address => uint256) freezeBalances;
    mapping (address => uint256) freezeTime;

    uint256 public minimalPrice = 10000000000000; // 0.00001
    uint256 public tokensRaised;
    uint256 public ETHUSD;
    uint256 public startPresaleTime;
    uint256 public secPerBlock = 14;

    uint256 constant public expiredTime = 1546300800;
    uint256 constant public twoWeeks = 1209600; // 2 weeks = 60*60*24*14 = 1209600 => 1209600
    uint256 constant public tenZero = 10000000000;
    uint256 constant public loyaltyCap = 200000000000000; // 2mln
    uint256 constant public presaleCap = 400000000000000; // 4mln

    bool public presaleFinished = false;
    bool public loyaltyPart = true;
    bool public oraclizeOn = false;
    
    event LogPriceUpdated(string price);
    event LogNewOraclizeQuery(string description);

    modifier whenOraclizeOff() {
        require(!oraclizeOn);
        _;
    }

    modifier whenOraclizeOn() {
        require(oraclizeOn);
        _;
    }
    
    modifier whenNotFinished() {
        require(!presaleFinished);
        _;
    }

    function ETLTokenPresale(address _tokenReward) public {
        tokenReward = ETLToken(_tokenReward);
    }

    function getBonus() public view returns (uint256) {
        if (loyaltyPart) return 5;
        else if (!loyaltyPart && block.number <= startPresaleTime.add(twoWeeks.div(secPerBlock))) return 5;
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
                startPresaleTime = block.number;
            }
            
            tokens = msg.value.mul(ETHUSD).div(getPrice()).mul(10).div(tenZero);
            tokensRaised = tokensRaised.add(tokens);
            
        } else {
            
            tokens = msg.value.mul(ETHUSD).div(getPrice()).mul(10).div(tenZero);
            uint256 bonusTokens = tokens.mul(getBonus()).div(10);
            freezeBalances[msg.sender] = freezeBalances[msg.sender].add(bonusTokens);
            freezeTime[msg.sender] = expiredTime;
            tokensRaised = tokensRaised.add(tokens).add(bonusTokens);
            
            if (tokensRaised >= presaleCap) {
                presaleFinished = true;
            }
        }
        
        tokenReward.transfer(buyer, tokens);
        owner.transfer(msg.value);
    }

    function __callback(bytes32 myid, string result) whenOraclizeOn {
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

    function updatePrice() onlyOwner whenOraclizeOn payable {
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
        for (i = 0; i < b.length; i = i.add(1)) {
            uint c = uint(b[i]);
            if (c == 46) {
                break;
            }
            if (c >= 48 && c <= 57) {
                result = result.mul(10).add(c.sub(48));
                require(result != 0);
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

    function turnOnOraclize() whenOraclizeOff public onlyOwner {
        oraclizeOn = true;
    }

    function turnOffOraclize() whenOraclizeOn public onlyOwner {
        oraclizeOn = false;
    }

    function updateSecPerBlock(uint256 _secPerBlock) public onlyOwner {
        secPerBlock = _secPerBlock;
    }

    function startPresale() public onlyOwner {
        loyaltyPart = false;
        startPresaleTime = block.number;
    }

    function transferTokens(uint256 _tokens) public onlyOwner {
        uint256 tokens = _tokens.mul(100000000); // decimals = 8
        tokenReward.transfer(owner, tokens); 
    }

    function airdrop(address[] _array1, uint256[] _array2) public onlyOwner {
        require(_array1.length <= 15);
        address[] memory arrayAddress = _array1;
        uint256[] memory arrayAmount = _array2;
        uint256 arrayLength = arrayAddress.length.sub(1);
        uint256 i = 0;
       
        while (i <= arrayLength) {
            tokenReward.transfer(arrayAddress[i], arrayAmount[i]);
            i = i.add(1);
        }  
   }

    function freezeTimeOf(address _investor) public view returns (uint256 balance) {
        return freezeTime[_investor];
    }

    function freezeBalancesOf(address _investor) public view returns (uint256 balance) {
        return freezeBalances[_investor];
    }
   
    function addEther() onlyOwner public payable {
       
    }

}