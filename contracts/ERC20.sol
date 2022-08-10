pragma solidity 0.5.4;

contract NFTCoin{ 

string public Name;
string public Symbol;
uint8 public Decimal;
uint256 public TotalSupply;

//EVENT
event Transfer(address indexed _from, address indexed _to, uint256 _value);
event Approval(address indexed _owner, address indexed _spender, uint256 _value);

//MAPPING 
mapping (address => uint256) balances;
mapping (address => mapping(address => uint256)) allowed;

constructor(string memory _name, string memory _symbol, uint8 _decimal, uint256 _totalSupply ) public{
    Name = _name;
    Symbol = _symbol;
    Decimal = _decimal;
    TotalSupply = _totalSupply;
    balances[msg.sender] = TotalSupply;

}


function name() public view returns (string memory){
    return Name;
}

function symbol() public view returns (string memory){
    return Symbol;
}

function decimals() public view returns (uint8){
    return Decimal;
}

function totalSupply() public view returns (uint256){
    return TotalSupply;
}

function balanceOf(address _owner) public view returns (uint256 balance){
    return balances[_owner];
}

function transfer(address _to, uint256 _value) public returns (bool status){
    require(_value <= balances[msg.sender], "Insufficient Balance");
    require(_value != 0 && _to != address(0), "Invalid Input");
    balances[msg.sender] -= _value;
    balances[_to] += _value;
    emit Transfer(msg.sender, _to, _value);
    return true;
}

function transferFrom(address _from, address _to, uint256 _value) public returns (bool status){
    require(_value <= balances[_from], "Insufficient Balance");
    require(_value <= allowed[_from][msg.sender]);
    allowed[_from][msg.sender] -= _value;
    balances[_from] -= _value;
    balances[_to] += _value;
    emit Transfer(msg.sender, _to, _value);
    return true;
}

function approve(address _spender, uint256 _value) public returns (bool status){
    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
}

function allowance(address _owner, address _spender) public view returns (uint256 remaining){
    return allowed[_owner][_spender];
}
}