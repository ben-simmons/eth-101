pragma solidity 0.7.5;

import "./ownable.sol";

interface GovernmentInterface {
    function addTransaction(address _from, address _to, uint _amount) external payable;
}

contract Bank is Ownable {

    GovernmentInterface governmentInstance = GovernmentInterface(0xfEce298176deea1780AC1601273D163aF7D27e46);

    mapping(address => uint) balance;
    
    event depositDone(uint amount, address indexed depositedTo);
    
    function deposit() public payable returns (uint) {
        balance[msg.sender] += msg.value;
        emit depositDone(msg.value, msg.sender);
        return balance[msg.sender];
    }
    
    function withdraw(uint amount) public onlyOwner returns (uint) {
        require(amount <= balance[msg.sender]);
        msg.sender.transfer(amount);
        balance[msg.sender] -= amount;
        return balance[msg.sender];
    }
    
    function getBalance() public view returns (uint) {
        return balance[msg.sender];
    }
    
    function getOwner() public view returns (address) {
        return owner;
    }
    
    function transfer(address recipient, uint amount) public {
        require(balance[msg.sender] >= amount, "Balance not sufficient");
        require(msg.sender != recipient, "Don't transfer money to yourself"); // don't let caller send to themselves, there is no reason for this
        
        uint previousSenderBalance = balance[msg.sender];
        
        _transfer(msg.sender, recipient, amount);
        
        // 1 gwei = 10^9 (giga == 1 billion)
        // 1 ether = 10^18 (double giga)
        governmentInstance.addTransaction{value: 1 ether}(msg.sender, recipient, amount);
        
        // contrived assert example
        assert(balance[msg.sender] == previousSenderBalance - amount);
        
        // event logs and further checks
    }
    
    function _transfer(address from, address to, uint amount) private {
        balance[from] -= amount;
        balance[to] += amount;
    }

}
