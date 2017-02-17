pragma solidity ^0.4.4;

contract CCCoinToken {
    
    //**** Constant token-specific fields:
    
    string public constant name = "CCCoin";
    string public constant symbol = "CCC";
    uint public constant decimals = 18;
    uint public constant MAX_CREATION_RATE_PER_SECOND = 1; 
    
    //*** Fields set in constructor:
    
    address public cccoin_address; // Contract owner
    address public minter_address; // Has permission to mint
    uint public start_time;        // Start time in seconds
    uint public tok_per_lock_rate; // Exchange rate between tok and lock
    
    //**** ERC20 TOK fields and events:

    uint public totalSupply;
    mapping(address => uint) balances;
    mapping (address => mapping (address => uint)) allowed;
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
    
    //**** LOCK fields and events:
        
    mapping (address => uint) balances_lock;    
    uint public totalSupplyLock;
    event LockupTokEvent(address recipient, uint amount_tok, uint end_tok, uint end_lock);    
    
    //**** Modifiers:

    modifier only_cccoin {
        assert(msg.sender == cccoin_address);
        _;
    }
    
    modifier only_minter {
        assert(msg.sender == minter_address);
        _;
    }
    
    modifier max_rate_not_reached(uint x) {
        assert((totalSupply / (now - x)) < MAX_CREATION_RATE_PER_SECOND);
        _;
    }

    //**** LOCK constant methods:

    function lockedBalanceOf(address _owner) constant returns (uint balance) {
        return balances_lock[_owner];
    }
    
    //**** Constructor:
    
    function CCCoinToken(address setMinter, address set_cccoin, uint set_start_time) {
        minter_address = setMinter;
        cccoin_address = set_cccoin;
        start_time = set_start_time;
    }
    
    //**** Master log for most user dApp actions:
    
    event TheLog(bytes);
    
    function addLog(bytes val) { 
        TheLog(val);
    }

    //**** Functions only minter can call:
    
    /// Mint TOK:
    function mintToken(address recipient, uint amount)
    external
    only_minter
    max_rate_not_reached(start_time)
    {
        balances[recipient] = safeAdd(balances[recipient], amount);
        totalSupply = safeAdd(totalSupply, amount);
    }
    
    // Mint LOCK, e.g. for certain types of mining rewards:
    function mintLockToken(address recipient, uint amount)
    external
    only_minter
    max_rate_not_reached(start_time)
    {
        balances_lock[recipient] = safeAdd(balances_lock[recipient], amount);
        totalSupplyLock = safeAdd(totalSupply, amount);
    }
    
    // Cashout LOCK to TOK at current tok_per_lock exchange rate. Only minter can do this, to limit withdrawl rate:
    function mintLockCashout(address recipient, uint amount_lock)
    external
    only_minter
    {
	assert(amount_lock <= balances_lock[recipient]);
        balances[recipient] = safeAdd(balances[recipient], safeMul(balances_lock[recipient], tok_per_lock_rate));
        balances_lock[recipient] = safeSub(balances_lock[recipient], amount_lock);
    }
    
    // Update conversion rate:
    function updateTokPerLockRate(uint rate)
    external
    only_minter
    {
        tok_per_lock_rate = rate;
    }
    
    //**** ERC20 functions that regular users can call:
    
    // Lockup TOK to LOCK at current tok_per_lock exchange rate. Users can do this themselves:
    function lockupTok(address recipient, uint amount_tok)
    external
    {
	assert(amount_tok <= balances[recipient]);
        balances_lock[recipient] = safeAdd(balances[recipient], safeDiv(balances_lock[recipient], tok_per_lock_rate));
        balances[recipient] = safeSub(balances[recipient], amount_tok);
	LockupTokEvent(recipient, amount_tok, balances[recipient], balances_lock[recipient]);
    }
    
    function transfer(address _to, uint _value) returns (bool success) {
	balances[msg.sender] = safeSub(balances[msg.sender], _value);
	balances[_to] = safeAdd(balances[_to], _value);
	Transfer(msg.sender, _to, _value);
	return true;
    }

    function transferFrom(address _from, address _to, uint _value) returns (bool success) {
	var _allowance = allowed[_from][msg.sender];
	
	balances[_to] = safeAdd(balances[_to], _value);
	balances[_from] = safeSub(balances[_from], _value);
	allowed[_from][msg.sender] = safeSub(_allowance, _value);
	Transfer(_from, _to, _value);
	return true;
    }

    function balanceOf(address _owner) constant returns (uint balance) {
	return balances[_owner];
    }

    function approve(address _spender, uint _value) returns (bool success) {
	allowed[msg.sender][_spender] = _value;
	Approval(msg.sender, _spender, _value);
	return true;
    }

    function allowance(address _owner, address _spender) constant returns (uint remaining) {
	return allowed[_owner][_spender];
    }


    //**** Update contract parameters:
    
    function changeCCCoinAddress(address newAddress) only_cccoin { cccoin_address = newAddress; }

    function changeMintingAddress(address newAddress) only_cccoin { minter_address = newAddress; }
    
    //**** SafeMath:

    function safeMul(uint a, uint b) internal returns (uint) {
	uint c = a * b;
	assert(a == 0 || c / a == b);
	return c;
    }

    function safeDiv(uint a, uint b) internal returns (uint) {
	assert(b > 0);
	uint c = a / b;
	assert(a == b * c + a % b);
	return c;
    }

    function safeSub(uint a, uint b) internal returns (uint) {
	assert(b <= a);
	return a - b;
    }

    function safeAdd(uint a, uint b) internal returns (uint) {
	uint c = a + b;
	assert(c>=a && c>=b);
	return c;
    }

    function max64(uint64 a, uint64 b) internal constant returns (uint64) {
	return a >= b ? a : b;
    }

    function min64(uint64 a, uint64 b) internal constant returns (uint64) {
	return a < b ? a : b;
    }

    function max256(uint256 a, uint256 b) internal constant returns (uint256) {
	return a >= b ? a : b;
    }

    function min256(uint256 a, uint256 b) internal constant returns (uint256) {
	return a < b ? a : b;
    }

    function assert(bool assertion) internal {
	if (!assertion) throw;
    }
    
 }
