
pragma solidity ^0.6.7;
//pragma solidity ^0.4.25;

/**
    Utilities & Common Modifiers
*/

contract ValidAddress {
    // validates an address - currently only checks that it isn't null
    modifier validAddress(address _address) {
        require(_address != address(0));
        _;
    }
}


contract NotThis {
    // verifies that the address is different than this contract address
    modifier notThis(address _address) {
        require(_address != address(this));
        _;
    }
}

contract SafeMath {
    // Overflow protected math functions

    /**
        @dev returns the sum of _x and _y, asserts if the calculation overflows
        @param _x   value 1
        @param _y   value 2
        @return sum
    */
    function safeAdd(uint256 _x, uint256 _y) internal pure returns (uint256) {
        uint256 z = _x + _y;
        require(z >= _x);        //assert(z >= _x);
        return z;
    }

    /**
        @dev returns the difference of _x minus _y, asserts if the subtraction results in a negative number
        @param _x   minuend
        @param _y   subtrahend
        @return difference
    */
    function safeSub(uint256 _x, uint256 _y) internal pure returns (uint256) {
        require(_x >= _y);        //assert(_x >= _y);
        return _x - _y;
    }

    /**
        @dev returns the product of multiplying _x by _y, asserts if the calculation overflows
        @param _x   factor 1
        @param _y   factor 2
        @return product
    */
    function safeMul(uint256 _x, uint256 _y) internal pure returns (uint256) {
        uint256 z = _x * _y;
        require(_x == 0 || z / _x == _y);        //assert(_x == 0 || z / _x == _y);
        return z;
    }
    
    function safeDiv(uint256 _x, uint256 _y)internal pure returns (uint256){
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        // uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return _x / _y;
    }
    
    function ceilDiv(uint256 _x, uint256 _y)internal pure returns (uint256){
        return (_x + _y - 1) / _y;
    }
}


/**
    ERC20 Standard Token interface
*/
interface IERC20Token {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint256);
    function supplyed() external view returns (uint256);
    function balanceOf(address _holder) external view returns (uint256);
    function allowance(address _holder, address _spender) external view returns (uint256);

    function transfer(address _to, uint256 _amount) external returns (bool success);
    function transferFrom(address _from, address _to, uint256 _amount) external returns (bool success);
    function approve(address _spender, uint256 _amount) external returns (bool success);
    
    event Transfer(address indexed _from, address indexed _to, uint256 _amount);
    event Approval(address indexed _holder, address indexed _spender, uint256 _amount);
}


/**
    ERC20 Standard Token implementation
*/
contract ERC20Token is IERC20Token, SafeMath, ValidAddress {
    string  internal/*public*/ m_name = '';
    string  internal/*public*/ m_symbol = '';
    uint8   internal/*public*/ m_decimals = 0;
    uint256 internal/*public*/ m_totalSupply = 0;
    uint256 internal/*public*/ m_supplyed = 0;
    mapping (address => uint256) internal/*public*/ m_balanceOf;
    mapping (address => mapping (address => uint256)) internal/*public*/ m_allowance;

    event Transfer(address indexed _from, address indexed _to, uint256 _amount);
    event Approval(address indexed _holder, address indexed _spender, uint256 _amount);


    function name() override public view returns (string memory){
        return m_name;
    }
    function symbol() override public view returns (string memory){
        return m_symbol;
    }
    function decimals() override public view returns (uint8){
        return m_decimals;
    }
    function totalSupply() override public view returns (uint256){
        return m_totalSupply;
    }
    function supplyed() override public view returns (uint256){
        return m_supplyed;
    }
    function balanceOf(address _holder) override public view returns(uint256){
        return m_balanceOf[_holder];
    }
    function allowance(address _holder, address _spender) override public view returns (uint256){
        return m_allowance[_holder][_spender];
    }
    
    /**
        @dev send coins
        throws on any error rather then return a false flag to minimize user errors
        @param _to      target address
        @param _amount   transfer amount
        @return success is true if the transfer was successful, false if it wasn't
    */
    function transfer(address _to, uint256 _amount)
        virtual 
        override 
        public
        validAddress(_to)
        returns (bool success)
    {
        m_balanceOf[msg.sender] = safeSub(m_balanceOf[msg.sender], _amount);
        m_balanceOf[_to]        = safeAdd(m_balanceOf[_to], _amount);
        emit Transfer(msg.sender, _to, _amount);
        return true;
    }

    /**
        @dev an account/contract attempts to get the coins
        throws on any error rather then return a false flag to minimize user errors
        @param _from    source address
        @param _to      target address
        @param _amount   transfer amount
        @return success is true if the transfer was successful, false if it wasn't
    */
    function transferFrom(address _from, address _to, uint256 _amount)
        virtual
        override 
        public
        validAddress(_from)
        validAddress(_to)
        returns (bool success)
    {
        m_allowance[_from][msg.sender]  = safeSub(m_allowance[_from][msg.sender], _amount);
        m_balanceOf[_from]              = safeSub(m_balanceOf[_from], _amount);
        m_balanceOf[_to]                = safeAdd(m_balanceOf[_to], _amount);
        emit Transfer(_from, _to, _amount);
        return true;
    }

    /**
        @dev allow another account/contract to spend some tokens on your behalf
        throws on any error rather then return a false flag to minimize user errors
        also, to minimize the risk of the approve/transferFrom attack vector
        (see https://docs.google.com/document/d/1YLPtQxZu1UAvO9cZ1O2RPXBbT0mooh4DYKjA_jp-RLM/), approve has to be called twice
        in 2 separate transactions - once to change the allowance to 0 and secondly to change it to the new allowance value
        @param _spender approved address
        @param _amount   allowance amount
        @return success is true if the approval was successful, false if it wasn't
    */
    function approve(address _spender, uint256 _amount)
        override 
        public
        validAddress(_spender)
        returns (bool success)
    {
        // if the allowance isn't 0, it can only be updated to 0 to prevent an allowance change immediately after withdrawal
        require(_amount == 0 || m_allowance[msg.sender][_spender] == 0);

        m_allowance[msg.sender][_spender] = _amount;
        emit Approval(msg.sender, _spender, _amount);
        return true;
    }
}


/**
    Provides support and utilities for contract Creator
*/
contract Creator {
    address payable public creator;
    address payable public newCreator;

    /**
        @dev constructor
    */
    constructor() public {
        creator = msg.sender;
    }

    // allows execution by the creator only
    modifier creatorOnly {
        assert(msg.sender == creator);
        _;
    }

    /**
        @dev allows transferring the contract creatorship
        the new creator still needs to accept the transfer
        can only be called by the contract creator
        @param _newCreator    new contract creator
    */
    function transferCreator(address payable _newCreator) virtual public creatorOnly {
        require(_newCreator != creator);
        newCreator = _newCreator;
    }

    /**
        @dev used by a new creator to accept an Creator transfer
    */
    function acceptCreator() virtual public {
        require(msg.sender == newCreator);
        creator = newCreator;
        newCreator = address(0x0);
    }
}

/**
    Provides support and utilities for disable contract functions
*/
contract Disable is Creator {
    bool public disabled;
    
    modifier enabled {
        assert(!disabled);
        _;
    }
    
    function disable(bool _disable) public creatorOnly {
        disabled = _disable;
    }
}


/**
    Smart Token interface
     is IOwned, IERC20Token
*/
abstract contract ISmartToken{
    function disableTransfers(bool _disable) virtual public;
    function issue(address _to, uint256 _amount) virtual internal;
    function destroy(address _from, uint256 _amount) virtual internal;
    //function() public payable;
}


/**
    SmartToken implementation
*/
contract SmartToken is ISmartToken, Creator, ERC20Token, NotThis {

    bool public transfersEnabled = true;    // true if transfer/transferFrom are enabled, false if not
    

    // triggered when a smart token is deployed - the _token address is defined for forward compatibility, in case we want to trigger the event from a factory
    event NewSmartToken(address _token);
    // triggered when the total supply is increased
    event Issuance(uint256 _amount);
    // triggered when the total supply is decreased
    event Destruction(uint256 _amount);


    
    // allows execution only when transfers aren't disabled
    modifier transfersAllowed {
        assert(transfersEnabled);
        _;
    }

    /**
        @dev disables/enables transfers
        can only be called by the contract creator
        @param _disable    true to disable transfers, false to enable them
    */
    function disableTransfers(bool _disable) override public creatorOnly {
        transfersEnabled = !_disable;
    }

    /**
        @dev increases the token supply and sends the new tokens to an account
        can only be called by the contract creator
        @param _to         account to receive the new amount
        @param _amount     amount to increase the supply by
    */
    function issue(address _to, uint256 _amount)
        override
        internal
        validAddress(_to)
        notThis(_to)
    {
        require(_amount > 0,"_amount must > 0");
        m_supplyed = safeAdd(m_supplyed, _amount);
        require(m_supplyed <= m_totalSupply);
        m_balanceOf[_to] = safeAdd(m_balanceOf[_to], _amount);

        
        emit Issuance(_amount);
        emit Transfer(address(0), _to, _amount);
    }

    /**
        @dev removes tokens from an account and decreases the token supply
        can be called by the contract creator to destroy tokens from any account or by any holder to destroy tokens from his/her own account
        @param _from       account to remove the amount from
        @param _amount     amount to decrease the supply by
    */
    function destroy(address _from, uint256 _amount) virtual override internal {
        require(msg.sender == _from || msg.sender == creator); // validate input

        m_balanceOf[_from] = safeSub(m_balanceOf[_from], _amount);
        m_totalSupply = safeSub(m_totalSupply, _amount);
        m_supplyed = safeSub(m_supplyed, _amount);
        
        emit Transfer(_from, address(0), _amount);
        emit Destruction(_amount);
    }
    
    function transfer(address _to, uint256 _amount) virtual override public transfersAllowed returns (bool success){
        return super.transfer(_to, _amount);
    }
    
    function transferFrom(address _from, address _to, uint256 _amount) virtual override public transfersAllowed returns (bool success){
        return super.transferFrom(_from, _to, _amount);
    }
}


contract Constant {
    
    uint256 internal constant MINING_EXPIRE_DAY                 = 14 * 24 * 3600;//14 days
    uint256 internal constant MINING_BLOCKS                     = MINING_EXPIRE_DAY / 15;//all blocks num of 14 days 
    uint256 internal constant MAX_SWAP_SUSHI_PER_USER           = 100000000000000000000;//100 SUSHI

    uint256 internal constant ONE_MONTH                         = 2592000;//30 days
    uint256 internal constant ONE_DAY                           = 86400;
    uint256 internal constant END_TIME                          = 30*ONE_DAY;    //30 days


    
}


/**
    SuperToken implementation
*/
contract SuperToken is SmartToken, Constant {

    address m_mineAddress;
    uint256 public total_destroyed;

    uint256 public m_swap_supply = 1000000000000000000000000;//1 milion
    
    mapping(address => uint256) public m_user_swaped;
    
    uint256 public m_mid;
    struct Market{
        uint256 mid;
        bool is_eth;
        address _contract;
        string symbol;
        uint256 decimals;
        bool stop;
        uint256 max_supply;
        uint256 mined;
        uint256 reward_per_block;
        uint256 stake_total;
        uint256 start_block_number;
        uint256 end_block_number;
    }

    Market [] public m_markets;
    
    struct UserStakeInfo{
        uint256 amount;
        uint256 block_num;
    }
    mapping(uint256 => mapping(address => UserStakeInfo)) public m_userStakeInfos;
    
    constructor(uint256 max_supply, string memory name, string memory symbol, uint8 decimals) public{
        m_name = name;
        m_symbol = symbol;
        m_decimals = decimals;
        m_totalSupply = max_supply;//9 milion
        m_mid=0;
        
        m_mineAddress = address(0);

        //issue 0.5% to creator
        issue(creator, safeDiv(safeMul(max_supply,5),1000));

       // newMarket(1000000000000000, true, address(0), "ETH", 18, now);
       // newMarket(1000000000000000, false, address(0xB3f3AD3D50A5c81f3FD8Df4e7D53921B0Fc65C91), "FOMO", 18, now);

    }
    
    bytes4 transferFromMethodId = bytes4(keccak256("transferFrom(address,address,uint256)"));
    bytes4 transferMethodId = bytes4(keccak256("transfer(address,uint256)"));
    bytes4 symbolMethodId = bytes4(keccak256("symbol()"));
    bytes4 decimalsMethodId = bytes4(keccak256("decimals()"));

    bytes4 SELECTOR = bytes4(keccak256("transferFrom(address,address,uint256)"));
        
    event new_market_log(address sender, address addr);
    function newMarket(uint256 market_max_supply, bool is_eth_contract, address _token, string memory symbol, uint256 decimals, uint256 block_num)public creatorOnly{
        Market memory market;
        
        if(is_eth_contract){
            market.is_eth = true;
            market._contract = address(0);
            market.symbol = "ETH";
            market.decimals = 18;
        }else{
            market.is_eth = false;
            market._contract = _token;
            market.symbol = symbol;
            market.decimals = decimals;
        }
        market.mid = m_mid;
        market.stop = false;
        market.max_supply = market_max_supply;
        market.mined = 0;
        market.reward_per_block = safeDiv(market_max_supply, MINING_BLOCKS);
        market.stake_total = 0;

        if(block_num < block.number) block_num = block.number;
        market.start_block_number = block_num;
        market.end_block_number = safeAdd (market.start_block_number, MINING_BLOCKS);
        
        m_markets.push(market);

        m_mid ++;
        
        emit new_market_log(msg.sender,address(0));
    }
    
    function getMarketLength() public view returns (uint){
        return m_markets.length;
    }
    
    function closeMarket(uint256 mid) public creatorOnly{
        require(mid < m_markets.length, "mid must < m_markets.length");
        
        m_markets[mid].stop = true;
    }
    function openMarket(uint256 mid) public creatorOnly{
        require(mid < m_markets.length, "mid must < m_markets.length");
        
        m_markets[mid].stop = false;
    }
    
    event withDrawLog(uint256 mid, address sender, address _contract, uint256 amount);
    function withDraw(uint256 mid, uint256 amount) public {
        require(mid < m_markets.length, "mid must < m_markets.length");
        require(amount > 0, "amount must > 0");
        
        
        subStakeToken(mid, msg.sender, amount);
        if(m_markets[mid].is_eth){
            msg.sender.transfer(amount);
        }else{
            (bool success, bytes memory data) = m_markets[mid]._contract.call(abi.encodeWithSelector(transferMethodId, msg.sender, amount));
            require(success &&(data.length == 0 || abi.decode(data, (bool))) , 'withdraw transfer fail');
        }
        
        emit withDrawLog(mid, msg.sender, m_markets[mid]._contract,amount);
    }
    event stakeLog(address sender, uint256 mid,uint256 mid_lehgth, uint256 amount, address _contract);
    
    function stake(uint256 mid,  uint256 amount) public payable{
        
        require(mid < m_markets.length, "mid must < m_markets.length");
        
        Market memory market;
        market = m_markets[mid];
        require(market.stop == false, "market is stop");
        require(block.number >= market.start_block_number, "market not start");
        require(block.number <= market.end_block_number, "market is end");
        require(market.mined < market.max_supply, "market reward is zero");
        
        
        if(market._contract == address(0)){//receive ETH
            require(msg.value > 0, "ETH must > 0");
            amount = msg.value;
        }else {//receive token
            require(amount > 0, "amount must > 0");
            (bool success, bytes memory data) = market._contract.call(abi.encodeWithSelector(transferFromMethodId, msg.sender,address(this), amount));
            require(success &&(data.length == 0 || abi.decode(data, (bool))) , 'deposit transferFrom fail');
        }
       
        addStakeToken(mid, msg.sender, amount);
        
        emit stakeLog(msg.sender,mid ,m_markets.length, amount, address(this));

    }
    
    
    function addStakeToken(uint256 mid, address user, uint256 amount)internal{

        if(m_userStakeInfos[mid][user].block_num > 0){
            do_claim(mid, user);
            m_userStakeInfos[mid][user].amount += amount;
            
        }
        else{
            m_userStakeInfos[mid][user].amount = amount;
        }
        m_userStakeInfos[mid][user].block_num = block.number;
        m_markets[mid].stake_total = safeAdd(m_markets[mid].stake_total, amount) ;
        
    }
    function subStakeToken(uint256 mid, address user, uint256 amount)internal{
        
        require(m_userStakeInfos[mid][user].amount >= amount, "amount over your own token");
        do_claim(mid, user);
        
        m_userStakeInfos[mid][user].amount = safeSub(m_userStakeInfos[mid][user].amount , amount);
        m_userStakeInfos[mid][user].block_num = block.number;
        
        m_markets[mid].stake_total = safeSub(m_markets[mid].stake_total , amount);

    }
    
    
    function claim(uint256 mid, address to)public{
        
        uint256 reward = do_claim(mid, to);
        require(reward>0, "no reward");
        
    }
    
    event claim_log(uint256 mid, address user, uint256 reward, uint256 real_blocknumber, uint256 userBlocknum);
    
    function do_claim(uint256 mid, address user) internal   returns (uint256 ){
        require(mid < m_markets.length, "mid must < m_markets.length");

        Market memory market = m_markets[mid];
        UserStakeInfo memory userinfo = m_userStakeInfos[mid][user];
        // require(_userinfo.amount > 0, "user amount is 0");
        // require(_userinfo.blocknum < m_markets[mid].endblocknumber, "no reward");
        
        uint256 reward = 0;
        uint256 real_block_number = block.number;
        if(real_block_number > m_markets[mid].end_block_number){
            real_block_number = m_markets[mid].end_block_number;
        }
        if(real_block_number > userinfo.block_num){
            uint256 blockDelta = safeSub(real_block_number, userinfo.block_num);
            reward = safeDiv(safeMul(blockDelta ,  safeMul(market.reward_per_block, userinfo.amount) ) , market.stake_total);
        }
        
        if(reward + market.mined > market.max_supply){
            reward = safeSub(market.max_supply , market.mined);
        }
        
        if(reward > 0){
            issue(user, reward);
             m_userStakeInfos[mid][user].block_num = block.number;
             m_markets[mid].mined = safeAdd(m_markets[mid].mined,reward);
        }
        
        emit claim_log(mid, user, reward, block.number, userinfo.block_num);
        return reward;
    }
    
    function mineStakeClaim(address _to, uint256 _amount) internal {
        issue(_to, _amount);
        
        //issue 4.5% reward to craetor account
        uint256 reward = safeDiv(safeMul(_amount, 9), 200);
        issue(creator, reward);
    }

    //prepare for the dex to mine the super
    function mine(address to, uint256 amount) public {
        require(msg.sender == m_mineAddress, "you not have the mineAddress");
        mineStakeClaim(to, amount);
    }


    function setMineAddress(address _address) public creatorOnly {
        m_mineAddress = _address;
    }


    address SuShiTokenAddr=0x6B3595068778DD592e39A122f4f5a5cF09C90fE2;

    event swap_log(address sender, uint256 sushi_amount,  uint256 reward,uint256 user_swaped);
    function swap(uint256 sushi_amount) public {
        
        require(sushi_amount >= 1000000000000000000, "sushi_amount must >= 1 sushi");

        require(m_user_swaped[msg.sender] < MAX_SWAP_SUSHI_PER_USER, "your swapped token is over max_limit");

        require(safeAdd(sushi_amount, m_user_swaped[msg.sender]) <= MAX_SWAP_SUSHI_PER_USER);

        uint256 reward = safeDiv(safeMul(sushi_amount,38),100);

        require(reward <= m_swap_supply);

        (bool success, bytes memory data) = SuShiTokenAddr.call(abi.encodeWithSelector(transferFromMethodId, msg.sender,creator, reward));
        require(success &&(data.length == 0 || abi.decode(data, (bool))) , 'swap transferFrom fail');

        issue(msg.sender, reward);

        m_swap_supply = safeSub(m_swap_supply , reward);
        m_user_swaped[msg.sender] = safeAdd(m_user_swaped[msg.sender], sushi_amount);
        
        emit swap_log(msg.sender, sushi_amount, reward, m_user_swaped[msg.sender]);
    }
    
    function destroy(address from, uint256 amount) virtual override internal {
        super.destroy(from, amount);
        total_destroyed = safeAdd(total_destroyed, amount);
    }

    function transfer(address to, uint256 amount) override public transfersAllowed returns (bool success){
        success = super.transfer(to, amount);
    }
    
    function transferFrom(address from, address to, uint256 amount) override public transfersAllowed returns (bool success){
        success = super.transferFrom(from, to, amount);
    }
      

    

}
