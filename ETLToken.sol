pragma solidity ^0.4.11;

import "./ERC20Standard.sol";

contract ETLToken is ERC20Standard {
	function ETLToken() {
		totalSupply = 100000000;
		name = "E-talon";
		decimals = 6;
		symbol = "ETL";
		version = "1.0";
		balances[msg.sender] = totalSupply;
	}
}