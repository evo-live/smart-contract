pragma solidity ^0.4.11;

import "./ERC20Standard.sol";

contract NewToken is ERC20Standard {
	function NewToken() {
		totalSupply = 100000000;
		name = "EVO.LIVE main token";
		decimals = 6;
		symbol = "ETL";
		version = "1.0";
		balances[msg.sender] = totalSupply;
	}
}