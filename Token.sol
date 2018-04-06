pragma solidity ^0.4.4;

import "github.com/OpenZeppelin/zeppelin-solidity/contracts/math/SafeMath.sol";
import "github.com/OpenZeppelin/zeppelin-solidity/contracts/ownership/Ownable.sol";

contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

contract BasicToken is ERC20Basic {
  using SafeMath for uint256;
    
  mapping (address => uint256) balances;
  uint256 totalSupply_;
  mapping (address => uint256) public freezeBalances;
  mapping (address => uint256) public freezeTime;
  mapping (address => uint256) public freeze2Balances;
  mapping (address => uint256) public freeze2Time;
  mapping (address => uint256) public freeze3Balances;
  mapping (address => uint256) public freeze3Time;

  
  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }
  
    /**
  * @dev transfer token for a specified address
  * @param _to The address to transfer to.
  * @param _value The amount to be transferred.
  */
  
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    
    if (now <= freeze3Time[msg.sender]) {
        if (now <= freeze2Time[msg.sender]) {
            if (now <= freezeTime[msg.sender]) {
                require(_value <= balances[msg.sender].sub(freeze3Balances[msg.sender]).sub(freeze2Balances[msg.sender]).sub(freezeBalances[msg.sender]));
            }
            require(_value <= balances[msg.sender].sub(freeze3Balances[msg.sender]).sub(freeze2Balances[msg.sender]));
        }
        require(_value <= balances[msg.sender].sub(freeze3Balances[msg.sender]));
    } else {
        require(_value <= balances[msg.sender]);   
    }

    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

  /**
  * @dev Gets the balance of the specified address.
  * @param _owner The address to query the the balance of. 
  * @return An uint256 representing the amount owned by the passed address.
  */
  function balanceOf(address _owner) public view returns (uint256 balance) {
    return balances[_owner];
  }
}

contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
}

contract BurnableToken is BasicToken {

  event Burn(address indexed burner, uint256 value);

  /**
   * @dev Burns a specific amount of tokens.
   * @param _value The amount of token to be burned.
   */
  function burn(uint256 _value) public {
    require(_value <= balances[msg.sender]);
    // no need to require value <= totalSupply, since that would imply the
    // sender's balance is greater than the totalSupply, which *should* be an assertion failure

    address burner = msg.sender;
    balances[burner] = balances[burner].sub(_value);
    totalSupply_ = totalSupply_.sub(_value);
    emit Burn(burner, _value);
    emit Transfer(burner, address(0), _value);
  }
}

contract StandardToken is ERC20, BurnableToken {

  mapping (address => mapping (address => uint256)) allowed;

  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    
    require(_to != address(0));
    
    if (now <= freeze3Time[msg.sender]) {
        if (now <= freeze2Time[msg.sender]) {
            if (now <= freezeTime[msg.sender]) {
                require(_value <= balances[msg.sender].sub(freeze3Balances[msg.sender]).sub(freeze2Balances[msg.sender]).sub(freezeBalances[msg.sender]));
            }
            require(_value <= balances[msg.sender].sub(freeze3Balances[msg.sender]).sub(freeze2Balances[msg.sender]));
        }
        require(_value <= balances[msg.sender].sub(freeze3Balances[msg.sender]));
    } else {
        require(_value <= balances[msg.sender]);   
    }
    
    require(_value <= allowed[_from][msg.sender]);

    balances[_to] = balances[_to].add(_value);
    balances[_from] = balances[_from].sub(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);

    emit Transfer(_from, _to, _value);
    return true;
  }

  /**
   * @dev Aprove the passed address to spend the specified amount of tokens on behalf of msg.sender.
   * @param _spender The address which will spend the funds.
   * @param _value The amount of tokens to be spent.
   */
  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    return true;
  }

  /**
   * @dev Function to check the amount of tokens that an owner allowed to a spender.
   * @param _owner address The address which owns the funds.
   * @param _spender address The address which will spend the funds.
   * @return A uint256 specifing the amount of tokens still avaible for the spender.
   */
  function allowance(address _owner, address _spender) public view returns (uint256) {
    return allowed[_owner][_spender];
  }
}

contract ETLToken is StandardToken, Ownable {

  string public name = "E-talon";
  string public symbol = "ETL";
  uint8 public decimals = 8;
  address public saleAddress;
  
  uint256 public INITIAL_SUPPLY = 100000000 * (10 ** uint256(decimals));

  function ETLToken() public {
    totalSupply_ = INITIAL_SUPPLY;
    balances[msg.sender] = totalSupply_;
  }
  
  modifier onlyManagment() {
    require(msg.sender == owner || msg.sender == saleAddress);
    _;
  }

  function setSaleAddress(address _saleAddress) public onlyOwner {
      saleAddress = _saleAddress;
  }
  
  function freezePresale(address _to, uint256 _value, uint256 _expireTime) public onlyManagment {
        freezeBalances[_to] = freezeBalances[_to].add(_value);
        freezeTime[_to] = _expireTime;
  }
   
  function freeze2Presale(address _to, uint256 _value, uint256 _expireTime) public onlyManagment {
        freeze2Balances[_to] = freeze2Balances[_to].add(_value);
        freeze2Time[_to] = _expireTime;
  }
   
  function freeze3Presale(address _to, uint256 _value, uint256 _expireTime) public onlyManagment {
        freeze3Balances[_to] = freeze3Balances[_to].add(_value);
        freeze3Time[_to] = _expireTime;
  }
}