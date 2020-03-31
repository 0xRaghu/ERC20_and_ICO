pragma solidity ^0.5.6;

// ----------------------------------------------------------------------------
// ERC Token Standard #20 Interface
// https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20.md
// ----------------------------------------------------------------------------
contract ERC20Interface {
    function totalSupply() public view returns (uint);
    function balanceOf(address tokenOwner) public view returns (uint balance);
    function allowance(address tokenOwner, address spender) public view returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}
contract CryptosToken is ERC20Interface{
    string public name="Cryptos";
    string public symbol="CRPT";
    uint public decimals=0;
    
    uint public supply;
    address public founder;
    
    mapping(address=>uint) public balances;
    mapping(address=>mapping(address=>uint)) allowed;
    
    event Transfer(address indexed from, address indexed to, uint tokens); 
    
    constructor() public {
        supply=1000000;
        founder=msg.sender;
        balances[founder]=supply;
    }
    
    function allowance(address tokenOwner, address spender) public view returns (uint remaining){
        return allowed[tokenOwner][spender];
    } 
    
    function approve(address spender, uint tokens) public returns (bool success){
        require(balances[msg.sender] >= tokens);
        require(tokens > 0);
        allowed[msg.sender][spender]=tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }
    
    function transferFrom(address from, address to, uint tokens) public returns (bool success){
        require(allowed[from][to] > tokens);
        require(balances[from] >= tokens);
        balances[from]-=tokens;
        balances[to]+=tokens;
        allowed[from][to]-=tokens;
        return true;
    }
    
    function totalSupply() public view returns (uint){
        return supply;
    }
    
    function balanceOf(address tokenOwner) public view returns (uint balance){
        return balances[tokenOwner];
    }
    
    function transfer(address to, uint tokens) public returns (bool success){
        require(balances[msg.sender] >= tokens);
        require(tokens > 0);
        balances[to]+=tokens;
        balances[msg.sender]-=tokens;
        emit Transfer(msg.sender,to,tokens);
        return true;
        
    }
}

contract CryptosICO is CryptosToken{
    address public admin;
    address payable public deposit;
    uint public tokenPrice=0.001 ether;
    uint public hardCap=300 ether;
    uint public raisedAmount;
    uint public saleStart=now;
    uint public saleEnd=now+604800;
    uint public coinTradeStart=saleEnd+604800;
    uint public maxInvestment=5 ether;
    uint public minInvestment=0.01 ether;
    
    enum State{beforeStart,Running,afterEnd,Halted}
    State public icoState;
    
    modifier onlyAdmin{
        require(msg.sender==admin);
        _;
    }
    
    event Invest( address investor,uint value,uint tokens);
    
    constructor(address payable _deposit) public {
        deposit=_deposit;
        admin=msg.sender;
        icoState=State.beforeStart;
    }
    
    function halt() public onlyAdmin{
        icoState=State.Halted;
    }
    
    function unhalt() public onlyAdmin{
        icoState=State.Running;
    }
    
    function changeDepositAddress(address payable _deposit) public onlyAdmin{
        deposit=_deposit;
    }
    
    function getCurrentState() public view returns(State){
        if(icoState==State.Halted){
            return State.Halted;
        }
        else if(block.timestamp < saleStart){
            return State.beforeStart;
        }else if(block.timestamp >= saleStart && block.timestamp <= saleEnd){
            return State.Running;
        }else {
            return State.afterEnd;
        }
    }
    
    function invest() payable public returns(bool){
        icoState=getCurrentState();
        require(icoState==State.Running);
        require(msg.value >= minInvestment && msg.value<=maxInvestment);
        uint tokens=msg.value/tokenPrice;
        require(raisedAmount+msg.value<=hardCap);
        raisedAmount+=msg.value;
        balances[msg.sender]+=tokens;
        balances[founder]-=tokens;
        deposit.transfer(msg.value);
        emit Invest(msg.sender,msg.value,tokens);
        return true;
    }
    
    function () external payable {
        invest();
    }
    
    function transfer(address to, uint tokens) public returns (bool){
        require(now > coinTradeStart);
        super.transfer(to,tokens);
    }
    
    function transferFrom(address from, address to, uint tokens) public returns (bool){
        require(now > coinTradeStart);
        super.transferFrom(from,to,tokens);
    }
    
    function burn() public returns(bool){
        icoState=getCurrentState();
        require(icoState==State.afterEnd);
        balances[founder]=0;
    }
}