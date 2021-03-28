pragma solidity 0.7.5;
pragma abicoder v2;

contract Wallet {
    address[] public owners;
    uint limit;
    // mapping(address => uint) balance;
    uint balance;
    
    struct Transfer {
        address recipient;
        uint amount;
        uint numApprovals;
        bool completed;
    }
    
    Transfer[] transferRequests;
    
    // map approver to transferRequest (index in array)
    // double mapping of approver to transfer ID to approval status
    mapping(address => mapping(uint => bool)) approvals;
    // mapping[address][transferID] => true/false
    
    constructor() {
        owners = [0x5B38Da6a701c568545dCfcB03FcB875f56beddC4, 0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2, 0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db];
        limit = 2;
    }
    
    modifier onlyOwner {
        // TODO how to efficiently check for value existence in array?
        require(msg.sender == owners[0] || msg.sender == owners[1] || msg.sender == owners[2]);
        _;
    }
    
    function deposit() public payable returns (uint) {
        balance += msg.value;
        return balance;
    }
    
    function withdraw(address recipient, uint amount) public onlyOwner returns (uint) {
        require(amount <= balance, "Balance not sufficient");
        // Should the withdrawer count as an approver? Assume not.
        Transfer memory transferRequest = Transfer(recipient, amount, 0, false);
    }
    
    function transfer(address recipient, uint amount) public {
        recipient.send(amount);
        balance -= amount;
        return balance;
    }
    
    function approve(uint transferID) public {
        require(!approvals[msg.sender][transferID], "This owner has already approved this transfer");
        Transfer memory transferRequest = transferRequests[transferID];
        transferRequest.numApprovals += 1;
        
        if (transferRequest.numApprovals >= limit) {
            transfer(transfer.recipient, transfer.amount);
            transferRequest.completed == true;
        }
    }
    
}